import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/picked_image.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/session_service.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/company_selector_field.dart';
import '../../../companies/domain/entities/company.dart';
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
  int quantity;
  String priceType; // one of _priceTypes
  _SaleLineItem({required this.product, required this.quantity, required this.priceType});
  double get unitPrice => priceType == 'Wholesale' ? product.wholesalePrice : product.retailPrice;
  double get amount => unitPrice * quantity;
}

class CreateSalePage extends ConsumerStatefulWidget {
  final bool fromMenu;
  final bool fromMasters;
  final Sale? editSale;
  const CreateSalePage({
    super.key,
    this.fromMenu = false,
    this.fromMasters = false,
    this.editSale,
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

  // Step 1 — Bill Info
  DateTime _billDate = DateTime.now();
  String? _invoiceType;
  XFile? _billImage;
  Customer? _selectedCustomer;
  Company? _selectedCompany; // superAdmin only — companyAdmin/employee use Session.companyId
  final _picker = ImagePicker();

  // Step 2 — Amounts
  final _subtotalCtrl = TextEditingController();
  final _taxAmountCtrl = TextEditingController();
  final _taxPercentCtrl = TextEditingController();
  final _totalAmountCtrl = TextEditingController();
  String? _paymentType;
  String? _paymentStatus;
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
      if (s.billImagePath != null) _billImage = XFile(s.billImagePath!);
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
      _notesCtrl.text = s.notes ?? '';
      // Pre-select customer, and rebuild the line-item rows from the saved
      // sale_items, once the Customers/Products providers have data.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (s.customerId != null) {
          final customers = ref.read(customersProvider).valueOrNull ?? [];
          final matches = customers.where((c) => c.id == s.customerId);
          if (matches.isNotEmpty) {
            setState(() => _selectedCustomer = matches.first);
          }
        }
        if (s.items.isNotEmpty) {
          final products = ref.read(productsProvider).valueOrNull ?? [];
          final byId = {for (final p in products) p.id: p};
          final restored = s.items
              .map((item) {
                final product = byId[item.productId];
                if (product == null) return null;
                return _SaleLineItem(
                  product: product,
                  quantity: item.quantity,
                  priceType: item.priceType == 'wholesale' ? 'Wholesale' : 'Retail',
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

  static const _invoiceTypes = [
    'Tax Invoice', 'Proforma Invoice', 'Credit Note',
    'Debit Note', 'Quotation', 'Delivery Challan',
  ];
  static const _paymentTypes = [
    'Cash', 'Card', 'UPI', 'Bank Transfer', 'Cheque', 'Other',
  ];
  static const _paymentStatuses = [
    'Pending', 'Paid', 'Partial',
  ];

  @override
  void dispose() {
    _subtotalCtrl.dispose(); _taxAmountCtrl.dispose(); _taxPercentCtrl.dispose();
    _totalAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  static String _trimmed(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// Checking a product in the multi-select picker adds it as a row (default
  /// qty 1, Retail); unchecking removes it. Price tier and quantity are then
  /// adjusted per-row below, not at selection time.
  void _toggleProduct(Product product) {
    setState(() {
      final i = _lineItems.indexWhere((l) => l.product.id == product.id);
      if (i != -1) {
        _lineItems.removeAt(i);
      } else {
        _lineItems.add(_SaleLineItem(product: product, quantity: 1, priceType: 'Retail'));
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
    final pct = double.tryParse(_taxPercentCtrl.text) ?? 0;
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
              Text('Attach Bill Image',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface)),
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
        const SnackBar(content: Text('Please select a company'), backgroundColor: AppColors.dangerFill),
      );
      return;
    }
    setState(() => _submitting = true);
    // Header fields only — subtotal/tax/total are no longer sent here, the
    // server derives them from the line items posted in the step2 call below.
    final headerSale = Sale(
      id: _isEditing ? widget.editSale!.id : '',
      customerId: _selectedCustomer?.id,
      billDate: _billDate,
      invoiceType: _invoiceType,
      subtotal: 0,
      taxAmount: 0,
      totalAmount: 0,
      paymentType: _paymentType,
      paymentStatus: _paymentStatus ?? 'Pending',
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      billImagePath: _billImage?.path,
      createdAt: _isEditing ? widget.editSale!.createdAt : DateTime.now(),
    );
    try {
      final notifier = ref.read(salesProvider.notifier);
      final saved = _isEditing
          ? await notifier.updateSale(headerSale, companyId: _effectiveCompanyId)
          : await notifier.addSale(
              headerSale,
              companyId: (Session.isSuperAdmin ? _selectedCompany!.id : Session.companyId)!,
            );
      if (_lineItems.isNotEmpty) {
        final items = _lineItems
            .map((l) => SaleItem(
                  productId: l.product.id,
                  productName: l.product.productName,
                  priceType: l.priceType.toLowerCase(),
                  price: l.unitPrice,
                  quantity: l.quantity,
                ))
            .toList();
        final taxPct = double.tryParse(_taxPercentCtrl.text) ?? 0;
        await notifier.updateSaleItems(
          saved.id,
          items,
          taxPct,
          companyId: _effectiveCompanyId,
        );
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
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dangerFill),
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
              (widget.fromMenu || widget.fromMasters) ? context.pop() : context.go(AppRouter.sales);
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
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16,
                color: isDark ? AppColors.black : AppColors.white),
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
                    GestureDetector(onTap: () => context.pop(), child: Text('Menu', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.chevron_right_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                    GestureDetector(onTap: () => context.pop(), child: Text('Masters', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.chevron_right_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                    GestureDetector(onTap: () => context.pop(), child: Text('Sales', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.chevron_right_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                    Text('Create', style: TextStyle(color: cs.onSurface, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else if (widget.fromMenu)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text('Menu', style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(Icons.chevron_right_rounded, size: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text('Sales', style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(Icons.chevron_right_rounded, size: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  ),
                  Text('Create', style: TextStyle(
                      color: cs.onSurface, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              )
            else
              Text(_isEditing ? 'Edit Sale' : 'Create Sale', style: TextStyle(
                  color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
            if (!widget.fromMenu)
              Text('Step ${_currentStep + 1} of 3 — ${_stepTitle(_currentStep)}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11))
            else
              Text('${_isEditing ? 'Edit' : 'Create'} Sale — Step ${_currentStep + 1} of 3',
                  style: TextStyle(
                      color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
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
                      begin: const Offset(0.04, 0), end: Offset.zero)
                      .animate(anim),
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

  String _stepTitle(int step) =>
      ['Bill Info', 'Amounts', 'Notes'][step];

  Widget _buildStep(BuildContext context) {
    switch (_currentStep) {
      case 0:
        final customers = ref.watch(customersProvider).valueOrNull ?? [];
        return _Step1(
          formKey: _step1Key,
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
        final products = ref.watch(productsProvider).valueOrNull ?? [];
        return _Step2(
          formKey: _step2Key,
          products: products,
          lineItems: _lineItems,
          onToggleProduct: _toggleProduct,
          onRemoveLineItem: _removeLineItem,
          onLineItemQtyChanged: _updateLineItemQty,
          onLineItemPriceTypeChanged: _updateLineItemPriceType,
          subtotalCtrl: _subtotalCtrl,
          taxPercentCtrl: _taxPercentCtrl,
          taxAmountCtrl: _taxAmountCtrl,
          totalAmountCtrl: _totalAmountCtrl,
          paymentType: _paymentType,
          paymentStatus: _paymentStatus,
          paymentTypes: _paymentTypes,
          paymentStatuses: _paymentStatuses,
          onPaymentTypeChanged: (v) => setState(() => _paymentType = v),
          onPaymentStatusChanged: (v) => setState(() => _paymentStatus = v),
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
    if (_selectedCustomer != null) 'Customer': _selectedCustomer!.name,
    'Date': DateFormat('dd MMM yyyy').format(_billDate),
    'Invoice Type': _invoiceType ?? '—',
    if (_lineItems.isNotEmpty)
      'Items': _lineItems.map((l) => '${l.product.productName} ×${l.quantity}').join(', '),
    'Subtotal': '₹${_subtotalCtrl.text.isEmpty ? '0.00' : _subtotalCtrl.text}',
    if (_taxPercentCtrl.text.isNotEmpty) 'Tax %': _taxPercentCtrl.text,
    'Tax': '₹${_taxAmountCtrl.text.isEmpty ? '0.00' : _taxAmountCtrl.text}',
    'Total': '₹${_totalAmountCtrl.text.isEmpty ? '0.00' : _totalAmountCtrl.text}',
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
              child: BrixenButton(label: 'Back', isOutlined: true, onPressed: _back),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: BrixenButton(
              label: _currentStep == 2 ? (_isEditing ? 'Save Changes' : 'Create Sale') : 'Continue',
              isLoading: _submitting,
              onPressed: _submitting ? null : (_currentStep == 2 ? _submit : _next),
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
                              gradient: (done || active) ? activeCircleGradient : null,
                              color: (done || active) ? activeCircleColor : cs.surfaceContainerHighest,
                              border: Border.all(
                                color: (done || active)
                                    ? activeLineColor
                                    : Theme.of(context).dividerColor,
                                width: active ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: done
                                  ? Icon(Icons.check_rounded, size: 14, color: activeContentColor)
                                  : Text('${i + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: active ? activeContentColor : cs.onSurfaceVariant,
                                      )),
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
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
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
            CompanySelectorField(value: selectedCompany, onChanged: onCompanyChanged),
            const SizedBox(height: 22),
          ],
          _DatePickerField(
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

// ── Step 2: Amounts ────────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Product> products;
  final List<_SaleLineItem> lineItems;
  final void Function(Product) onToggleProduct;
  final void Function(int index) onRemoveLineItem;
  final void Function(int index, int qty) onLineItemQtyChanged;
  final void Function(int index, String priceType) onLineItemPriceTypeChanged;
  final TextEditingController subtotalCtrl, taxPercentCtrl, taxAmountCtrl, totalAmountCtrl;
  final String? paymentType, paymentStatus;
  final List<String> paymentTypes, paymentStatuses;
  final void Function(String?) onPaymentTypeChanged;
  final void Function(String?) onPaymentStatusChanged;
  final VoidCallback onRecalc;

  const _Step2({
    required this.formKey,
    required this.products,
    required this.lineItems,
    required this.onToggleProduct,
    required this.onRemoveLineItem,
    required this.onLineItemQtyChanged,
    required this.onLineItemPriceTypeChanged,
    required this.subtotalCtrl,
    required this.taxPercentCtrl,
    required this.taxAmountCtrl,
    required this.totalAmountCtrl,
    required this.paymentType,
    required this.paymentStatus,
    required this.paymentTypes,
    required this.paymentStatuses,
    required this.onPaymentTypeChanged,
    required this.onPaymentStatusChanged,
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
          Text('Add Products',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 3),
          Text('Optional — pick products to auto-fill the subtotal below',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
          const SizedBox(height: 12),

          _ProductMultiSelectField(
            products: products,
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
                        onPriceTypeChanged: (t) => onLineItemPriceTypeChanged(i, t),
                        onRemove: () => onRemoveLineItem(i),
                      ),
                      if (!isLast) Divider(height: 1, color: Theme.of(context).dividerColor),
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
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'Tax %',
            hint: 'e.g. 5',
            controller: taxPercentCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.percent_rounded),
            onChanged: (_) => onRecalc(),
          ),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'Tax Amount',
            hint: '0.00',
            controller: taxAmountCtrl,
            readOnly: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.currency_rupee_rounded),
          ),
          const SizedBox(height: 22),

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

          Text('Review',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
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
                          horizontal: 16, vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key,
                              style: TextStyle(
                                  fontSize: 13, color: cs.onSurfaceVariant)),
                          Text(e.value,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: e.key == 'Total'
                                      ? AppColors.accentEmerald
                                      : cs.onSurface)),
                        ],
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

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final void Function(DateTime) onChanged;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('dd MMM yyyy').format(value),
                style: TextStyle(fontSize: 15, color: cs.onSurface),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Line-item picker (Sales — Amounts step) ────────────────────────────────

class _QtyStepper extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;
  const _QtyStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove_rounded,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
          ),
          _QtyButton(icon: Icons.add_rounded, onTap: () => onChanged(value + 1)),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? cs.onSurfaceVariant.withValues(alpha: 0.3) : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Tappable trigger styled like [BrixenDropdown] but opens a checklist
/// (`_ProductMultiSelectSheet`) instead of a single-select panel — checking
/// a product adds it as a line item immediately, unchecking removes it.
class _ProductMultiSelectField extends StatelessWidget {
  final List<Product> products;
  final List<_SaleLineItem> lineItems;
  final void Function(Product) onToggle;
  const _ProductMultiSelectField({
    required this.products,
    required this.lineItems,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = lineItems.isEmpty ? null : '${lineItems.length} product(s) selected';

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ProductMultiSelectSheet(
          products: products,
          selectedIds: lineItems.map((l) => l.product.id).toSet(),
          onToggle: onToggle,
        ),
      ),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: Theme.of(context).dividerColor) : null,
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

class _ProductMultiSelectSheet extends StatefulWidget {
  final List<Product> products;
  final Set<String> selectedIds;
  final void Function(Product) onToggle;
  const _ProductMultiSelectSheet({
    required this.products,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  State<_ProductMultiSelectSheet> createState() => _ProductMultiSelectSheetState();
}

class _ProductMultiSelectSheetState extends State<_ProductMultiSelectSheet> {
  late final Set<String> _selectedIds = {...widget.selectedIds};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                  Text('Select Products',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  Text('${_selectedIds.length} selected',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Expanded(
              child: widget.products.isEmpty
                  ? Center(
                      child: Text('No products available',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: widget.products.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: Theme.of(context).dividerColor),
                      itemBuilder: (_, i) {
                        final product = widget.products[i];
                        final selected = _selectedIds.contains(product.id);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (_) {
                            setState(() {
                              selected ? _selectedIds.remove(product.id) : _selectedIds.add(product.id);
                            });
                            widget.onToggle(product);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(product.productName,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                          subtitle: Text(
                            'Retail ₹${product.retailPrice.toStringAsFixed(0)} · '
                            'Wholesale ₹${product.wholesalePrice.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
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
                color: selected ? AppColors.accentIndigo.withValues(alpha: 0.15) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.accentIndigo : cs.onSurfaceVariant,
                  )),
            ),
          );
        }).toList(),
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
                child: Text(item.product.productName,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: cs.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
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
              _PriceTypeChips(value: item.priceType, onChanged: onPriceTypeChanged),
              const Spacer(),
              _QtyStepper(value: item.quantity, onChanged: onQtyChanged),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: Text('₹${item.amount.toStringAsFixed(0)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: cs.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('₹${item.unitPrice.toStringAsFixed(0)} each (${item.priceType})',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
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
              color: _focused ? AppColors.silver : Theme.of(context).dividerColor,
              width: _focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 14),
                child: Icon(Icons.notes_rounded,
                    color: cs.onSurfaceVariant, size: 20),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  maxLines: 4,
                  style: TextStyle(color: cs.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: showLabel ? 'Add any remarks or notes' : 'Notes',
                    hintStyle:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.fromLTRB(8, 14, 16, 14),
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
            child: pickedImage(image!.path, width: double.infinity, height: 180),
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
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Colors.white),
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
                  Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Bill attached',
                      style: TextStyle(fontSize: 11, color: Colors.white)),
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
            Icon(Icons.upload_file_outlined,
                size: 32, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text('Attach Bill Image',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
            const SizedBox(height: 3),
            Text('Optional — tap to pick from camera or gallery',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
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
            Icon(icon,
                size: 28,
                color: isDark ? AppColors.silver : AppColors.lightPrimary),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}
