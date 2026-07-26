import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/expense.dart';
import '../providers/expenses_provider.dart';

class ExpenseDetailPage extends ConsumerWidget {
  final Expense expense;
  const ExpenseDetailPage({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final catColor = _categoryColor(expense.category);

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
          Text(expense.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
          Text(DateFormat('dd MMM yyyy').format(expense.expenseDate), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createExpense, extra: expense),
            child: Container(margin: const EdgeInsets.fromLTRB(0, 8, 8, 8), width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accentIndigo.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3))), child: Icon(Icons.edit_outlined, size: 18, color: AppColors.accentIndigo)),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context, ref),
            child: Container(margin: const EdgeInsets.fromLTRB(0, 8, 16, 8), width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accentRose.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3))), child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // Category + Amount hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: catColor.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: catColor.withValues(alpha: 0.3))),
                child: Icon(_categoryIcon(expense.category), color: catColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expense.category, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: catColor)),
                const SizedBox(height: 2),
                Text(expense.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
              ])),
              Text('₹${fmt.format(expense.amount)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accentRose)),
            ]),
          ),
          const SizedBox(height: 16),

          if (expense.receiptImagePath != null) ...[
            ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(expense.receiptImagePath!), width: double.infinity, height: 200, fit: BoxFit.cover)),
            const SizedBox(height: 16),
          ],

          _Card(isDark: isDark, child: Column(children: [
            _Row(label: 'Expense Date', value: DateFormat('dd MMM yyyy').format(expense.expenseDate), color: cs.onSurface),
            if (expense.paymentMethod != null) ...[
              _Divider(),
              _Row(label: 'Payment Method', value: expense.paymentMethod!, color: cs.onSurface),
            ],
          ])),
          const SizedBox(height: 14),

          if (expense.notes != null && expense.notes!.isNotEmpty) ...[
            _Card(isDark: isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Notes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(expense.notes!, style: TextStyle(fontSize: 14, color: cs.onSurface)),
            ])),
            const SizedBox(height: 14),
          ],

          _Card(isDark: isDark, child: _Row(label: 'Created', value: DateFormat('dd MMM yyyy, hh:mm a').format(expense.createdAt), color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
        content: Text('Delete "${expense.title}"? This cannot be undone.', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant))),
          TextButton(
            onPressed: () { ref.read(expensesProvider.notifier).deleteExpense(expense.id); Navigator.pop(context); context.go(AppRouter.expenses); },
            child: Text('Delete', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'rent':            return AppColors.accentIndigo;
      case 'salary':          return AppColors.accentEmerald;
      case 'utilities':       return AppColors.accentTeal;
      case 'travel':          return AppColors.accentViolet;
      case 'food':            return AppColors.accentGold;
      case 'office supplies': return AppColors.accentSlate;
      case 'marketing':       return AppColors.accentRose;
      case 'maintenance':     return AppColors.accentIndigo;
      default:                return AppColors.accentSlate;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'rent':            return Icons.home_outlined;
      case 'salary':          return Icons.people_outline_rounded;
      case 'utilities':       return Icons.electrical_services_outlined;
      case 'travel':          return Icons.directions_car_outlined;
      case 'food':            return Icons.restaurant_outlined;
      case 'office supplies': return Icons.inventory_2_outlined;
      case 'marketing':       return Icons.campaign_outlined;
      case 'maintenance':     return Icons.build_outlined;
      default:                return Icons.receipt_outlined;
    }
  }
}

class _Card extends StatelessWidget {
  final Widget child; final bool isDark;
  const _Card({required this.child, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : AppColors.lightSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
    child: child,
  );
}

class _Row extends StatelessWidget {
  final String label, value; final Color color;
  const _Row({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color))),
  ]);
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Theme.of(context).dividerColor));
}
