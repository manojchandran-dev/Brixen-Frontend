import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_date_field.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/picked_image.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../masters/domain/entities/master_item.dart';
import '../../../masters/presentation/cubit/master_cubit.dart';
import '../../domain/entities/purchase.dart';
import '../providers/purchases_provider.dart';

class CreatePurchasePage extends ConsumerStatefulWidget {
  final bool fromMasters;
  final Purchase? editPurchase;
  const CreatePurchasePage({
    super.key,
    this.fromMasters = false,
    this.editPurchase,
  });

  @override
  ConsumerState<CreatePurchasePage> createState() => _CreatePurchasePageState();
}

class _CreatePurchasePageState extends ConsumerState<CreatePurchasePage> {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _submitting = false;

  // Step 1
  final _supplierCtrl = TextEditingController();
  final _billNoCtrl = TextEditingController();
  DateTime _billDate = DateTime.now();
  String? _invoiceType;
  XFile? _billImage;
  final _picker = ImagePicker();

  // Step 2 — items (purchase categories) and payment
  final List<_Line> _lines = [];
  bool _loadingLines = false;
  // Number fields start empty (hint "0") so they can be typed straight in.
  final _taxPercentCtrl = TextEditingController();
  final _amountPaidCtrl = TextEditingController();
  String? _paymentType;
  String? _paymentStatus;

  double get _subtotal => _lines.fold(0, (a, l) => a + l.total);
  double get _taxAmount =>
      _subtotal * (double.tryParse(_taxPercentCtrl.text) ?? 0) / 100;
  double get _total => _subtotal + _taxAmount;

  // Step 3
  final _notesCtrl = TextEditingController();

  bool get _isEditing => widget.editPurchase != null;

  static const _invoiceTypes = [
    'Tax Invoice',
    'Proforma Invoice',
    'Credit Note',
    'Debit Note',
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
  static const _paymentStatuses = ['Paid', 'Pending', 'Partial', 'Cancelled'];

  /// Units master names ("pcs", "m", "kg") for the per-line unit picker.
  List<String> get _units => [
    for (final u in masterCubit.itemsOfType('unit'))
      if (u.name.isNotEmpty) u.name,
  ];

  /// New lines start in "pcs" when the company has it, else its first unit.
  String? get _defaultUnit {
    final units = _units;
    return units.contains('pcs') ? 'pcs' : units.firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    masterCubit.ensureLoaded('unit').then((_) {
      if (mounted) setState(() {});
    }, onError: (_) {});
    final p = widget.editPurchase;
    if (p != null) {
      _supplierCtrl.text = p.supplierName;
      _billNoCtrl.text = p.billNo;
      _taxPercentCtrl.text = _trim(p.taxPercentage);
      if (p.amountPaid != null) _amountPaidCtrl.text = _trim(p.amountPaid!);
      _setLines(p.items);
      // The list may not carry the lines — load the full purchase.
      if (p.items.isEmpty) {
        _loadingLines = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final full = await ref.read(purchasesProvider.notifier).fetch(p.id);
            if (mounted) setState(() => _setLines(full.items));
          } catch (_) {
            // Leave it empty; the user can add lines.
          } finally {
            if (mounted) setState(() => _loadingLines = false);
          }
        });
      }
      _billDate = p.billDate;
      _invoiceType = p.invoiceType;
      if (p.billImagePath != null) _billImage = XFile(p.billImagePath!);
      _paymentType = p.paymentType;
      _paymentStatus = p.paymentStatus;
      _notesCtrl.text = p.notes ?? '';
    }
  }

  @override
  void dispose() {
    _supplierCtrl.dispose();
    _billNoCtrl.dispose();
    _taxPercentCtrl.dispose();
    _amountPaidCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    _notesCtrl.dispose();
    super.dispose();
  }

  GlobalKey<FormState> get _currentFormKey =>
      [_step1Key, _step2Key, _step3Key][_currentStep];

  static String _trim(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  void _setLines(List<PurchaseItem> items) {
    for (final l in _lines) {
      l.dispose();
    }
    _lines
      ..clear()
      ..addAll([
        for (final it in items)
          _Line(
            it.productName,
            it.quantity,
            it.unitCost,
            purchaseCategoryId: it.purchaseCategoryId,
            productId: it.productId,
            unit: it.unit,
          ),
      ]);
  }

  bool _hasLines() {
    if (_lines.isNotEmpty) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add at least one item'),
        backgroundColor: AppColors.dangerFill,
      ),
    );
    return false;
  }

  void _addCategory(MasterItem c) {
    final existing = _lines
        .where((l) => l.purchaseCategoryId == c.id)
        .firstOrNull;
    setState(() {
      if (existing != null) {
        existing.qty.text = '${(int.tryParse(existing.qty.text) ?? 0) + 1}';
      } else {
        _lines.add(
          _Line(
            c.name,
            null,
            null,
            purchaseCategoryId: c.id,
            unit: _defaultUnit,
          ),
        );
      }
    });
  }

  void _next() {
    if (!_currentFormKey.currentState!.validate()) return;
    if (_currentStep == 1 && !_hasLines()) return;
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _back() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file != null) setState(() => _billImage = file);
  }

  void _showImageSheet() {
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
    if (!_currentFormKey.currentState!.validate() || !_hasLines()) return;
    final companyId = _isEditing
        ? widget.editPurchase!.companyId
        : Session.companyId;
    if (!_isEditing && companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases are recorded from a company account'),
          backgroundColor: AppColors.dangerFill,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      // A newly picked bill photo is a local path — host it first.
      final bill = _billImage;
      final billUrl = bill == null || bill.path.startsWith('http')
          ? bill?.path
          : await ref
                .read(uploadServiceProvider)
                .uploadImage(bill, folder: 'purchases');
      final purchase = Purchase(
        id: _isEditing ? widget.editPurchase!.id : '',
        supplierName: _supplierCtrl.text.trim(),
        billNo: _billNoCtrl.text.trim(),
        billDate: _billDate,
        invoiceType: _invoiceType,
        subtotal: _subtotal,
        taxPercentage: double.tryParse(_taxPercentCtrl.text) ?? 0,
        taxAmount: _taxAmount,
        totalAmount: _total,
        amountPaid: _paymentStatus == 'Partial'
            ? double.tryParse(_amountPaidCtrl.text.trim())
            : null,
        paymentType: _paymentType,
        paymentStatus: _paymentStatus ?? 'Pending',
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        billImagePath: billUrl,
        items: [
          for (final l in _lines)
            PurchaseItem(
              purchaseCategoryId: l.purchaseCategoryId,
              productId: l.productId,
              productName: l.name,
              unit: l.unit,
              quantity: int.tryParse(l.qty.text) ?? 0,
              unitCost: double.tryParse(l.cost.text) ?? 0,
            ),
        ],
        createdAt: _isEditing ? widget.editPurchase!.createdAt : DateTime.now(),
      );
      final notifier = ref.read(purchasesProvider.notifier);
      if (_isEditing) {
        await notifier.edit(purchase);
      } else {
        await notifier.add(purchase, companyId: companyId!);
      }
      if (!mounted) return;
      if (widget.fromMasters) {
        context.pop();
      } else {
        context.go(AppRouter.purchases);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.dangerFill),
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
              widget.fromMasters
                  ? context.pop()
                  : context.go(AppRouter.purchases);
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
                        'Purchases',
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
                      _isEditing ? 'Edit' : 'Create',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                _isEditing ? 'Edit Purchase' : 'New Purchase',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            Text(
              'Step ${_currentStep + 1} of 3 — ${['Supplier Info', 'Items & Payment', 'Notes'][_currentStep]}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(
            currentStep: _currentStep,
            labels: const ['Supplier', 'Items', 'Notes'],
            accentColor: AppColors.accentTeal,
          ),
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
                child: _buildStep(),
              ),
            ),
          ),
          _NavBar(
            currentStep: _currentStep,
            submitting: _submitting,
            isEditing: _isEditing,
            onBack: _back,
            onNext: _next,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _pickCategory(BuildContext context) async {
    final picked = await showModalBottomSheet<MasterItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CategoryPickerSheet(),
    );
    if (picked != null) _addCategory(picked);
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _Step1(
          formKey: _step1Key,
          supplierCtrl: _supplierCtrl,
          billNoCtrl: _billNoCtrl,
          billDate: _billDate,
          invoiceType: _invoiceType,
          invoiceTypes: _invoiceTypes,
          billImage: _billImage,
          onDateChanged: (d) => setState(() => _billDate = d),
          onInvoiceTypeChanged: (v) => setState(() => _invoiceType = v),
          onPickImage: _showImageSheet,
          onRemoveImage: () => setState(() => _billImage = null),
        );
      case 1:
        return _ItemsStep(
          formKey: _step2Key,
          lines: _lines,
          units: _units,
          loading: _loadingLines,
          onAdd: () => _pickCategory(context),
          onRemove: (l) => setState(() {
            _lines.remove(l);
            l.dispose();
          }),
          onChanged: () => setState(() {}),
          taxPercentCtrl: _taxPercentCtrl,
          subtotal: _subtotal,
          taxAmount: _taxAmount,
          total: _total,
          paymentType: _paymentType,
          paymentStatus: _paymentStatus,
          paymentTypes: _paymentTypes,
          paymentStatuses: _paymentStatuses,
          onPaymentTypeChanged: (v) => setState(() => _paymentType = v),
          onPaymentStatusChanged: (v) => setState(() => _paymentStatus = v),
          amountPaidCtrl: _amountPaidCtrl,
        );
      default:
        return _Step3(
          formKey: _step3Key,
          notesCtrl: _notesCtrl,
          preview: {
            'Supplier': _supplierCtrl.text.trim().isEmpty
                ? '—'
                : _supplierCtrl.text.trim(),
            'Date': DateFormat('dd MMM yyyy').format(_billDate),
            'Invoice Type': _invoiceType ?? '—',
            'Bill No': _billNoCtrl.text.trim().isEmpty
                ? '—'
                : _billNoCtrl.text.trim(),
            'Items':
                '${_lines.length} item${_lines.length == 1 ? '' : 's'} · '
                '${_lines.fold<int>(0, (a, l) => a + (int.tryParse(l.qty.text) ?? 0))} units',
            'Subtotal': '₹${_subtotal.toStringAsFixed(2)}',
            'Tax': '₹${_taxAmount.toStringAsFixed(2)}',
            'Total': '₹${_total.toStringAsFixed(2)}',
            'Payment Type': _paymentType ?? '—',
            'Status': _paymentStatus ?? 'Pending',
          },
        );
    }
  }
}

// ── Step Indicator ─────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  final Color accentColor;
  const _StepIndicator({
    required this.currentStep,
    required this.labels,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(labels.length, (i) {
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
                                    ? accentColor
                                    : Theme.of(context).dividerColor,
                              ),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (done || active)
                                  ? accentColor
                                  : cs.surfaceContainerHighest,
                              border: Border.all(
                                color: (done || active)
                                    ? accentColor
                                    : Theme.of(context).dividerColor,
                                width: active ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: done
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: active
                                            ? Colors.white
                                            : cs.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                          ),
                          if (i < labels.length - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i < currentStep
                                    ? accentColor
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

// ── Nav Bar ────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int currentStep;
  final bool submitting, isEditing;
  final VoidCallback onBack, onNext, onSubmit;
  const _NavBar({
    required this.currentStep,
    required this.submitting,
    required this.isEditing,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          if (currentStep > 0) ...[
            Expanded(
              child: BrixenButton(
                label: 'Back',
                isOutlined: true,
                onPressed: onBack,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: BrixenButton(
              label: currentStep == 2
                  ? (isEditing ? 'Save Changes' : 'Create Purchase')
                  : 'Continue',
              isLoading: submitting,
              onPressed: submitting
                  ? null
                  : (currentStep == 2 ? onSubmit : onNext),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Supplier Info ──────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController supplierCtrl, billNoCtrl;
  final DateTime billDate;
  final String? invoiceType;
  final List<String> invoiceTypes;
  final XFile? billImage;
  final void Function(DateTime) onDateChanged;
  final void Function(String?) onInvoiceTypeChanged;
  final VoidCallback onPickImage, onRemoveImage;

  const _Step1({
    required this.formKey,
    required this.supplierCtrl,
    required this.billNoCtrl,
    required this.billDate,
    required this.invoiceType,
    required this.invoiceTypes,
    required this.billImage,
    required this.onDateChanged,
    required this.onInvoiceTypeChanged,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
          BrixenTextField(
            label: 'Supplier Name *',
            hint: 'Enter supplier or vendor name',
            controller: supplierCtrl,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.store_outlined),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 22),
          BrixenTextField(
            label: 'Bill No',
            hint: "Supplier's bill number",
            controller: billNoCtrl,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.tag_rounded),
          ),
          const SizedBox(height: 22),
          BrixenDateField(value: billDate, onChanged: onDateChanged),
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
          _ImagePicker(
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

// ── Step 2: Items & payment ────────────────────────────────────────────────

/// One bill line being edited: quantity and unit cost fields. New lines are
/// purchase categories; a product line only comes from an older bill.
class _Line {
  final String? purchaseCategoryId;
  final String productId;
  final String name;
  final TextEditingController qty;
  final TextEditingController cost;
  String? unit;

  /// Null [quantity] / [unitCost] leave the field empty (a new line).
  _Line(
    this.name,
    int? quantity,
    double? unitCost, {
    this.purchaseCategoryId,
    this.productId = '',
    this.unit,
  }) : qty = TextEditingController(text: quantity == null ? '' : '$quantity'),
       cost = TextEditingController(
         text: unitCost == null
             ? ''
             : unitCost % 1 == 0
             ? unitCost.toStringAsFixed(0)
             : unitCost.toStringAsFixed(2),
       );

  double get total =>
      (int.tryParse(qty.text) ?? 0) * (double.tryParse(cost.text) ?? 0);

  void dispose() {
    qty.dispose();
    cost.dispose();
  }
}

class _ItemsStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<_Line> lines;

  /// Unit names for each line's unit picker.
  final List<String> units;
  final bool loading;
  final VoidCallback onAdd;
  final void Function(_Line) onRemove;
  final VoidCallback onChanged;
  final TextEditingController taxPercentCtrl, amountPaidCtrl;
  final double subtotal, taxAmount, total;
  final String? paymentType, paymentStatus;
  final List<String> paymentTypes, paymentStatuses;
  final void Function(String?) onPaymentTypeChanged, onPaymentStatusChanged;

  const _ItemsStep({
    required this.formKey,
    required this.lines,
    required this.units,
    required this.loading,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
    required this.taxPercentCtrl,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.paymentType,
    required this.paymentStatus,
    required this.paymentTypes,
    required this.paymentStatuses,
    required this.onPaymentTypeChanged,
    required this.onPaymentStatusChanged,
    required this.amountPaidCtrl,
  });

  static final _money = NumberFormat('#,##,##0.00', 'en_IN');

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        children: [
          Row(
            children: [
              Text(
                'Items bought',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add item'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (lines.isEmpty)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: AppColors.brand,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add the items on this bill',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      'Pick from your purchase categories',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final l in lines) ...[
              _LineCard(
                units: units,
                line: l,
                onRemove: () => onRemove(l),
                onChanged: onChanged,
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 12),
          BrixenTextField(
            label: 'Tax %',
            hint: '0',
            controller: taxPercentCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.percent_rounded),
            onChanged: (_) => onChanged(),
            validator: (v) {
              final n = double.tryParse(v?.trim() ?? '');
              return v == null || v.trim().isEmpty || (n != null && n >= 0)
                  ? null
                  : 'Enter a valid %';
            },
          ),
          const SizedBox(height: 14),
          // Totals, worked out from the lines.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (final (label, v, bold) in [
                  ('Subtotal', subtotal, false),
                  ('Tax', taxAmount, false),
                  ('Total', total, true),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: bold
                                ? AppColors.ink
                                : AppColors.textSecondary,
                            fontWeight: bold
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${_money.format(v)}',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: bold ? 16 : 13.5,
                            fontWeight: bold
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
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
                if (paid == null) return 'Enter the amount paid';
                if (paid < 0) return "Can't be negative";
                if (paid > total) return 'More than the total';
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

class _LineCard extends StatelessWidget {
  final _Line line;
  final List<String> units;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _LineCard({
    required this.line,
    required this.units,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    InputDecoration box(String label, {String? prefix, String? hint}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix,
          isDense: true,
          filled: true,
          fillColor: AppColors.surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
          ),
        );
    // A unit saved on an old line that's no longer in the master still shows.
    final unitOptions = [
      ...units,
      if (line.unit != null && !units.contains(line.unit)) line.unit!,
    ];
    final qty = int.tryParse(line.qty.text) ?? 0;
    final cost = double.tryParse(line.cost.text) ?? 0;
    final money = _ItemsStep._money;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + remove.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 17,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          // Qty · unit · unit cost.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: line.qty,
                    keyboardType: TextInputType.number,
                    decoration: box('Qty', hint: '0'),
                    onChanged: (_) => onChanged(),
                    validator: (v) => (int.tryParse(v?.trim() ?? '') ?? 0) < 1
                        ? 'Enter qty'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await _pickUnit(
                        context,
                        current: line.unit,
                        units: unitOptions,
                      );
                      if (picked == null) return;
                      line.unit = picked;
                      onChanged();
                    },
                    child: InputDecorator(
                      decoration: box('Unit').copyWith(
                        suffixIcon: Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 26,
                        ),
                      ),
                      child: Text(
                        line.unit ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: TextFormField(
                    controller: line.cost,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: box('Unit cost', prefix: '₹ ', hint: '0'),
                    onChanged: (_) => onChanged(),
                    validator: (v) =>
                        (double.tryParse(v?.trim() ?? '') ?? -1) < 0
                        ? 'Enter cost'
                        : null,
                  ),
                ),
              ],
            ),
          ),
          // Full-width footer: the working and the full line total.
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$qty${line.unit == null ? '' : ' ${line.unit}'} × ₹${money.format(cost)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '₹${money.format(line.total)}',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pick a purchase category (Masters → Purchase Category) for a bill line
/// (searchable). Only active categories are listed.
class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet();

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  String _q = '';
  late final Future<void> _load = masterCubit.ensureLoaded('purchaseCategory');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _load,
      builder: (context, snap) => _sheet(
        context,
        loading: snap.connectionState != ConnectionState.done,
        failed: snap.hasError,
      ),
    );
  }

  Widget _sheet(
    BuildContext context, {
    required bool loading,
    required bool failed,
  }) {
    final all = masterCubit.itemsOfType('purchaseCategory');
    final q = _q.toLowerCase();
    final shown = [
      for (final c in all)
        if (q.isEmpty || c.name.toLowerCase().contains(q)) c,
    ];
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _q = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : shown.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        failed
                            ? "Couldn't load purchase categories"
                            : all.isEmpty
                            ? 'No purchase categories yet.\nAdd them in Masters → Purchase Category.'
                            : 'No purchase categories found',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    itemCount: shown.length,
                    itemBuilder: (_, i) {
                      final c = shown[i];
                      final about = c.description?.trim() ?? '';
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.brand,
                          child: Icon(
                            Icons.shopping_basket_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: about.isEmpty
                            ? null
                            : Text(
                                about,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        onTap: () => Navigator.of(context).pop(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Notes & Review ─────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController notesCtrl;
  final Map<String, String> preview;
  const _Step3({
    required this.formKey,
    required this.notesCtrl,
    required this.preview,
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
              children: preview.entries.map((e) {
                final isLast = e.key == preview.keys.last;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: e.key == 'Total'
                                  ? AppColors.accentTeal
                                  : cs.onSurface,
                            ),
                          ),
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
// (date picker moved to shared/widgets/brixen_date_field.dart)

class _ImagePicker extends StatelessWidget {
  final XFile? image;
  final VoidCallback onPick, onRemove;
  const _ImagePicker({
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

class _NotesField extends StatefulWidget {
  final TextEditingController controller;
  const _NotesField({required this.controller});
  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  final _focus = FocusNode();
  bool _focused = false, _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    widget.controller.addListener(() {
      final h = widget.controller.text.isNotEmpty;
      if (h != _hasText) setState(() => _hasText = h);
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
                  ? AppColors.accentTeal
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
                  color: _focused ? AppColors.accentTeal : cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bottom sheet of the company's units as chips ("pcs · Pieces"), the
/// current one highlighted. Returns the picked unit name, or null.
Future<String?> _pickUnit(
  BuildContext context, {
  required String? current,
  required List<String> units,
}) {
  final fullForms = {
    for (final u in masterCubit.itemsOfType('unit')) u.name: u.fullForm,
  };
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Select unit',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'What the quantity counts',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            if (units.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No units yet. Add them in Masters → Units.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final u in units)
                        _UnitChip(
                          unit: u,
                          fullForm: fullForms[u],
                          selected: u == current,
                          onTap: () => Navigator.of(ctx).pop(u),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _UnitChip extends StatelessWidget {
  final String unit;
  final String? fullForm;
  final bool selected;
  final VoidCallback onTap;
  const _UnitChip({
    required this.unit,
    required this.fullForm,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.ink;
    return Material(
      color: selected ? AppColors.brand : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minWidth: 92),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                unit,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (fullForm != null && fullForm!.isNotEmpty)
                Text(
                  fullForm!,
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
