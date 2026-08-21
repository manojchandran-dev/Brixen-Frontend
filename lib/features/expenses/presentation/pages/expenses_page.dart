import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
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

  // Category names come from user-defined Masters data, so colors are
  // assigned by hashing the name into the fixed 5-color brand palette
  // instead of matching fixed keywords — every distinct category gets a
  // consistent color even if the user creates their own category names.
  static const _categoryColors = [AppColors.brand, AppColors.positive, AppColors.brandDeep, AppColors.brandLight, AppColors.ink];
  Color _categoryColor(String cat) => _categoryColors[cat.toLowerCase().hashCode.abs() % _categoryColors.length];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      extendBody: true,
      drawer: widget.fromMasters ? null : const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(activeIndex: 3),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Theme.of(context).dividerColor)),
        leading: widget.fromMasters
            ? GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40, height: 40,
                  margin: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? cs.surfaceContainerHighest : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: AppColors.ink.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4)),
                      BoxShadow(color: AppColors.white.withValues(alpha: 0.8), blurRadius: 4, offset: const Offset(-2, -2)),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
                ),
              )
            : Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    width: 40, height: 40,
                    margin: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? cs.surfaceContainerHighest : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: AppColors.ink.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4)),
                        BoxShadow(color: AppColors.white.withValues(alpha: 0.8), blurRadius: 4, offset: const Offset(-2, -2)),
                      ],
                    ),
                    child: const Icon(Icons.menu_rounded, size: 18, color: AppColors.ink),
                  ),
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
              margin: const EdgeInsets.fromLTRB(0, 8, 16, 8), width: 38, height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.silverGradient
                    : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [BoxShadow(color: AppColors.brand.withValues(alpha: isDark ? 0.0 : 0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(Icons.add_rounded, size: 20, color: isDark ? AppColors.black : AppColors.white),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHighest : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
                      BoxShadow(color: AppColors.white.withValues(alpha: 0.85), blurRadius: 6, offset: const Offset(-3, -3)),
                    ],
            ),
            child: TextField(
              controller: _searchCtrl, onChanged: (_) => setState(() {}),
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by title or category…',
                hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
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
                itemBuilder: (_, i) => _ExpenseCard(expense: filtered[i], categoryColor: _categoryColor(filtered[i].category)),
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
  final Color categoryColor;
  const _ExpenseCard({required this.expense, required this.categoryColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    // Pale opaque blend of this expense's real category colour — keeps the
    // category signal while matching the matte-3D card look used elsewhere.
    final bg = Color.lerp(AppColors.surface, categoryColor, 0.32)!;
    const fg = AppColors.ink;
    final fgMuted = AppColors.ink.withValues(alpha: 0.6);
    final dividerColor = AppColors.ink.withValues(alpha: 0.12);

    return SwipeActions(
      onTap: () => context.push(AppRouter.expenseDetail, extra: expense),
      actions: [
        SwipeAction(
          icon: Icons.edit_outlined,
          label: 'Edit',
          color: AppColors.accentIndigo,
          onTap: () => context.push(AppRouter.createExpense, extra: expense),
        ),
        SwipeAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          color: AppColors.error,
          onTap: () => _confirmDelete(context, ref),
        ),
      ],
      child: RichCardShell(
        accentColor: categoryColor,
        backgroundColor: bg,
        showAccentBar: false,
        edgeColor: categoryColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [categoryColor, categoryColor.withValues(alpha: 0.75)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: categoryColor.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.receipt_rounded, size: 17, color: AppColors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(expense.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: categoryColor, borderRadius: BorderRadius.circular(20)),
                child: Text(expense.category, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.white)),
              ),
              const SizedBox(width: 8),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(Icons.chevron_right_rounded, size: 16, color: fgMuted),
              ),
            ]),
            const SizedBox(height: 14),
            RichCardDivider(color: dividerColor),
            const SizedBox(height: 12),
            StatGrid(
              labelColor: fgMuted,
              valueColor: fg,
              dividerColor: dividerColor,
              items: [
                StatGridItem(label: 'Amount', value: '₹${fmt.format(expense.amount)}', color: AppColors.brandDeep, bold: true),
                StatGridItem(label: 'Payment', value: expense.paymentMethod ?? '—'),
                StatGridItem(label: 'Unit', value: expense.unit ?? '—'),
              ],
            ),
            const SizedBox(height: 12),
            RichCardDivider(color: dividerColor),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.calendar_today_rounded, size: 12, color: fgMuted),
              const SizedBox(width: 4),
              Text(DateFormat('dd MMM yyyy').format(expense.expenseDate), style: TextStyle(fontSize: 12, color: fgMuted)),
            ]),
          ]),
        ),
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.ink),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
