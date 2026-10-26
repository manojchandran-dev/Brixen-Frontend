import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/picked_image.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/session_service.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_date_field.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/pill_segmented_control.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/review_row.dart';
import '../../../../shared/widgets/company_selector_field.dart';
import '../../../companies/domain/entities/company.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../providers/sales_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/products_provider.dart';

const _priceTypes = ['Retail', 'Wholesale'];

/// A product picked onto this sale's bill, purely a client-side calculator —
/// `Sale` has no line-item field on the backend, only the aggregate
/// `subtotal`/`taxAmount`/`totalAmount` this feeds into.
class _SaleLineItem {
  final Product product;

  /// The size/colour being sold (null for a product without sizes).
  final ProductVariant? variant;
  int quantity;
  String priceType; // one of _priceTypes
  _SaleLineItem({
    required this.product,
    this.variant,
    required this.quantity,
    required this.priceType,
  });

  /// One line per product + size.
  String get key => _lineKey(product, variant);
  String get title => variant == null
      ? product.productName
      : '${product.productName} (${variant!.label})';
  double get unitPrice => priceType == 'Wholesale'
      ? product.wholesaleFor(variant)
      : product.retailFor(variant);
  double get amount => unitPrice * quantity;
}

String _lineKey(Product p, ProductVariant? v) => '${p.id}|${v?.id ?? ''}';

class CreateSalePage extends ConsumerStatefulWidget {
  final bool fromMenu;
  final bool fromMasters;
  final Sale? editSale;

  /// Starting bill type for a new sale (the Sales tab it was opened from).
  final String billType;
  const CreateSalePage({
    super.key,
    this.fromMenu = false,
    this.fromMasters = false,
    this.editSale,
    this.billType = BillType.gst,
  });

  @override
  ConsumerState<CreateSalePage> createState() => _CreateSalePageState();
}

class _CreateSalePageState extends ConsumerState<CreateSalePage> {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _submitting = false;

  /// Editing: the sale's lines are still loading (saving now would drop
  /// them, and with them the GST change).
  bool _loadingLines = false;

  // Step 1 — Bill Info
  /// GST bill or secondary bill; fixed once the sale is saved.
  late String _billType = widget.editSale?.billType ?? widget.billType;
  bool get _isGst => _billType != BillType.secondary;

  /// GST bill only: it can also be printed as a secondary bill.
  late bool _hasSecondaryBill = widget.editSale?.hasSecondaryBill ?? false;
  DateTime _billDate = DateTime.now();
  String? _invoiceType;
  XFile? _billImage;
  Customer? _selectedCustomer;
  Company?
  _selectedCompany; // superAdmin only — companyAdmin/employee use Session.companyId
  final _picker = ImagePicker();

  // Step 2 — Amounts
  final _subtotalCtrl = TextEditingController();
  final _taxAmountCtrl = TextEditingController();
  final _taxPercentCtrl = TextEditingController();
  final _totalAmountCtrl = TextEditingController();
  String? _paymentType;
  String? _paymentStatus;
  // Only for Partial: how much was received (Paid is filled in by the server).
  final _amountPaidCtrl = TextEditingController();
  final List<_SaleLineItem> _lineItems = [];

  // Step 3 — Notes
  final _notesCtrl = TextEditingController();

  bool get _isEditing => widget.editSale != null;

  /// The company this sale belongs to, for every write in this form.
  /// superAdmin-only — companyAdmin/employee writes are scoped by
  /// `Session.companyId` automatically. Editing uses the sale's own owning
  /// company (not whatever the list-page browse filter happens to be set
  /// to); creating uses the company picked in this form's own field.
  String? get _effectiveCompanyId {
    if (!Session.isSuperAdmin) return null;
    return _isEditing ? widget.editSale!.companyId : _selectedCompany?.id;
  }

  @override
  void initState() {
    super.initState();
    final s = widget.editSale;
    if (s != null) {
      _billDate = s.billDate;
      _invoiceType = s.invoiceType;
      if (s.billImagePath != null && s.billImagePath!.isNotEmpty) {
        _billImage = XFile(s.billImagePath!);
      } else {
        // The passed-in sale (from the list page) doesn't always carry the
        // bill image URL — only `GET /sales/:id` reliably does — so fetch
        // the full record rather than silently editing without it.
        _loadBillImageFallback(s.id, Session.isSuperAdmin ? s.companyId : null);
      }
      _subtotalCtrl.text = s.subtotal.toString();
      _taxAmountCtrl.text = s.taxAmount.toString();
      _totalAmountCtrl.text = s.totalAmount.toString();
      if (s.taxPercentage != null) {
        _taxPercentCtrl.text = _trimmed(s.taxPercentage!);
      } else if (s.subtotal > 0) {
        // Older sales / list responses without a stored percentage — back
        // -compute one from the saved amounts instead of a blank field.
        _taxPercentCtrl.text = _trimmed(s.taxAmount / s.subtotal * 100);
      }
      _paymentType = s.paymentType;
      _paymentStatus = s.paymentStatus;
      if (s.amountPaid != null && s.paymentStatus.toLowerCase() == 'partial') {
        _amountPaidCtrl.text = s.amountPaid!.toStringAsFixed(
          s.amountPaid! % 1 == 0 ? 0 : 2,
        );
      }
      _notesCtrl.text = s.notes ?? '';
      // Pre-select the customer and rebuild the line-item rows from the
      // saved sale_items. The list response doesn't carry the lines, so
      // they're fetched; customers/products are awaited, not read as they
      // happen to be — without the lines a save would drop the GST change.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _loadingLines = true;
        final scope = Session.isSuperAdmin ? s.companyId : null;
        final itemsF = s.items.isNotEmpty
            ? Future.value(s.items)
            : ref
                  .read(salesRepositoryProvider)
                  .getSaleItems(s.id, companyId: scope)
                  .catchError((_) => <SaleItem>[]);
        final customers = await ref
            .read(customersProvider.future)
            .catchError((_) => <Customer>[]);
        final products = await ref
            .read(productsProvider.future)
            .catchError((_) => <Product>[]);
        final items = await itemsF;
        if (!mounted) return;
        setState(() => _loadingLines = false);
        if (s.customerId != null) {
          final matches = customers.where((c) => c.id == s.customerId);
          if (matches.isNotEmpty) {
            setState(() => _selectedCustomer = matches.first);
          }
        }
        if (items.isNotEmpty) {
          final byId = {for (final p in products) p.id: p};
          final restored = items
              .map((item) {
                final product = byId[item.productId];
                if (product == null) return null;
                return _SaleLineItem(
                  product: product,
                  variant: product.variants
                      .where((v) => v.id == item.variantId)
                      .firstOrNull,
                  quantity: item.quantity,
                  priceType: item.priceType == 'wholesale'
                      ? 'Wholesale'
                      : 'Retail',
                );
              })
              .whereType<_SaleLineItem>()
              .toList();
          if (restored.isNotEmpty) {
            setState(() => _lineItems.addAll(restored));
          }
        }
      });
    }
  }

  Future<void> _loadBillImageFallback(String id, String? companyId) async {
    try {
      final full = await ref
          .read(salesRepositoryProvider)
          .getSaleById(id, companyId: companyId);
      if (!mounted ||
          full.billImagePath == null ||
          full.billImagePath!.isEmpty) {
        return;
      }
      setState(() => _billImage = XFile(full.billImagePath!));
    } catch (_) {}
  }

  static const _invoiceTypes = [
    'Tax Invoice',
    'Proforma Invoice',
    'Credit Note',
    'Debit Note',
    'Quotation',
    'Delivery Challan',
  ];
  static const _paymentTypes = [
    'Cash',
    'Card',
    'UPI',
    'Bank Transfer',
    'Cheque',
    'Other',
  ];
  static const _paymentStatuses = ['Pending', 'Paid', 'Partial'];

  @override
  void dispose() {
    _subtotalCtrl.dispose();
    _taxAmountCtrl.dispose();
    _taxPercentCtrl.dispose();
    _totalAmountCtrl.dispose();
    _notesCtrl.dispose();
    _amountPaidCtrl.dispose();
    super.dispose();
  }

  static String _trimmed(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// Checking a product (or one of its sizes) in the picker adds it as a
  /// row (default qty 1, Retail); unchecking removes it. Price tier and
  /// quantity are then adjusted per-row below, not at selection time.
  void _toggleProduct(Product product, ProductVariant? variant) {
    setState(() {
      final key = _lineKey(product, variant);
      final i = _lineItems.indexWhere((l) => l.key == key);
      if (i != -1) {
        _lineItems.removeAt(i);
      } else {
        _lineItems.add(
          _SaleLineItem(
            product: product,
            variant: variant,
            quantity: 1,
            priceType: 'Wholesale',
          ),
        );
      }
    });
    _recalcFromLineItems();
  }

  void _removeLineItem(int index) {
    setState(() => _lineItems.removeAt(index));
    _recalcFromLineItems();
  }

  void _updateLineItemQty(int index, int qty) {
    if (qty <= 0) return;
    setState(() => _lineItems[index].quantity = qty);
    _recalcFromLineItems();
  }

  void _updateLineItemPriceType(int index, String priceType) {
    setState(() => _lineItems[index].priceType = priceType);
    _recalcFromLineItems();
  }

  /// Subtotal always mirrors the sum of the line items once any exist —
  /// editing it by hand only applies while no products have been added.
  void _recalcFromLineItems() {
    final sum = _lineItems.fold<double>(0, (s, item) => s + item.amount);
    _subtotalCtrl.text = sum.toStringAsFixed(2);
    _recalcTaxAndTotal();
  }

  /// Tax is entered as a percentage of the subtotal — this derives the
  /// actual amount the backend stores, then the total.
  void _recalcTaxAndTotal() {
    final sub = double.tryParse(_subtotalCtrl.text) ?? 0;
    final pct = _isGst ? double.tryParse(_taxPercentCtrl.text) ?? 0 : 0;
    final taxAmt = sub * pct / 100;
    setState(() {
      _taxAmountCtrl.text = taxAmt.toStringAsFixed(2);
      _totalAmountCtrl.text = (sub + taxAmt).toStringAsFixed(2);
    });
  }

  GlobalKey<FormState> get _currentFormKey =>
      [_step1Key, _step2Key, _step3Key][_currentStep];

  void _next() {
    if (!_currentFormKey.currentState!.validate()) return;
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _back() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file != null) setState(() => _billImage = file);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attach Bill Image',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_currentFormKey.currentState!.validate()) return;
    if (!_isEditing && Session.isSuperAdmin && _selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a company'),
          backgroundColor: AppColors.dangerFill,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    // Header fields only — subtotal/tax/total are no longer sent here, the
    // server derives them from the line items posted in the step2 call below.
    if (_loadingLines) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading the sale\'s items — try again')),
      );
      return;
    }
    // Without product lines the amounts typed here are the sale's amounts,
    // so they go with the header (with lines the server works them out).
    final manual = _lineItems.isEmpty;
    final headerSale = Sale(
      id: _isEditing ? widget.editSale!.id : '',
      customerId: _selectedCustomer?.id,
      billDate: _billDate,
      billType: _billType,
      hasSecondaryBill: _isGst && _hasSecondaryBill,
      invoiceType: _invoiceType,
      subtotal: manual ? double.tryParse(_subtotalCtrl.text) ?? 0 : 0,
      taxPercentage: manual && _isGst
          ? double.tryParse(_taxPercentCtrl.text) ?? 0
          : 0,
      taxAmount: manual && _isGst
          ? double.tryParse(_taxAmountCtrl.text) ?? 0
          : 0,
      totalAmount: manual ? double.tryParse(_totalAmountCtrl.text) ?? 0 : 0,
      paymentType: _paymentType,
      paymentStatus: _paymentStatus ?? 'Pending',
      amountPaid: _paymentStatus == 'Partial'
          ? double.tryParse(_amountPaidCtrl.text.trim())
          : null,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      billImagePath: _billImage?.path,
      createdAt: _isEditing ? widget.editSale!.createdAt : DateTime.now(),
    );
    try {
      // A newly picked bill image is still a local path — host it first.
      // When editing, _billImage wraps the already-hosted URL; send it as is.
      final bill = _billImage;
      final toSave = bill == null || bill.path.startsWith('http')
          ? headerSale
          : headerSale.copyWith(
              billImagePath: await ref
                  .read(uploadServiceProvider)
                  .uploadImage(bill, folder: 'sales'),
            );
      final notifier = ref.read(salesProvider.notifier);
      final saved = _isEditing
          ? await notifier.updateSale(toSave, companyId: _effectiveCompanyId)
          : await notifier.addSale(
              toSave,
              companyId: (Session.isSuperAdmin
                  ? _selectedCompany!.id
                  : Session.companyId)!,
            );
      if (_lineItems.isNotEmpty) {
        // A new sale is created first, then its lines; if the lines fail,
        // delete the empty sale so no ₹0 bill is left behind.
        final undoNew = _isEditing
            ? null
            : () => notifier
                  .deleteSale(saved.id, companyId: _effectiveCompanyId)
                  .catchError((_) {});
        final items = _lineItems
            .map(
              (l) => SaleItem(
                productId: l.product.id,
                productName: l.product.productName,
                variantId: l.variant?.id,
                variantLabel: l.variant?.label,
                priceType: l.priceType.toLowerCase(),
                price: l.unitPrice,
                quantity: l.quantity,
              ),
            )
            .toList();
        final taxPct = _isGst
            ? double.tryParse(_taxPercentCtrl.text) ?? 0
            : 0.0;
        try {
          await notifier.updateSaleItems(
            saved.id,
            items,
            taxPct,
            companyId: _effectiveCompanyId,
          );
        } catch (_) {
          await undoNew?.call();
          rethrow;
        }
      }
      if (!mounted) return;
      if (widget.fromMenu || widget.fromMasters) {
        context.pop();
      } else {
        context.go(AppRouter.sales);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.dangerFill,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).dividerColor),
        ),
        leading: GestureDetector(
          onTap: () {
            if (_currentStep == 0) {
              (widget.fromMenu || widget.fromMasters)
                  ? context.pop()
                  : context.go(AppRouter.sales);
            } else {
              _back();
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.silverGradient : null,
              color: isDark ? null : AppColors.lightPrimary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppColors.shadows([
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: isDark ? AppColors.black : AppColors.white,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.fromMasters)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Menu',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Masters',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Sales',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    Text(
                      'Create',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else if (widget.fromMenu)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 13,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(
                      'Sales',
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 13,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  Text(
                    'Create',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              Text(
                _isEditing ? 'Edit Sale' : 'Create Sale',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (!widget.fromMenu)
              Text(
                'Step ${_currentStep + 1} of 3 — ${_stepTitle(_currentStep)}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              )
            else
              Text(
                '${_isEditing ? 'Edit' : 'Create'} Sale — Step ${_currentStep + 1} of 3',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          _SaleStepIndicator(currentStep: _currentStep),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: _buildStep(context),
              ),
            ),
          ),
          _buildNavBar(context),
        ],
      ),
    );
  }

  String _stepTitle(int step) => ['Bill Info', 'Amounts', 'Notes'][step];

  Widget _buildStep(BuildContext context) {
    switch (_currentStep) {
      case 0:
        final customers = ref.watch(customersProvider).valueOrNull ?? [];
        return _Step1(
          formKey: _step1Key,
          billType: _billType,
          // Each bill type has its own numbering, so it can't change later.
          onBillTypeChanged: _isEditing
              ? null
              : (v) {
                  setState(() => _billType = v);
                  _recalcTaxAndTotal();
                },
          hasSecondaryBill: _hasSecondaryBill,
          onHasSecondaryBillChanged: (v) =>
              setState(() => _hasSecondaryBill = v),
          billDate: _billDate,
          invoiceType: _invoiceType,
          invoiceTypes: _invoiceTypes,
          billImage: _billImage,
          customers: customers,
          selectedCustomer: _selectedCustomer,
          onDateChanged: (d) => setState(() => _billDate = d),
          onInvoiceTypeChanged: (v) => setState(() => _invoiceType = v),
          onPickImage: _showImageSourceSheet,
          onRemoveImage: () => setState(() => _billImage = null),
          onCustomerChanged: (c) => setState(() => _selectedCustomer = c),
          showCompanyField: !_isEditing && Session.isSuperAdmin,
          selectedCompany: _selectedCompany,
          onCompanyChanged: (c) => setState(() => _selectedCompany = c),
        );
      case 1:
        // Starts loading products now, so the picker is usually ready.
        ref.watch(productsProvider);
        return _Step2(
          formKey: _step2Key,
          lineItems: _lineItems,
          onToggleProduct: _toggleProduct,
          onRemoveLineItem: _removeLineItem,
          onLineItemQtyChanged: _updateLineItemQty,
          onLineItemPriceTypeChanged: _updateLineItemPriceType,
          subtotalCtrl: _subtotalCtrl,
          showTax: _isGst,
          taxPercentCtrl: _taxPercentCtrl,
          taxAmountCtrl: _taxAmountCtrl,
          totalAmountCtrl: _totalAmountCtrl,
          paymentType: _paymentType,
          paymentStatus: _paymentStatus,
          paymentTypes: _paymentTypes,
          paymentStatuses: _paymentStatuses,
          onPaymentTypeChanged: (v) => setState(() => _paymentType = v),
          onPaymentStatusChanged: (v) => setState(() => _paymentStatus = v),
          amountPaidCtrl: _amountPaidCtrl,
          onRecalc: _recalcTaxAndTotal,
        );
      default:
        return _Step3(
          formKey: _step3Key,
          notesCtrl: _notesCtrl,
          sale: _buildPreview(),
        );
    }
  }

  Map<String, String> _buildPreview() => {
    'Bill': _isGst ? 'GST Bill' : 'Secondary Bill (no GST)',
    if (_isGst) 'Secondary Bill': _hasSecondaryBill ? 'Enabled' : 'Disabled',
    if (_selectedCustomer != null) 'Customer': _selectedCustomer!.name,
    'Date': DateFormat('dd MMM yyyy').format(_billDate),
    'Invoice Type': _invoiceType ?? '—',
    if (_lineItems.isNotEmpty)
      'Items': _lineItems.map((l) => '${l.title} ×${l.quantity}').join('\n'),
    'Subtotal': '₹${_subtotalCtrl.text.isEmpty ? '0.00' : _subtotalCtrl.text}',
    if (_isGst && _taxPercentCtrl.text.isNotEmpty)
      'GST %': _taxPercentCtrl.text,
    if (_isGst)
      'GST': '₹${_taxAmountCtrl.text.isEmpty ? '0.00' : _taxAmountCtrl.text}',
    'Total':
        '₹${_totalAmountCtrl.text.isEmpty ? '0.00' : _totalAmountCtrl.text}',
    'Payment Type': _paymentType ?? '—',
    'Status': _paymentStatus ?? 'Pending',
  };

  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: BrixenButton(
                label: 'Back',
                isOutlined: true,
                onPressed: _back,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: BrixenButton(
              label: _currentStep == 2
                  ? (_isEditing ? 'Save Changes' : 'Create Sale')
                  : 'Continue',
              isLoading: _submitting,
              onPressed: _submitting
                  ? null
                  : (_currentStep == 2 ? _submit : _next),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step Indicator ─────────────────────────────────────────────────────────

class _SaleStepIndicator extends StatelessWidget {
  final int currentStep;
  const _SaleStepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = ['Bill Info', 'Amounts', 'Notes'];

    final activeCircleGradient = isDark ? AppColors.silverGradient : null;
    final activeCircleColor = isDark ? null : AppColors.lightPrimary;
    final activeContentColor = isDark ? AppColors.black : AppColors.white;
    final activeLineColor = isDark ? AppColors.silver : AppColors.lightPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(3, (i) {
          final done = i < currentStep;
          final active = i == currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (i > 0)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i <= currentStep
                                    ? activeLineColor
                                    : Theme.of(context).dividerColor,
                              ),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: (done || active)
                                  ? activeCircleGradient
                                  : null,
                              color: (done || active)
                                  ? activeCircleColor
                                  : cs.surfaceContainerHighest,
                              border: Border.all(
                                color: (done || active)
                                    ? activeLineColor
                                    : Theme.of(context).dividerColor,
                                width: active ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: done
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: activeContentColor,
                                    )
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: active
                                            ? activeContentColor
                                            : cs.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                          ),
                          if (i < 2)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i < currentStep
                                    ? activeLineColor
                                    : Theme.of(context).dividerColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: active ? cs.onSurface : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Step 1: Bill Info ──────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String billType;

  /// Null when the bill type is locked (editing a saved sale).
  final ValueChanged<String>? onBillTypeChanged;
  final bool hasSecondaryBill;
  final ValueChanged<bool> onHasSecondaryBillChanged;
  final DateTime billDate;
  final String? invoiceType;
  final List<String> invoiceTypes;
  final XFile? billImage;
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final void Function(DateTime) onDateChanged;
  final void Function(String?) onInvoiceTypeChanged;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final void Function(Customer?) onCustomerChanged;
  final bool showCompanyField;
  final Company? selectedCompany;
  final void Function(Company?) onCompanyChanged;

  const _Step1({
    required this.formKey,
    required this.billType,
    required this.onBillTypeChanged,
    required this.hasSecondaryBill,
    required this.onHasSecondaryBillChanged,
    required this.billDate,
    required this.invoiceType,
    required this.invoiceTypes,
    required this.billImage,
    required this.customers,
    required this.selectedCustomer,
    required this.onDateChanged,
    required this.onInvoiceTypeChanged,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onCustomerChanged,
    required this.showCompanyField,
    required this.selectedCompany,
    required this.onCompanyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
          if (showCompanyField) ...[
            CompanySelectorField(
              value: selectedCompany,
              onChanged: onCompanyChanged,
            ),
            const SizedBox(height: 22),
          ],
          Text(
            'Bill type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          PillSegmentedControl<String>(
            value: billType,
            onChanged: onBillTypeChanged,
            segments: const [
              PillSegment(
                value: BillType.gst,
                label: 'GST Bill',
                icon: Icons.verified_outlined,
              ),
              PillSegment(
                value: BillType.secondary,
                label: 'Secondary Bill',
                icon: Icons.receipt_long_outlined,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            onBillTypeChanged == null
                ? "A saved sale's bill type can't be changed"
                : billType == BillType.gst
                ? 'Tax invoice with GST'
                : 'Bill without GST',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          if (billType == BillType.gst) ...[
            const SizedBox(height: 14),
            _SecondaryBillToggle(
              value: hasSecondaryBill,
              onChanged: onHasSecondaryBillChanged,
            ),
          ],
          const SizedBox(height: 22),
          BrixenDateField(
            label: 'Bill Date *',
            value: billDate,
            onChanged: onDateChanged,
          ),
          const SizedBox(height: 22),

          BrixenDropdown<Customer>(
            hint: 'Select Customer',
            value: selectedCustomer,
            items: customers,
            labelOf: (c) => c.name,
            subtitleOf: (c) => c.shopName,
            icon: Icons.person_outline_rounded,
            onChanged: onCustomerChanged,
          ),
          const SizedBox(height: 22),

          BrixenDropdown<String>(
            hint: 'Invoice Type',
            value: invoiceType,
            items: invoiceTypes,
            labelOf: (s) => s,
            icon: Icons.description_outlined,
            onChanged: onInvoiceTypeChanged,
          ),
          const SizedBox(height: 22),

          _BillImagePicker(
            image: billImage,
            onPick: onPickImage,
            onRemove: onRemoveImage,
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

/// GST bill: on/off for also printing it as a secondary bill (no GST).
class _SecondaryBillToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SecondaryBillToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secondary bill',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value
                      ? 'This bill has a secondary bill'
                      : 'No secondary bill',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.brand,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Amounts ────────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<_SaleLineItem> lineItems;
  final void Function(Product, ProductVariant?) onToggleProduct;
  final void Function(int index) onRemoveLineItem;
  final void Function(int index, int qty) onLineItemQtyChanged;
  final void Function(int index, String priceType) onLineItemPriceTypeChanged;
  final TextEditingController subtotalCtrl,
      taxPercentCtrl,
      taxAmountCtrl,
      totalAmountCtrl;

  /// False for a secondary bill (no GST).
  final bool showTax;
  final String? paymentType, paymentStatus;
  final List<String> paymentTypes, paymentStatuses;
  final void Function(String?) onPaymentTypeChanged;
  final void Function(String?) onPaymentStatusChanged;
  final TextEditingController amountPaidCtrl;
  final VoidCallback onRecalc;

  const _Step2({
    required this.formKey,
    required this.lineItems,
    required this.onToggleProduct,
    required this.onRemoveLineItem,
    required this.onLineItemQtyChanged,
    required this.onLineItemPriceTypeChanged,
    required this.subtotalCtrl,
    required this.showTax,
    required this.taxPercentCtrl,
    required this.taxAmountCtrl,
    required this.totalAmountCtrl,
    required this.paymentType,
    required this.paymentStatus,
    required this.paymentTypes,
    required this.paymentStatuses,
    required this.onPaymentTypeChanged,
    required this.onPaymentStatusChanged,
    required this.amountPaidCtrl,
    required this.onRecalc,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasLineItems = lineItems.isNotEmpty;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
          Text(
            'Add Products',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Optional — pick products to auto-fill the subtotal below',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),

          _ProductMultiSelectField(
            lineItems: lineItems,
            onToggle: onToggleProduct,
          ),

          if (hasLineItems) ...[
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: List.generate(lineItems.length, (i) {
                  final item = lineItems[i];
                  final isLast = i == lineItems.length - 1;
                  return Column(
                    children: [
                      _LineItemRow(
                        item: item,
                        onQtyChanged: (q) => onLineItemQtyChanged(i, q),
                        onPriceTypeChanged: (t) =>
                            onLineItemPriceTypeChanged(i, t),
                        onRemove: () => onRemoveLineItem(i),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'Subtotal *',
            hint: '0.00',
            controller: subtotalCtrl,
            readOnly: hasLineItems,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.currency_rupee_rounded),
            onChanged: hasLineItems ? null : (_) => onRecalc(),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 22),

          if (showTax) ...[
            BrixenTextField(
              label: 'GST %',
              hint: 'e.g. 5',
              controller: taxPercentCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.percent_rounded),
              onChanged: (_) => onRecalc(),
            ),
            const SizedBox(height: 22),

            BrixenTextField(
              label: 'GST Amount',
              hint: '0.00',
              controller: taxAmountCtrl,
              readOnly: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
            ),
            const SizedBox(height: 22),
          ],

          BrixenTextField(
            label: 'Total Amount',
            hint: '0.00',
            controller: totalAmountCtrl,
            readOnly: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
          ),
          const SizedBox(height: 22),

          BrixenDropdown<String>(
            hint: 'Payment Type',
            value: paymentType,
            items: paymentTypes,
            labelOf: (s) => s,
            icon: Icons.payment_outlined,
            onChanged: onPaymentTypeChanged,
          ),
          const SizedBox(height: 22),

          BrixenDropdown<String>(
            hint: 'Payment Status *',
            value: paymentStatus,
            items: paymentStatuses,
            labelOf: (s) => s,
            icon: Icons.check_circle_outline_rounded,
            onChanged: onPaymentStatusChanged,
          ),
          const SizedBox(height: 22),
          if (paymentStatus == 'Partial') ...[
            BrixenTextField(
              label: 'Amount paid *',
              hint: '0.00',
              controller: amountPaidCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: const Icon(Icons.payments_outlined),
              validator: (v) {
                final paid = double.tryParse(v?.trim() ?? '');
                if (paid == null) return 'Enter the amount received';
                if (paid < 0) return 'Can\'t be negative';
                final total = double.tryParse(totalAmountCtrl.text) ?? 0;
                if (total > 0 && paid > total) {
                  return 'More than the total (₹${totalAmountCtrl.text})';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}

// ── Step 3: Notes & Review ─────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController notesCtrl;
  final Map<String, String> sale;

  const _Step3({
    required this.formKey,
    required this.notesCtrl,
    required this.sale,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
          _NotesField(controller: notesCtrl),
          const SizedBox(height: 28),

          Text(
            'Review',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surfaceContainerHighest
                  : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: sale.entries.map((e) {
                final isLast = e.key == sale.keys.last;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: ReviewRow(
                        label: e.key,
                        value: e.value,
                        valueColor: e.key == 'Total'
                            ? AppColors.accentEmerald
                            : cs.onSurface,
                      ),
                    ),
                    if (!isLast)
                      Divider(height: 1, color: Theme.of(context).dividerColor),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────
// (date picker moved to shared/widgets/brixen_date_field.dart)

// ── Line-item picker (Sales — Amounts step) ────────────────────────────────

/// − [qty] +: the number can be typed (e.g. 100) as well as stepped.
class _QtyStepper extends StatefulWidget {
  final int value;
  final void Function(int) onChanged;
  const _QtyStepper({required this.value, required this.onChanged});

  @override
  State<_QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<_QtyStepper> {
  late final _ctrl = TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() {}); // focused border
      if (_focus.hasFocus) {
        // Tap to type over the old number.
        _ctrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _ctrl.text.length,
        );
      } else {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(_QtyStepper old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && _ctrl.text != '${widget.value}') {
      _ctrl.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// An empty or 0 field goes back to the last good quantity.
  void _commit() {
    final n = int.tryParse(_ctrl.text.trim());
    if (n == null || n < 1) {
      _ctrl.text = '${widget.value}';
    } else if (n != widget.value) {
      widget.onChanged(n);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = widget.value;
    final onChanged = widget.onChanged;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyButton(
          icon: Icons.remove_rounded,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        const SizedBox(width: 8),
        Container(
          width: 72,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focus.hasFocus ? AppColors.brand : AppColors.border,
              width: _focus.hasFocus ? 1.6 : 1,
            ),
          ),
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (t) {
              final n = int.tryParse(t);
              if (n != null && n >= 1) onChanged(n);
            },
            onSubmitted: (_) => _commit(),
          ),
        ),
        const SizedBox(width: 8),
        _QtyButton(icon: Icons.add_rounded, onTap: () => onChanged(value + 1)),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: AppColors.brand.withValues(alpha: enabled ? 0.12 : 0.05),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? AppColors.brand
                : AppColors.brand.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

/// Tappable trigger styled like [BrixenDropdown] but opens a checklist
/// (`_ProductMultiSelectSheet`) instead of a single-select panel — checking
/// a product adds it as a line item immediately, unchecking removes it.
class _ProductMultiSelectField extends StatelessWidget {
  final List<_SaleLineItem> lineItems;
  final void Function(Product, ProductVariant?) onToggle;
  const _ProductMultiSelectField({
    required this.lineItems,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = lineItems.isEmpty
        ? null
        : '${lineItems.length} item${lineItems.length == 1 ? '' : 's'} selected';

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ProductMultiSelectSheet(
          selectedKeys: lineItems.map((l) => l.key).toSet(),
          onToggle: onToggle,
        ),
      ),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: Theme.of(context).dividerColor)
              : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.shadowDark.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(Icons.checkroom_rounded, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label ?? 'Select Products',
                style: TextStyle(
                  color: label != null ? cs.onSurface : cs.onSurfaceVariant,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.checklist_rounded, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Watches the products list itself, so a sheet opened before products
/// finish loading fills in when they arrive instead of showing "none".
class _ProductMultiSelectSheet extends ConsumerStatefulWidget {
  /// Picked lines, as [_lineKey]s.
  final Set<String> selectedKeys;
  final void Function(Product, ProductVariant?) onToggle;
  const _ProductMultiSelectSheet({
    required this.selectedKeys,
    required this.onToggle,
  });

  @override
  ConsumerState<_ProductMultiSelectSheet> createState() =>
      _ProductMultiSelectSheetState();
}

class _ProductMultiSelectSheetState
    extends ConsumerState<_ProductMultiSelectSheet> {
  late final Set<String> _selected = {...widget.selectedKeys};

  void _toggle(Product p, ProductVariant? v) {
    final key = _lineKey(p, v);
    setState(
      () =>
          _selected.contains(key) ? _selected.remove(key) : _selected.add(key),
    );
    widget.onToggle(p, v);
  }

  /// Skeleton rows shaped like the product tiles.
  Widget _loading() => Shimmer(
    child: ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      itemCount: 6,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(bottom: 18),
        child: Row(
          children: [
            SkeletonBox(width: 22, height: 22, radius: 6),
            SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160, height: 13),
                  SizedBox(height: 7),
                  SkeletonBox(width: 210, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _message(IconData icon, String text, {VoidCallback? onRetry}) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(productsProvider);
    // Inactive products can't be sold.
    final products = [
      for (final p in async.valueOrNull ?? const <Product>[])
        if (p.status.toLowerCase() != 'inactive') p,
    ];
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Products',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    '${_selected.length} selected',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Expanded(
              child: products.isEmpty && async.isLoading
                  ? _loading()
                  : products.isEmpty && async.hasError
                  ? _message(
                      Icons.cloud_off_rounded,
                      "Couldn't load products",
                      onRetry: () => ref.invalidate(productsProvider),
                    )
                  : products.isEmpty
                  ? _message(
                      Icons.checkroom_rounded,
                      'No products yet.\nAdd them in the Products module.',
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: products.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                      itemBuilder: (_, i) {
                        final product = products[i];
                        // With sizes: pick the size(s) being sold.
                        if (product.hasVariants) {
                          return _VariantPickTile(
                            product: product,
                            selected: _selected,
                            onToggle: (v) => _toggle(product, v),
                          );
                        }
                        final selected = _selected.contains(
                          _lineKey(product, null),
                        );
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (_) => _toggle(product, null),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            product.productName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'Retail ₹${product.retailPrice.toStringAsFixed(0)} · '
                            'Wholesale ₹${product.wholesalePrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: BrixenButton(
                label: _selected.isEmpty
                    ? 'Done'
                    : 'Apply · ${_selected.length} selected',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact per-row Retail/Wholesale switch — a full dropdown per line item
/// would crowd the row, so this reuses the same two options as chips.
class _PriceTypeChips extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _PriceTypeChips({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _priceTypes.map((t) {
          final selected = t == value;
          return GestureDetector(
            onTap: () => onChanged(t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accentIndigo.withValues(alpha: 0.15)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.accentIndigo
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A product with sizes in the picker: its name, then one chip per
/// size/colour (with stock); tapping a chip adds/removes that size.
class _VariantPickTile extends StatelessWidget {
  final Product product;
  final Set<String> selected;
  final ValueChanged<ProductVariant> onToggle;
  const _VariantPickTile({
    required this.product,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.productName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Pick the size(s) sold',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in product.variants)
                _SizeChip(
                  label: v.label,
                  stock: v.stockQuantity,
                  retail: product.retailFor(v),
                  wholesale: product.wholesaleFor(v),
                  selected: selected.contains(_lineKey(product, v)),
                  onTap: () => onToggle(v),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final int stock;
  final double retail, wholesale;
  final bool selected;
  final VoidCallback onTap;
  const _SizeChip({
    required this.label,
    required this.stock,
    required this.retail,
    required this.wholesale,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.ink;
    return Material(
      color: selected ? AppColors.brand : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_rounded, size: 14, color: fg),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Text(
                'R ₹${retail.toStringAsFixed(0)} · W ₹${wholesale.toStringAsFixed(0)}\n${stock <= 0 ? 'Out of stock' : '$stock in stock'}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.75),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  final _SaleLineItem item;
  final void Function(int) onQtyChanged;
  final void Function(String) onPriceTypeChanged;
  final VoidCallback onRemove;
  const _LineItemRow({
    required this.item,
    required this.onQtyChanged,
    required this.onPriceTypeChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.dangerFill,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _PriceTypeChips(
                value: item.priceType,
                onChanged: onPriceTypeChanged,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '₹${item.unitPrice.toStringAsFixed(0)} each',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _QtyStepper(value: item.quantity, onChanged: onQtyChanged),
              const Spacer(),
              Text(
                '₹${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 2)}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatefulWidget {
  final TextEditingController controller;
  const _NotesField({required this.controller});

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  final _focus = FocusNode();
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    widget.controller.addListener(() {
      final has = widget.controller.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showLabel = _focused || _hasText;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.silver
                  : Theme.of(context).dividerColor,
              width: _focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 14),
                child: Icon(
                  Icons.notes_rounded,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  maxLines: 4,
                  style: TextStyle(color: cs.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: showLabel ? 'Add any remarks or notes' : 'Notes',
                    hintStyle: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(8, 14, 16, 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabel)
          Positioned(
            top: -9,
            left: 12,
            child: Container(
              color: cs.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Notes',
                style: TextStyle(
                  color: _focused ? AppColors.silver : cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Bill Image Picker ──────────────────────────────────────────────────────

class _BillImagePicker extends StatelessWidget {
  final XFile? image;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _BillImagePicker({
    required this.image,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (image != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: pickedImage(
              image!.path,
              width: double.infinity,
              height: 180,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Bill attached',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? AppColors.silver : AppColors.lightPrimary)
                .withValues(alpha: 0.25),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upload_file_outlined,
              size: 32,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Attach Bill Image',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Optional — tap to pick from camera or gallery',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Source Tile ────────────────────────────────────────────────────────────

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isDark ? AppColors.silver : AppColors.lightPrimary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
