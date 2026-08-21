import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../domain/entities/sale.dart';
import '../providers/sales_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/presentation/providers/customers_provider.dart';

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
  final _picker = ImagePicker();

  // Step 2 — Amounts
  final _subtotalCtrl = TextEditingController();
  final _taxAmountCtrl = TextEditingController();
  final _totalAmountCtrl = TextEditingController();
  String? _paymentType;
  String? _paymentStatus;

  // Step 3 — Notes
  final _notesCtrl = TextEditingController();

  bool get _isEditing => widget.editSale != null;

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
      _paymentType = s.paymentType;
      _paymentStatus = s.paymentStatus;
      _notesCtrl.text = s.notes ?? '';
      // Pre-select customer after provider loads
      if (s.customerId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final customers = ref.read(customersProvider).valueOrNull ?? [];
          final matches = customers.where((c) => c.id == s.customerId);
          if (matches.isNotEmpty && mounted) {
            setState(() => _selectedCustomer = matches.first);
          }
        });
      }
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
    _subtotalCtrl.dispose(); _taxAmountCtrl.dispose(); _totalAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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

  void _recalcTotal() {
    final sub = double.tryParse(_subtotalCtrl.text) ?? 0;
    final tax = double.tryParse(_taxAmountCtrl.text) ?? 0;
    _totalAmountCtrl.text = (sub + tax).toStringAsFixed(2);
  }

  Future<void> _submit() async {
    if (!_currentFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final sub = double.tryParse(_subtotalCtrl.text) ?? 0;
    final tax = double.tryParse(_taxAmountCtrl.text) ?? 0;
    final sale = Sale(
      id: _isEditing ? widget.editSale!.id : '',
      customerId: _selectedCustomer?.id,
      billDate: _billDate,
      invoiceType: _invoiceType,
      subtotal: sub,
      taxAmount: tax,
      totalAmount: double.tryParse(_totalAmountCtrl.text) ?? (sub + tax),
      paymentType: _paymentType,
      paymentStatus: _paymentStatus ?? 'Pending',
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      billImagePath: _billImage?.path,
      createdAt: _isEditing ? widget.editSale!.createdAt : DateTime.now(),
    );
    try {
      if (_isEditing) {
        await ref.read(salesProvider.notifier).updateSale(sale);
      } else {
        await ref.read(salesProvider.notifier).addSale(sale);
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
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.ink),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
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
        );
      case 1:
        return _Step2(
          formKey: _step2Key,
          subtotalCtrl: _subtotalCtrl,
          taxAmountCtrl: _taxAmountCtrl,
          totalAmountCtrl: _totalAmountCtrl,
          paymentType: _paymentType,
          paymentStatus: _paymentStatus,
          paymentTypes: _paymentTypes,
          paymentStatuses: _paymentStatuses,
          onPaymentTypeChanged: (v) => setState(() => _paymentType = v),
          onPaymentStatusChanged: (v) => setState(() => _paymentStatus = v),
          onRecalc: _recalcTotal,
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
    'Subtotal': '₹${_subtotalCtrl.text.isEmpty ? '0.00' : _subtotalCtrl.text}',
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
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
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
  final TextEditingController subtotalCtrl, taxAmountCtrl, totalAmountCtrl;
  final String? paymentType, paymentStatus;
  final List<String> paymentTypes, paymentStatuses;
  final void Function(String?) onPaymentTypeChanged;
  final void Function(String?) onPaymentStatusChanged;
  final VoidCallback onRecalc;

  const _Step2({
    required this.formKey,
    required this.subtotalCtrl,
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
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        children: [
          BrixenTextField(
            label: 'Subtotal *',
            hint: '0.00',
            controller: subtotalCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.currency_rupee_rounded),
            onFieldSubmitted: (_) => onRecalc(),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'Tax Amount',
            hint: '0.00',
            controller: taxAmountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.percent_rounded),
            onFieldSubmitted: (_) => onRecalc(),
          ),
          const SizedBox(height: 8),
          _RecalcButton(onTap: onRecalc),
          const SizedBox(height: 22),

          BrixenTextField(
            label: 'Total Amount',
            hint: '0.00',
            controller: totalAmountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
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

class _RecalcButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RecalcButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calculate_outlined,
                  size: 14, color: AppColors.accentIndigo),
              const SizedBox(width: 6),
              Text('Auto-calculate total',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accentIndigo,
                      fontWeight: FontWeight.w500)),
            ],
          ),
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
            child: Image.file(
              File(image!.path),
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
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
