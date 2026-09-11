import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/detail_sheet.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/super_admin_company_filter_bar.dart';
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

  // Cards cycle through accent colors by list position — same pattern as
  // every other module — so two consecutive cards never land on the same
  // (or a near-identical) color, regardless of which category they belong to.
  static List<Color> get _cardColors => [AppColors.brand, AppColors.positive, AppColors.brandLight, AppColors.brandBlack];

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
                    boxShadow: AppColors.shadows([
                      BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4)),
                      BoxShadow(color: AppColors.highlightShadow(0.8), blurRadius: 4, offset: const Offset(-2, -2)),
                    ]),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
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
                      boxShadow: AppColors.shadows([
                        BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4)),
                        BoxShadow(color: AppColors.highlightShadow(0.8), blurRadius: 4, offset: const Offset(-2, -2)),
                      ]),
                    ),
                    child: Icon(Icons.menu_rounded, size: 18, color: AppColors.ink),
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
                boxShadow: AppColors.shadows([BoxShadow(color: AppColors.brand.withValues(alpha: isDark ? 0.0 : 0.4), blurRadius: 10, offset: const Offset(0, 4))]),
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
                      BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
                      BoxShadow(color: AppColors.highlightShadow(0.85), blurRadius: 6, offset: const Offset(-3, -3)),
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
        const SuperAdminCompanyFilterBar(),
        Expanded(
          child: expensesAsync.when(
            loading: () => const SkeletonListView(),
            error: (e, _) => ErrorCard(
              error: e,
              onRetry: () => ref.invalidate(expensesProvider),
            ),
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
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (_, i) => _ExpenseCard(expense: filtered[i], categoryColor: _cardColors[i % _cardColors.length]),
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
    final bg = Color.lerp(AppColors.surface, categoryColor, AppColors.cardTintBlend(categoryColor))!;
    final fg = AppColors.ink;
    final fgMuted = AppColors.ink.withValues(alpha: 0.6);
    final dividerColor = AppColors.ink.withValues(alpha: 0.12);

    return SwipeActions(
      onTap: () => _showExpenseDetail(context, ref, expense, categoryColor),
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
          color: AppColors.brandBlack,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(expense.title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg, height: 1.25)),
                ),
                const SizedBox(width: 16),
                Text('₹${fmt.format(expense.amount)}',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: fg)),
              ],
            ),
            const SizedBox(height: 14),
            RichCardDivider(color: dividerColor),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_rounded, size: 12, color: fgMuted),
                const SizedBox(width: 4),
                Text(DateFormat('dd MMM yyyy').format(expense.expenseDate), style: TextStyle(fontSize: 12, color: fgMuted)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: categoryColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(expense.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.white)),
                ),
              ],
            ),
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
                await ref.read(expensesProvider.notifier).deleteExpense(
                      expense.id,
                      companyId: Session.isSuperAdmin ? expense.companyId : null,
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dangerFill),
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

void _showExpenseDetail(BuildContext context, WidgetRef ref, Expense expense, Color categoryColor) {
  final fmt = NumberFormat('#,##,##0.00', 'en_IN');
  showDetailSheet(context, (ctx) => DetailSheetScaffold(
    showAvatar: false,
    title: expense.title,
    subtitle: expense.category,
    onEdit: () {
      Navigator.of(ctx).pop();
      ctx.push(AppRouter.createExpense, extra: expense);
    },
    onDelete: () async {
      final confirmed = await showDialog<bool>(
        context: ctx,
        builder: (dCtx) => AlertDialog(
          backgroundColor: Theme.of(dCtx).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
          content: Text('Delete "${expense.title}"? This cannot be undone.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
            TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: Text('Delete', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700))),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        await ref.read(expensesProvider.notifier).deleteExpense(
                      expense.id,
                      companyId: Session.isSuperAdmin ? expense.companyId : null,
                    );
        if (ctx.mounted) Navigator.of(ctx).pop();
      } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dangerFill));
        }
      }
    },
    statusRow: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: categoryColor, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.currency_rupee_rounded, color: AppColors.white, size: 18),
        const SizedBox(width: 8),
        const Text('Amount', style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        const Spacer(),
        Text('₹${fmt.format(expense.amount)}', style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      ]),
    ),
    sections: [
      DetailSection(title: 'Details', items: [
        DetailRow(icon: Icons.calendar_today_rounded, label: 'Date', value: DateFormat('dd MMM yyyy').format(expense.expenseDate)),
        if (expense.paymentMethod != null) DetailRow(icon: Icons.payments_outlined, label: 'Payment Method', value: expense.paymentMethod!, iconColor: AppColors.positive),
        if (expense.unit != null) DetailRow(icon: Icons.straighten_rounded, label: 'Unit', value: expense.unit!),
      ]),
      if (expense.notes != null && expense.notes!.isNotEmpty)
        DetailSection(title: 'Notes', items: [
          DetailRow(icon: Icons.notes_rounded, label: 'Notes', value: expense.notes!),
        ]),
    ],
  ));
}
