import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../domain/entities/expense.dart';
import '../providers/expenses_provider.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  final bool fromMasters;
  const ExpensesPage({super.key, this.fromMasters = false});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const AppBottomNav(activeIndex: 3),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Theme.of(context).dividerColor)),
        leading: GestureDetector(
          onTap: () => widget.fromMasters ? context.pop() : context.go(AppRouter.companies),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: isDark ? AppColors.silverGradient : null, color: isDark ? null : AppColors.lightTextPrimary, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2), blurRadius: 6, offset: const Offset(0, 2))]),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: isDark ? AppColors.black : AppColors.white),
          ),
        ),
        title: widget.fromMasters
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  GestureDetector(onTap: () => context.pop(), child: Text('Menu', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_right_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                  GestureDetector(onTap: () => context.pop(), child: Text('Masters', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_right_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.4))),
                  Text('Expenses', style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Expenses', style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
                expensesAsync.whenOrNull(data: (l) => Text('${l.length} records', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11))) ?? const SizedBox.shrink(),
              ]),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRouter.createExpense, extra: widget.fromMasters ? 'masters' : null),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 16, 8), width: 36, height: 36,
              decoration: BoxDecoration(gradient: isDark ? AppColors.silverGradient : null, color: isDark ? null : AppColors.lightTextPrimary, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2), blurRadius: 6, offset: const Offset(0, 2))]),
              child: Icon(Icons.add_rounded, size: 20, color: isDark ? AppColors.black : AppColors.white),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _searchCtrl, onChanged: (_) => setState(() {}),
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by title or category…',
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 20),
              filled: true, fillColor: cs.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.silver : AppColors.lightTextPrimary, width: 1.5)),
            ),
          ),
        ),
        Expanded(
          child: expensesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: cs.error, fontSize: 13))),
            data: (list) {
              final q = _searchCtrl.text.trim().toLowerCase();
              final filtered = q.isEmpty ? list : list.where((e) => e.title.toLowerCase().contains(q) || e.category.toLowerCase().contains(q)).toList();
              if (filtered.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.receipt_outlined, size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(list.isEmpty ? 'No expenses yet' : 'No results', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                  if (list.isEmpty) ...[const SizedBox(height: 6), Text('Tap + to log your first expense', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))],
                ]));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ExpenseCard(expense: filtered[i], isDark: isDark, categoryColor: _categoryColor(filtered[i].category)),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Expense Card ───────────────────────────────────────────────────────────

class _ExpenseCard extends ConsumerWidget {
  final Expense expense;
  final bool isDark;
  final Color categoryColor;
  const _ExpenseCard({required this.expense, required this.isDark, required this.categoryColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return GestureDetector(
      onTap: () => context.push(AppRouter.expenseDetail, extra: expense),
      child: Container(
        decoration: BoxDecoration(color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Row(children: [
            Container(width: 3, color: categoryColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(expense.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: categoryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(expense.category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: categoryColor))),
                      const SizedBox(width: 10),
                      Icon(Icons.calendar_today_outlined, size: 11, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(DateFormat('dd MMM yyyy').format(expense.expenseDate), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    ]),
                  ])),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('₹${fmt.format(expense.amount)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accentRose)),
                    if (expense.paymentMethod != null) ...[
                      const SizedBox(height: 4),
                      Text(expense.paymentMethod!, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ]),
                  PopupMenuButton<String>(
                    onSelected: (v) => _onAction(context, ref, v),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: cs.onSurfaceVariant),
                    itemBuilder: (_) => [
                      _item(context, 'view', 'View', Icons.visibility_outlined, cs.onSurface),
                      _item(context, 'edit', 'Edit', Icons.edit_outlined, AppColors.accentIndigo),
                      _item(context, 'delete', 'Delete', Icons.delete_outline_rounded, AppColors.accentRose),
                    ],
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(BuildContext context, String value, String label, IconData icon, Color color) =>
      PopupMenuItem(value: value, child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 10), Text(label, style: TextStyle(fontSize: 13, color: color))]));

  void _onAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'view':   context.push(AppRouter.expenseDetail, extra: expense);
      case 'edit':   context.push(AppRouter.createExpense, extra: expense);
      case 'delete': _confirmDelete(context, ref);
    }
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
          TextButton(onPressed: () { ref.read(expensesProvider.notifier).deleteExpense(expense.id); Navigator.pop(context); }, child: Text('Delete', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
