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
import '../../domain/entities/purchase.dart';
import '../providers/purchases_provider.dart';

class CreatePurchasePage extends ConsumerStatefulWidget {
  final bool fromMasters;
  final Purchase? editPurchase;
  const CreatePurchasePage({super.key, this.fromMasters = false, this.editPurchase});

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
  DateTime _billDate = DateTime.now();
  String? _invoiceType;
  XFile? _billImage;
  final _picker = ImagePicker();

  // Step 2
  final _subtotalCtrl    = TextEditingController();
  final _taxAmountCtrl   = TextEditingController();
  final _totalAmountCtrl = TextEditingController();
  String? _paymentType;
  String? _paymentStatus;

  // Step 3
  final _notesCtrl = TextEditingController();

  bool get _isEditing => widget.editPurchase != null;

  static const _invoiceTypes   = ['Tax Invoice', 'Proforma Invoice', 'Credit Note', 'Debit Note', 'Delivery Challan'];
  static const _paymentTypes   = ['Cash', 'Card', 'UPI', 'Bank Transfer', 'Cheque', 'Other'];
  static const _paymentStatuses = ['Paid', 'Pending', 'Partial', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    final p = widget.editPurchase;
    if (p != null) {
      _supplierCtrl.text    = p.supplierName;
      _billDate             = p.billDate;
      _invoiceType          = p.invoiceType;
      if (p.billImagePath != null) _billImage = XFile(p.billImagePath!);
      _subtotalCtrl.text    = p.subtotal.toString();
      _taxAmountCtrl.text   = p.taxAmount.toString();
      _totalAmountCtrl.text = p.totalAmount.toString();
      _paymentType          = p.paymentType;
      _paymentStatus        = p.paymentStatus;
      _notesCtrl.text       = p.notes ?? '';
    }
  }

  @override
  void dispose() {
    _supplierCtrl.dispose();
    _subtotalCtrl.dispose(); _taxAmountCtrl.dispose(); _totalAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  GlobalKey<FormState> get _currentFormKey => [_step1Key, _step2Key, _step3Key][_currentStep];

  void _next() { if (!_currentFormKey.currentState!.validate()) return; if (_currentStep < 2) setState(() => _currentStep++); }
  void _back() { if (_currentStep > 0) setState(() => _currentStep--); }

  void _recalcTotal() {
    final sub = double.tryParse(_subtotalCtrl.text) ?? 0;
    final tax = double.tryParse(_taxAmountCtrl.text) ?? 0;
    _totalAmountCtrl.text = (sub + tax).toStringAsFixed(2);
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file != null) setState(() => _billImage = file);
  }

  void _showImageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Attach Bill Image', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _SourceTile(icon: Icons.camera_alt_outlined, label: 'Camera', onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); })),
              const SizedBox(width: 12),
              Expanded(child: _SourceTile(icon: Icons.photo_library_outlined, label: 'Gallery', onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); })),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_currentFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 400));
    final purchase = Purchase(
      id: _isEditing ? widget.editPurchase!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      supplierName: _supplierCtrl.text.trim(),
      billNo: _isEditing ? widget.editPurchase!.billNo : '',
      billDate: _billDate,
      invoiceType: _invoiceType,
      subtotal: double.tryParse(_subtotalCtrl.text) ?? 0,
      taxAmount: double.tryParse(_taxAmountCtrl.text) ?? 0,
      totalAmount: double.tryParse(_totalAmountCtrl.text) ?? 0,
      paymentType: _paymentType,
      paymentStatus: _paymentStatus ?? 'Pending',
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      billImagePath: _billImage?.path,
      createdAt: _isEditing ? widget.editPurchase!.createdAt : DateTime.now(),
    );
    if (_isEditing) { ref.read(purchasesProvider.notifier).updatePurchase(purchase); }
    else            { ref.read(purchasesProvider.notifier).addPurchase(purchase); }
    if (!mounted) return;
    if (widget.fromMasters) { context.pop(); } else { context.go(AppRouter.purchases); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Theme.of(context).dividerColor)),
        leading: GestureDetector(
          onTap: () { if (_currentStep == 0) { widget.fromMasters ? context.pop() : context.go(AppRouter.purchases); } else { _back(); } },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.silverGradient : null,
              color: isDark ? null : AppColors.lightPrimary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: isDark ? AppColors.black : AppColors.white),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.fromMasters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                GestureDetector(onTap: () => context.pop(), child: Text('Menu', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.chevron_right_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                GestureDetector(onTap: () => context.pop(), child: Text('Masters', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.chevron_right_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                GestureDetector(onTap: () => context.pop(), child: Text('Purchases', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.chevron_right_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                Text(_isEditing ? 'Edit' : 'Create', style: TextStyle(color: cs.onSurface, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            )
          else
            Text(_isEditing ? 'Edit Purchase' : 'New Purchase', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
          Text('Step ${_currentStep + 1} of 3 — ${['Supplier Info', 'Amounts', 'Notes'][_currentStep]}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
        ]),
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep, labels: const ['Supplier', 'Amounts', 'Notes'], accentColor: AppColors.accentTeal),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim), child: child)),
              child: KeyedSubtree(key: ValueKey(_currentStep), child: _buildStep()),
            ),
          ),
          _NavBar(currentStep: _currentStep, submitting: _submitting, isEditing: _isEditing, onBack: _back, onNext: _next, onSubmit: _submit),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0: return _Step1(formKey: _step1Key, supplierCtrl: _supplierCtrl, billDate: _billDate, invoiceType: _invoiceType, invoiceTypes: _invoiceTypes, billImage: _billImage, onDateChanged: (d) => setState(() => _billDate = d), onInvoiceTypeChanged: (v) => setState(() => _invoiceType = v), onPickImage: _showImageSheet, onRemoveImage: () => setState(() => _billImage = null));
      case 1: return _Step2(formKey: _step2Key, subtotalCtrl: _subtotalCtrl, taxAmountCtrl: _taxAmountCtrl, totalAmountCtrl: _totalAmountCtrl, paymentType: _paymentType, paymentStatus: _paymentStatus, paymentTypes: _paymentTypes, paymentStatuses: _paymentStatuses, onPaymentTypeChanged: (v) => setState(() => _paymentType = v), onPaymentStatusChanged: (v) => setState(() => _paymentStatus = v), onRecalc: _recalcTotal);
      default: return _Step3(formKey: _step3Key, notesCtrl: _notesCtrl, preview: {
        'Supplier': _supplierCtrl.text.trim().isEmpty ? '—' : _supplierCtrl.text.trim(),
        'Date': DateFormat('dd MMM yyyy').format(_billDate),
        'Invoice Type': _invoiceType ?? '—',
        'Subtotal': '₹${_subtotalCtrl.text.isEmpty ? '0.00' : _subtotalCtrl.text}',
        'Tax': '₹${_taxAmountCtrl.text.isEmpty ? '0.00' : _taxAmountCtrl.text}',
        'Total': '₹${_totalAmountCtrl.text.isEmpty ? '0.00' : _totalAmountCtrl.text}',
        'Payment Type': _paymentType ?? '—',
        'Status': _paymentStatus ?? 'Pending',
      });
    }
  }
}

// ── Step Indicator ─────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  final Color accentColor;
  const _StepIndicator({required this.currentStep, required this.labels, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(labels.length, (i) {
          final done = i < currentStep;
          final active = i == currentStep;
          return Expanded(child: Row(children: [
            Expanded(child: Column(children: [
              Row(children: [
                if (i > 0) Expanded(child: Container(height: 2, color: i <= currentStep ? accentColor : Theme.of(context).dividerColor)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (done || active) ? accentColor : cs.surfaceContainerHighest,
                    border: Border.all(color: (done || active) ? accentColor : Theme.of(context).dividerColor, width: active ? 2 : 1),
                  ),
                  child: Center(child: done
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : cs.onSurfaceVariant))),
                ),
                if (i < labels.length - 1) Expanded(child: Container(height: 2, color: i < currentStep ? accentColor : Theme.of(context).dividerColor)),
              ]),
              const SizedBox(height: 6),
              Text(labels[i], style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.normal, color: active ? cs.onSurface : cs.onSurfaceVariant)),
            ])),
          ]));
        }),
      ),
    );
  }
}

// ── Nav Bar ────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int currentStep; final bool submitting, isEditing;
  final VoidCallback onBack, onNext, onSubmit;
  const _NavBar({required this.currentStep, required this.submitting, required this.isEditing, required this.onBack, required this.onNext, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
      child: Row(children: [
        if (currentStep > 0) ...[Expanded(child: BrixenButton(label: 'Back', isOutlined: true, onPressed: onBack)), const SizedBox(width: 12)],
        Expanded(flex: 2, child: BrixenButton(
          label: currentStep == 2 ? (isEditing ? 'Save Changes' : 'Create Purchase') : 'Continue',
          isLoading: submitting,
          onPressed: submitting ? null : (currentStep == 2 ? onSubmit : onNext),
        )),
      ]),
    );
  }
}

// ── Step 1: Supplier Info ──────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController supplierCtrl;
  final DateTime billDate;
  final String? invoiceType;
  final List<String> invoiceTypes;
  final XFile? billImage;
  final void Function(DateTime) onDateChanged;
  final void Function(String?) onInvoiceTypeChanged;
  final VoidCallback onPickImage, onRemoveImage;

  const _Step1({required this.formKey, required this.supplierCtrl, required this.billDate, required this.invoiceType, required this.invoiceTypes, required this.billImage, required this.onDateChanged, required this.onInvoiceTypeChanged, required this.onPickImage, required this.onRemoveImage});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 28, 16, 16), children: [
        BrixenTextField(
          label: 'Supplier Name *', hint: 'Enter supplier or vendor name',
          controller: supplierCtrl, textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.store_outlined),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 22),
        _DateField(value: billDate, onChanged: onDateChanged),
        const SizedBox(height: 22),
        BrixenDropdown<String>(hint: 'Invoice Type', value: invoiceType, items: invoiceTypes, labelOf: (s) => s, icon: Icons.description_outlined, onChanged: onInvoiceTypeChanged),
        const SizedBox(height: 22),
        _ImagePicker(image: billImage, onPick: onPickImage, onRemove: onRemoveImage),
        const SizedBox(height: 22),
      ]),
    );
  }
}

// ── Step 2: Amounts ────────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController subtotalCtrl, taxAmountCtrl, totalAmountCtrl;
  final String? paymentType, paymentStatus;
  final List<String> paymentTypes, paymentStatuses;
  final void Function(String?) onPaymentTypeChanged, onPaymentStatusChanged;
  final VoidCallback onRecalc;

  const _Step2({required this.formKey, required this.subtotalCtrl, required this.taxAmountCtrl, required this.totalAmountCtrl, required this.paymentType, required this.paymentStatus, required this.paymentTypes, required this.paymentStatuses, required this.onPaymentTypeChanged, required this.onPaymentStatusChanged, required this.onRecalc});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 28, 16, 16), children: [
        BrixenTextField(label: 'Subtotal *', hint: '0.00', controller: subtotalCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.next, prefixIcon: const Icon(Icons.currency_rupee_rounded), onFieldSubmitted: (_) => onRecalc(), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
        const SizedBox(height: 22),
        BrixenTextField(label: 'Tax Amount', hint: '0.00', controller: taxAmountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.next, prefixIcon: const Icon(Icons.percent_rounded), onFieldSubmitted: (_) => onRecalc()),
        const SizedBox(height: 8),
        _RecalcButton(onTap: onRecalc),
        const SizedBox(height: 22),
        BrixenTextField(label: 'Total Amount', hint: '0.00', controller: totalAmountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.next, prefixIcon: const Icon(Icons.account_balance_wallet_outlined)),
        const SizedBox(height: 22),
        BrixenDropdown<String>(hint: 'Payment Type', value: paymentType, items: paymentTypes, labelOf: (s) => s, icon: Icons.payment_outlined, onChanged: onPaymentTypeChanged),
        const SizedBox(height: 22),
        BrixenDropdown<String>(hint: 'Payment Status *', value: paymentStatus, items: paymentStatuses, labelOf: (s) => s, icon: Icons.check_circle_outline_rounded, onChanged: onPaymentStatusChanged),
        const SizedBox(height: 22),
      ]),
    );
  }
}

// ── Step 3: Notes & Review ─────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController notesCtrl;
  final Map<String, String> preview;
  const _Step3({required this.formKey, required this.notesCtrl, required this.preview});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: formKey,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 28, 16, 16), children: [
        _NotesField(controller: notesCtrl),
        const SizedBox(height: 28),
        Text('Review', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
          child: Column(children: preview.entries.map((e) {
            final isLast = e.key == preview.keys.last;
            return Column(children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.key, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                Text(e.value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: e.key == 'Total' ? AppColors.accentTeal : cs.onSurface)),
              ])),
              if (!isLast) Divider(height: 1, color: Theme.of(context).dividerColor),
            ]);
          }).toList()),
        ),
        const SizedBox(height: 22),
      ]),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final DateTime value;
  final void Function(DateTime) onChanged;
  const _DateField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(DateFormat('dd MMM yyyy').format(value), style: TextStyle(fontSize: 15, color: cs.onSurface))),
          Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }
}

class _RecalcButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RecalcButton({required this.onTap});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calculate_outlined, size: 14, color: AppColors.accentTeal),
          const SizedBox(width: 6),
          Text('Auto-calculate total', style: TextStyle(fontSize: 12, color: AppColors.accentTeal, fontWeight: FontWeight.w500)),
        ]),
      ),
    ),
  );
}

class _ImagePicker extends StatelessWidget {
  final XFile? image; final VoidCallback onPick, onRemove;
  const _ImagePicker({required this.image, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (image != null) {
      return Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(image!.path), width: double.infinity, height: 180, fit: BoxFit.cover)),
        Positioned(top: 8, right: 8, child: GestureDetector(onTap: onRemove, child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 16, color: Colors.white)))),
        Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_rounded, size: 12, color: Colors.white), SizedBox(width: 4), Text('Bill attached', style: TextStyle(fontSize: 11, color: Colors.white))]))),
      ]);
    }
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: (isDark ? AppColors.silver : AppColors.lightPrimary).withValues(alpha: 0.25), width: 1.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.upload_file_outlined, size: 32, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text('Attach Bill Image', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 3),
          Text('Optional — tap to pick from camera or gallery', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
        ]),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _SourceTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(children: [Icon(icon, size: 28, color: isDark ? AppColors.silver : AppColors.lightPrimary), const SizedBox(height: 8), Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface))]),
    ));
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
    widget.controller.addListener(() { final h = widget.controller.text.isNotEmpty; if (h != _hasText) setState(() => _hasText = h); });
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showLabel = _focused || _hasText;
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: _focused ? AppColors.accentTeal : Theme.of(context).dividerColor, width: _focused ? 1.5 : 1)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(left: 14, top: 14), child: Icon(Icons.notes_rounded, color: cs.onSurfaceVariant, size: 20)),
          Expanded(child: TextFormField(controller: widget.controller, focusNode: _focus, maxLines: 4, style: TextStyle(color: cs.onSurface, fontSize: 15),
            decoration: InputDecoration(hintText: showLabel ? 'Add any remarks or notes' : 'Notes', hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: const EdgeInsets.fromLTRB(8, 14, 16, 14)))),
        ]),
      ),
      if (showLabel) Positioned(top: -9, left: 12, child: Container(color: cs.surfaceContainerHighest, padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('Notes', style: TextStyle(color: _focused ? AppColors.accentTeal : cs.onSurfaceVariant, fontSize: 12)))),
    ]);
  }
}
