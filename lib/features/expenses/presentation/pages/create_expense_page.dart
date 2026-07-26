import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
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

  String? _selectedCategory;
  String? _selectedPaymentMethod;
  DateTime _expenseDate = DateTime.now();
  XFile? _receiptImage;
  final _picker = ImagePicker();

  static const _categories = [
    'Rent', 'Salary', 'Utilities', 'Travel', 'Food',
    'Office Supplies', 'Marketing', 'Maintenance', 'Other',
  ];
  static const _paymentMethods = ['Cash', 'UPI', 'Card', 'Bank Transfer', 'Cheque'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.editExpense!;
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _notesCtrl.text = e.notes ?? '';
      _selectedCategory = e.category;
      _selectedPaymentMethod = e.paymentMethod;
      _expenseDate = e.expenseDate;
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          _SourceTile(icon: Icons.camera_alt_outlined, label: 'Camera', isDark: isDark, onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
          const SizedBox(height: 10),
          _SourceTile(icon: Icons.photo_library_outlined, label: 'Gallery', isDark: isDark, onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category'), behavior: SnackBarBehavior.floating));
      return;
    }
    final now = DateTime.now();
    final expense = Expense(
      id: _isEditing ? widget.editExpense!.id : now.millisecondsSinceEpoch.toString(),
      category: _selectedCategory!,
      title: _titleCtrl.text.trim(),
      amount: double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0,
      expenseDate: _expenseDate,
      paymentMethod: _selectedPaymentMethod,
      receiptImagePath: _receiptImage?.path ?? (_isEditing ? widget.editExpense!.receiptImagePath : null),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: _isEditing ? widget.editExpense!.createdAt : now,
    );
    if (_isEditing) {
      ref.read(expensesProvider.notifier).updateExpense(expense);
    } else {
      ref.read(expensesProvider.notifier).addExpense(expense);
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppColors.accentRose;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Theme.of(context).dividerColor)),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: isDark ? AppColors.silverGradient : null, color: isDark ? null : AppColors.lightTextPrimary, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2), blurRadius: 6, offset: const Offset(0, 2))]),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: isDark ? AppColors.black : AppColors.white),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isEditing ? 'Edit Expense' : 'New Expense', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
          Text(_isEditing ? 'Update expense details' : 'Log an expense', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          children: [
            // Category Dropdown
            _SectionLabel('Category *'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
              child: DropdownButtonHideUnderline(
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    hint: Text('Select category', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                    dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                    isExpanded: true,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            _SectionLabel('Title *'),
            const SizedBox(height: 8),
            _Field(ctrl: _titleCtrl, hint: 'e.g. Monthly office rent', isDark: isDark, validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null),
            const SizedBox(height: 18),

            // Amount
            _SectionLabel('Amount *'),
            const SizedBox(height: 8),
            _Field(ctrl: _amountCtrl, hint: '0.00', isDark: isDark, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Amount is required';
              final n = double.tryParse(v.replaceAll(',', ''));
              if (n == null || n <= 0) return 'Enter a valid amount';
              return null;
            }),
            const SizedBox(height: 18),

            // Expense Date
            _SectionLabel('Expense Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Text(DateFormat('dd MMM yyyy').format(_expenseDate), style: TextStyle(fontSize: 14, color: cs.onSurface)),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant),
                ]),
              ),
            ),
            const SizedBox(height: 18),

            // Payment Method
            _SectionLabel('Payment Method'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
              child: DropdownButtonHideUnderline(
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton<String>(
                    value: _selectedPaymentMethod,
                    hint: Text('Select payment method', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                    dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                    isExpanded: true,
                    items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _selectedPaymentMethod = v),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Receipt Image
            _SectionLabel('Receipt Image (Optional)'),
            const SizedBox(height: 8),
            _ReceiptImagePicker(
              image: _receiptImage,
              existingPath: _isEditing ? widget.editExpense!.receiptImagePath : null,
              isDark: isDark,
              onPickImage: _showImageSourceSheet,
              onRemoveImage: () => setState(() => _receiptImage = null),
            ),
            const SizedBox(height: 18),

            // Notes
            _SectionLabel('Notes (Optional)'),
            const SizedBox(height: 8),
            _NotesField(ctrl: _notesCtrl, isDark: isDark),
            const SizedBox(height: 32),

            // Submit
            GestureDetector(
              onTap: _submit,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.8)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text(_isEditing ? 'Save Changes' : 'Log Expense', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
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
  Widget build(BuildContext context) => Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool isDark;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _Field({required this.ctrl, required this.hint, required this.isDark, this.keyboardType, this.validator});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: ctrl, validator: validator, keyboardType: keyboardType,
      style: TextStyle(color: cs.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        filled: true, fillColor: cs.surfaceContainerHighest, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.silver : AppColors.lightTextPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5)),
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isDark;
  const _NotesField({required this.ctrl, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: ctrl, maxLines: 4,
      style: TextStyle(color: cs.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Additional details…', hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        filled: true, fillColor: cs.surfaceContainerHighest, contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.silver : AppColors.lightTextPrimary, width: 1.5)),
      ),
    );
  }
}

class _ReceiptImagePicker extends StatelessWidget {
  final XFile? image;
  final String? existingPath;
  final bool isDark;
  final VoidCallback onPickImage, onRemoveImage;
  const _ReceiptImagePicker({required this.image, required this.existingPath, required this.isDark, required this.onPickImage, required this.onRemoveImage});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasImage = image != null || existingPath != null;

    if (!hasImage) {
      return GestureDetector(
        onTap: onPickImage,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.solid),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.upload_file_outlined, size: 32, color: AppColors.accentRose.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Text('Tap to upload receipt', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            Text('Camera or Gallery', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
          ]),
        ),
      );
    }

    final imgWidget = image != null
        ? Image.file(File(image!.path), fit: BoxFit.cover, width: double.infinity, height: 180)
        : Image.file(File(existingPath!), fit: BoxFit.cover, width: double.infinity, height: 180);

    return Stack(children: [
      ClipRRect(borderRadius: BorderRadius.circular(12), child: imgWidget),
      Positioned(top: 8, right: 8, child: GestureDetector(
        onTap: onRemoveImage,
        child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 16, color: Colors.white)),
      )),
    ]);
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon; final String label; final bool isDark; final VoidCallback onTap;
  const _SourceTile({required this.icon, required this.label, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Row(children: [
          Icon(icon, size: 20, color: cs.onSurface),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface)),
        ]),
      ),
    );
  }
}
