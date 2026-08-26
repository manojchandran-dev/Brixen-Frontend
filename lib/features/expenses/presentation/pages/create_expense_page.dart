import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../masters/domain/entities/master_item.dart';
import '../../../masters/presentation/cubit/master_cubit.dart';
import '../../domain/entities/expense.dart';
import '../providers/expenses_provider.dart';

class CreateExpensePage extends ConsumerStatefulWidget {
  final Expense? editExpense;
  final bool fromMasters;
  const CreateExpensePage({super.key, this.editExpense, this.fromMasters = false});

  @override
  ConsumerState<CreateExpensePage> createState() => _CreateExpensePageState();
}

class _CreateExpensePageState extends ConsumerState<CreateExpensePage> {
  bool get _isEditing => widget.editExpense != null;

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Category/unit are selected as full MasterItem objects (not just a name
  // string) since the API needs their ids (category_id/unit_id), not names.
  MasterItem? _selectedCategory;
  MasterItem? _selectedUnit;
  String? _selectedPaymentMethod;
  DateTime _expenseDate = DateTime.now();
  XFile? _receiptImage;
  final _picker = ImagePicker();
  bool _submitting = false;

  // Sourced from Masters (Expense Category / Unit) — loaded independently
  // since MasterCubit only tracks one "active" master type's stream at a
  // time, and this screen needs two lists live at once.
  List<MasterItem> _categories = [];
  List<MasterItem> _units = [];
  bool _loadingCategories = true;
  bool _loadingUnits = true;

  static const _paymentMethods = ['Cash', 'Card', 'UPI', 'Bank Transfer', 'Cheque', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadUnits();
    if (_isEditing) {
      final e = widget.editExpense!;
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _notesCtrl.text = e.notes ?? '';
      _selectedPaymentMethod = e.paymentMethod;
      _expenseDate = e.expenseDate;
    }
  }

  Future<void> _loadCategories() async {
    await masterCubit.load('expenseCategory');
    if (!mounted) return;
    setState(() {
      _categories = masterCubit.itemsOfType('expenseCategory');
      _loadingCategories = false;
      if (_isEditing) {
        final id = widget.editExpense!.categoryId;
        _selectedCategory = _categories.where((c) => c.id == id).firstOrNull;
      }
    });
  }

  Future<void> _loadUnits() async {
    await masterCubit.load('unit');
    if (!mounted) return;
    setState(() {
      _units = masterCubit.itemsOfType('unit');
      _loadingUnits = false;
      if (_isEditing && widget.editExpense!.unitId != null) {
        final id = widget.editExpense!.unitId;
        _selectedUnit = _units.where((u) => u.id == id).firstOrNull;
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _amountCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final img = await _picker.pickImage(source: source, imageQuality: 85);
    if (img != null) setState(() => _receiptImage = img);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          _SourceTile(icon: Icons.camera_alt_outlined, label: 'Camera', accentColor: AppColors.brand, onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
          const SizedBox(height: 10),
          _SourceTile(icon: Icons.photo_library_outlined, label: 'Gallery', accentColor: AppColors.positive, onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
        ]),
      )),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _expenseDate,
      firstDate: DateTime(2020), lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category'), behavior: SnackBarBehavior.floating));
      return;
    }
    final now = DateTime.now();
    final expense = Expense(
      id: _isEditing ? widget.editExpense!.id : '',
      categoryId: _selectedCategory!.id,
      category: _selectedCategory!.name,
      unitId: _selectedUnit?.id,
      unit: _selectedUnit?.name,
      title: _titleCtrl.text.trim(),
      amount: double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0,
      expenseDate: _expenseDate,
      paymentMethod: _selectedPaymentMethod,
      receiptImagePath: _receiptImage?.path ?? (_isEditing ? widget.editExpense!.receiptImagePath : null),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: _isEditing ? widget.editExpense!.createdAt : now,
    );
    setState(() => _submitting = true);
    try {
      if (_isEditing) {
        await ref.read(expensesProvider.notifier).updateExpense(expense);
      } else {
        await ref.read(expensesProvider.notifier).addExpense(expense);
      }
      if (mounted) context.pop();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 40, height: 40,
            margin: const EdgeInsets.all(8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.shadows([
                BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4)),
                BoxShadow(color: AppColors.highlightShadow(0.8), blurRadius: 4, offset: const Offset(-2, -2)),
              ]),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isEditing ? 'Edit Expense' : 'New Expense', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
          Text(_isEditing ? 'Update expense details' : 'Log an expense', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          children: [
            // Category — sourced from the Expense Category master data
            _SectionLabel('Category *'),
            const SizedBox(height: 8),
            BrixenDropdown<MasterItem>(
              hint: _loadingCategories ? 'Loading categories…' : _categories.isEmpty ? 'No categories yet' : 'Select category',
              value: _categories.contains(_selectedCategory) ? _selectedCategory : null,
              items: _categories,
              labelOf: (c) => c.name,
              icon: Icons.category_rounded,
              iconColor: AppColors.brand,
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 18),

            // Unit — sourced from the Unit master data
            _SectionLabel('Unit'),
            const SizedBox(height: 8),
            BrixenDropdown<MasterItem>(
              hint: _loadingUnits ? 'Loading units…' : _units.isEmpty ? 'No units yet' : 'Select unit',
              value: _units.contains(_selectedUnit) ? _selectedUnit : null,
              items: _units,
              labelOf: (u) => u.name,
              icon: Icons.straighten_rounded,
              iconColor: AppColors.positive,
              onChanged: (v) => setState(() => _selectedUnit = v),
            ),
            const SizedBox(height: 18),

            // Title
            BrixenTextField(
              label: 'Title *',
              hint: 'e.g. Monthly office rent',
              controller: _titleCtrl,
              prefixIcon: const Icon(Icons.receipt_long_rounded),
              iconColor: AppColors.brandDeep,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 18),

            // Amount
            BrixenTextField(
              label: 'Amount *',
              hint: '0.00',
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              iconColor: AppColors.brand,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount is required';
                final n = double.tryParse(v.replaceAll(',', ''));
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Expense Date
            _SectionLabel('Expense Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.shadows([
                    BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
                    BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 6, offset: const Offset(-3, -3)),
                  ]),
                ),
                child: Row(children: [
                  Container(
                    width: 34, height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brandLight, AppColors.brand]),
                      boxShadow: AppColors.shadows([BoxShadow(color: AppColors.brandLight.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))]),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(DateFormat('dd MMM yyyy').format(_expenseDate), style: TextStyle(fontSize: 15, color: AppColors.ink)),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textHint),
                ]),
              ),
            ),
            const SizedBox(height: 18),

            // Payment Method
            _SectionLabel('Payment Method'),
            const SizedBox(height: 8),
            BrixenDropdown<String>(
              hint: 'Select payment method',
              value: _selectedPaymentMethod,
              items: _paymentMethods,
              labelOf: (m) => m,
              icon: Icons.credit_card_rounded,
              iconColor: AppColors.ink,
              onChanged: (v) => setState(() => _selectedPaymentMethod = v),
            ),
            const SizedBox(height: 18),

            // Receipt Image
            _SectionLabel('Receipt Image (Optional)'),
            const SizedBox(height: 8),
            _ReceiptImagePicker(
              image: _receiptImage,
              existingPath: _isEditing ? widget.editExpense!.receiptImagePath : null,
              onPickImage: _showImageSourceSheet,
              onRemoveImage: () => setState(() => _receiptImage = null),
            ),
            const SizedBox(height: 18),

            // Notes
            BrixenTextField(
              label: 'Notes (Optional)',
              hint: 'Additional details…',
              controller: _notesCtrl,
              prefixIcon: const Icon(Icons.notes_rounded),
              iconColor: AppColors.brandDeep,
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Submit
            BrixenButton(
              label: _isEditing ? 'Save Changes' : 'Log Expense',
              onPressed: _submitting ? null : _submit,
              isLoading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint));
}

class _ReceiptImagePicker extends StatelessWidget {
  final XFile? image;
  final String? existingPath;
  final VoidCallback onPickImage, onRemoveImage;
  const _ReceiptImagePicker({required this.image, required this.existingPath, required this.onPickImage, required this.onRemoveImage});

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null || existingPath != null;

    if (!hasImage) {
      return GestureDetector(
        onTap: onPickImage,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.shadows([
              BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
              BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 6, offset: const Offset(-3, -3)),
            ]),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 40, height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
                boxShadow: AppColors.shadows([BoxShadow(color: AppColors.brand.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))]),
              ),
              child: const Icon(Icons.upload_file_rounded, size: 20, color: AppColors.white),
            ),
            const SizedBox(height: 8),
            Text('Tap to upload receipt', style: TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w500)),
            Text('Camera or Gallery', style: TextStyle(fontSize: 11, color: AppColors.textHint.withValues(alpha: 0.8))),
          ]),
        ),
      );
    }

    final imgWidget = image != null
        ? Image.file(File(image!.path), fit: BoxFit.cover, width: double.infinity, height: 180)
        : Image.file(File(existingPath!), fit: BoxFit.cover, width: double.infinity, height: 180);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadows([
          BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 6, offset: const Offset(-3, -3)),
        ]),
      ),
      child: Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(16), child: imgWidget),
        Positioned(top: 8, right: 8, child: GestureDetector(
          onTap: onRemoveImage,
          child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.shadowDark.withValues(alpha: 0.6), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 16, color: AppColors.white)),
        )),
      ]),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon; final String label; final Color accentColor; final VoidCallback onTap;
  const _SourceTile({required this.icon, required this.label, required this.accentColor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.shadows([
            BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
            BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 6, offset: const Offset(-3, -3)),
          ]),
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accentColor, accentColor.withValues(alpha: 0.75)]),
              boxShadow: AppColors.shadows([BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))]),
            ),
            child: Icon(icon, size: 17, color: AppColors.white),
          ),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ]),
      ),
    );
  }
}
