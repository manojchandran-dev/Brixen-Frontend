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

  // Category names come from user-defined Masters data, so colors/icons are
  // assigned by hashing the name instead of matching fixed keywords — every
  // distinct category gets a consistent look even for custom category names.
  static const _categoryColors = [AppColors.brand, AppColors.positive, AppColors.brandDeep, AppColors.brandLight, AppColors.ink];
  static const _categoryIcons = [
    Icons.receipt_rounded, Icons.home_rounded, Icons.people_rounded, Icons.electrical_services_rounded,
    Icons.directions_car_rounded, Icons.restaurant_rounded, Icons.inventory_2_rounded, Icons.campaign_rounded, Icons.build_rounded,
  ];
  Color _categoryColor(String cat) => _categoryColors[cat.toLowerCase().hashCode.abs() % _categoryColors.length];
  IconData _categoryIcon(String cat) => _categoryIcons[cat.toLowerCase().hashCode.abs() % _categoryIcons.length];

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: Text('Delete "${expense.title}"? This cannot be undone.', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                if (context.mounted) context.go(AppRouter.expenses);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.ink),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final catColor = _categoryColor(expense.category);

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
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4)),
                BoxShadow(color: AppColors.white.withValues(alpha: 0.8), blurRadius: 4, offset: const Offset(-2, -2)),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Expenses', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
              const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textHint),
              Flexible(child: Text(expense.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink))),
            ]),
          ),
          Text(DateFormat('dd MMM yyyy').format(expense.expenseDate), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createExpense, extra: expense),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              width: 38, height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.brand.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.white),
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context, ref),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
              width: 38, height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.ink),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Category + Amount hero card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 10)),
                BoxShadow(color: AppColors.white.withValues(alpha: 0.85), blurRadius: 8, offset: const Offset(-3, -3)),
              ],
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [catColor, catColor.withValues(alpha: 0.75)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: catColor.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
                ),
                child: Icon(_categoryIcon(expense.category), color: AppColors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expense.category, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: catColor)),
                const SizedBox(height: 2),
                Text(expense.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 8),
              Text('₹${fmt.format(expense.amount)}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ]),
          ),
          const SizedBox(height: 16),

          if (expense.receiptImagePath != null) ...[
            ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(File(expense.receiptImagePath!), width: double.infinity, height: 200, fit: BoxFit.cover)),
            const SizedBox(height: 16),
          ],

          _Card(child: Column(children: [
            _Row(icon: Icons.calendar_today_rounded, iconColor: AppColors.brand, label: 'Expense Date', value: DateFormat('dd MMM yyyy').format(expense.expenseDate)),
            if (expense.unit != null && expense.unit!.isNotEmpty) ...[
              _Divider(),
              _Row(icon: Icons.straighten_rounded, iconColor: AppColors.positive, label: 'Unit', value: expense.unit!),
            ],
            if (expense.paymentMethod != null) ...[
              _Divider(),
              _Row(icon: Icons.credit_card_rounded, iconColor: AppColors.brandDeep, label: 'Payment Method', value: expense.paymentMethod!),
            ],
          ])),
          const SizedBox(height: 16),

          if (expense.notes != null && expense.notes!.isNotEmpty) ...[
            _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Notes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.3)),
              const SizedBox(height: 8),
              Text(expense.notes!, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
            ])),
            const SizedBox(height: 16),
          ],

          _Card(child: _Row(icon: Icons.history_rounded, iconColor: AppColors.brandLight, label: 'Created', value: DateFormat('dd MMM yyyy, hh:mm a').format(expense.createdAt))),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
        BoxShadow(color: AppColors.white.withValues(alpha: 0.85), blurRadius: 6, offset: const Offset(-3, -3)),
      ],
    ),
    child: child,
  );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;
  const _Row({required this.icon, required this.iconColor, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 32, height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [iconColor, iconColor.withValues(alpha: 0.75)]),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Icon(icon, size: 16, color: AppColors.white),
    ),
    const SizedBox(width: 12),
    Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textHint)),
    Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink))),
  ]);
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppColors.border));
}
