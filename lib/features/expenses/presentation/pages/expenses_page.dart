import 'dart:async';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/list_filter_options_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/detail_sheet.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/picked_image.dart';
import '../../../../shared/widgets/image_viewer.dart';
import '../../../../shared/widgets/super_admin_company_filter_bar.dart';
import '../../data/repositories/expenses_repository_impl.dart';
import '../../domain/entities/expense.dart';
import '../../../../shared/widgets/chip_filter_sheet.dart';
import '../../../../shared/widgets/search_field.dart';
import '../providers/expenses_provider.dart';
import '../../../../shared/widgets/list_count_bar.dart';
import '../../../../shared/widgets/module_title.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  final bool fromMasters;
  const ExpensesPage({super.key, this.fromMasters = false});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Cards cycle through accent colors by list position — same pattern as
  // every other module — so two consecutive cards never land on the same
  // (or a near-identical) color, regardless of which category they belong to.
  static List<Color> get _cardColors => [
    AppColors.brand,
    AppColors.positive,
    AppColors.brandLight,
    AppColors.brandBlack,
  ];

  // Filter sheet choices (null = All) and the search text — both go to the
  // API (see expenseResultsProvider).
  Map<String, Object?> _filters = {};
  String _search = '';
  Timer? _debounce;

  /// Search + filters as API params, as a stable query string (the results
  /// provider's key). '' = neither → the full list. "days" → from/to.
  String _query() {
    final days = _filters['days'] as int?;
    final now = DateTime.now();
    final day = DateFormat('yyyy-MM-dd');
    final p = <String, String>{
      if (_search.isNotEmpty) 'search': _search,
      for (final e in _filters.entries)
        if (e.key != 'days' && e.value != null) e.key: '${e.value}',
      if (days != null) ...{
        'from': day.format(now.subtract(Duration(days: days - 1))),
        'to': day.format(now),
      },
    };
    final keys = p.keys.toList()..sort();
    return Uri(queryParameters: {for (final k in keys) k: p[k]!}).query;
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _search = v.trim());
    });
  }

  void _openFilter(List<Expense> all) {
    final server =
        ref
            .read(listFilterOptionsProvider(ApiEndpoints.expenses))
            .valueOrNull ??
        const {};
    List<(Object, String)> opts(String key, List<(Object, String)> fallback) {
      final o = serverOptions(server, key);
      return o.isEmpty ? fallback : o;
    }

    showChipFilterSheet(
      context,
      title: 'Filter expenses',
      sections: [
        FilterSection(
          key: 'category_id',
          title: 'Category',
          options: opts('categories', [
            for (final c in {
              for (final e in all)
                if (e.categoryId.isNotEmpty) e.categoryId: e.category,
            }.entries)
              (c.key, c.value),
          ]),
        ),
        FilterSection(
          key: 'payment_method',
          title: 'Payment method',
          options: opts(
            'payment_method',
            distinctOptions(all, (e) => e.paymentMethod),
          ),
        ),
        FilterSection(
          key: 'days',
          title: 'Date',
          options: const [(7, 'Last 7 days'), (30, 'Last 30 days')],
        ),
      ],
      selected: _filters,
      onApply: (v) => setState(() => _filters = v),
      onClear: () => setState(() => _filters = {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _query();
    final expensesAsync = query.isEmpty
        ? ref.watch(expensesProvider)
        : ref.watch(expenseResultsProvider(query));
    // Loads the filter choices ahead of the sheet opening.
    ref.watch(listFilterOptionsProvider(ApiEndpoints.expenses));

    return Scaffold(
      extendBody: true,
      drawer: widget.fromMasters ? null : const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(activeIndex: 3),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).dividerColor),
        ),
        leading: widget.fromMasters
            ? GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? cs.surfaceContainerHighest
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.shadows([
                      BoxShadow(
                        color: AppColors.shadowDark.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: AppColors.highlightShadow(0.8),
                        blurRadius: 4,
                        offset: const Offset(-2, -2),
                      ),
                    ]),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppColors.ink,
                  ),
                ),
              )
            : Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.surfaceContainerHighest
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.shadows([
                        BoxShadow(
                          color: AppColors.shadowDark.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: AppColors.highlightShadow(0.8),
                          blurRadius: 4,
                          offset: const Offset(-2, -2),
                        ),
                      ]),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
        title: widget.fromMasters
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Menu',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Masters',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    Text(
                      'Expenses',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : ModuleTitle(title: 'Expenses', subtitle: 'Track your spending'),
        actions: [
          if (ref.watch(moduleAccessProvider('Expenses')).create)
            GestureDetector(
              onTap: () => context.push(
                AppRouter.createExpense,
                extra: widget.fromMasters ? 'masters' : null,
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 8, 16, 8),
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.silverGradient
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.brand, AppColors.brandDeep],
                        ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: AppColors.shadows([
                    BoxShadow(
                      color: AppColors.brand.withValues(
                        alpha: isDark ? 0.0 : 0.4,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: isDark ? AppColors.black : AppColors.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          SearchFilterBar(
            controller: _searchCtrl,
            hintText: 'Search',
            onChanged: _onSearch,
            filterActive: _filters.values.any((v) => v != null),
            onFilter: () => _openFilter(expensesAsync.valueOrNull ?? const []),
          ),
          const SuperAdminCompanyFilterBar(),
          Expanded(
            child: expensesAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(expensesProvider),
              ),
              data: (all) {
                final filtered = all;
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          size: 56,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.isEmpty ? 'No expenses yet' : 'No results',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (query.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to log your first expense',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    ListCountBar(
                      label: 'Total Expenses',
                      count: filtered.length,
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 18),
                        itemBuilder: (_, i) => _ExpenseCard(
                          expense: filtered[i],
                          categoryColor: _cardColors[i % _cardColors.length],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
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
    final bg = Color.lerp(
      AppColors.surface,
      categoryColor,
      AppColors.cardTintBlend(categoryColor),
    )!;
    final fg = AppColors.ink;
    final fgMuted = AppColors.ink.withValues(alpha: 0.6);
    // "₹1,750" — paise only when there are some.
    final amount = expense.amount % 1 == 0
        ? '₹${NumberFormat('#,##,##0', 'en_IN').format(expense.amount)}'
        : '₹${fmt.format(expense.amount)}';
    final meta = [
      DateFormat('d MMM yyyy').format(expense.expenseDate),
      if (expense.paymentMethod?.isNotEmpty == true) expense.paymentMethod!,
    ].join(' · ');

    return SwipeActions(
      onTap: () => _showExpenseDetail(context, ref, expense, categoryColor),
      actions: [
        if (ref.watch(moduleAccessProvider('Expenses')).edit)
          SwipeAction(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: AppColors.accentIndigo,
            onTap: () => context.push(AppRouter.createExpense, extra: expense),
          ),
        if (ref.watch(moduleAccessProvider('Expenses')).delete)
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
        // Compact: icon · title / date · method / category chip · amount pill.
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.accentGradient(categoryColor),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  // A receipt photo is attached.
                  if (expense.receiptImagePath?.isNotEmpty == true)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.positive,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.photo_rounded,
                          size: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: fgMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: fgMuted),
                          ),
                        ),
                      ],
                    ),
                    if (expense.category.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          expense.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // The amount is what you look for — a solid pill.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brand, AppColors.brandDeep],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.shadows([
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]),
                ),
                child: Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
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
        title: Text(
          'Delete Expense',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        content: Text(
          'Delete "${expense.title}"? This cannot be undone.',
          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(expensesProvider.notifier)
                    .deleteExpense(
                      expense.id,
                      companyId: Session.isSuperAdmin
                          ? expense.companyId
                          : null,
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.dangerFill,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showExpenseDetail(
  BuildContext context,
  WidgetRef ref,
  Expense expense,
  Color categoryColor,
) {
  final fmt = NumberFormat('#,##,##0.00', 'en_IN');
  showDetailSheet(
    context,
    (ctx) => DetailSheetScaffold(
      showAvatar: false,
      title: expense.title,
      subtitle: expense.category,
      onEdit: !ref.read(moduleAccessProvider('Expenses')).edit
          ? null
          : () {
              Navigator.of(ctx).pop();
              ctx.push(AppRouter.createExpense, extra: expense);
            },
      onDelete: !ref.read(moduleAccessProvider('Expenses')).delete
          ? null
          : () async {
              final confirmed = await showDialog<bool>(
                context: ctx,
                builder: (dCtx) => AlertDialog(
                  backgroundColor: Theme.of(dCtx).scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Delete Expense',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  content: Text(
                    'Delete "${expense.title}"? This cannot be undone.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dCtx).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dCtx).pop(true),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              try {
                await ref
                    .read(expensesProvider.notifier)
                    .deleteExpense(
                      expense.id,
                      companyId: Session.isSuperAdmin
                          ? expense.companyId
                          : null,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.dangerFill,
                    ),
                  );
                }
              }
            },
      statusRow: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: categoryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.currency_rupee_rounded,
              color: AppColors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'Amount',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '₹${fmt.format(expense.amount)}',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      sections: [
        DetailSection(
          title: 'Details',
          items: [
            DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: DateFormat('dd MMM yyyy').format(expense.expenseDate),
            ),
            if (expense.paymentMethod != null)
              DetailRow(
                icon: Icons.payments_outlined,
                label: 'Payment Method',
                value: expense.paymentMethod!,
                iconColor: AppColors.positive,
              ),
            if (expense.unit != null)
              DetailRow(
                icon: Icons.straighten_rounded,
                label: 'Unit',
                value: expense.unit!,
              ),
          ],
        ),
        _ExpenseReceiptImage(expense: expense),
        if (expense.notes != null && expense.notes!.isNotEmpty)
          DetailSection(
            title: 'Notes',
            items: [
              DetailRow(
                icon: Icons.notes_rounded,
                label: 'Notes',
                value: expense.notes!,
              ),
            ],
          ),
      ],
    ),
  );
}

/// The expense list response doesn't always carry `receipt_url` (only the
/// single-record `GET /expenses/:id` reliably does) — shows it immediately
/// if the list item already had it, otherwise fetches the full record by id
/// on open, same pattern as sales' `_SaleItemsSection`.
class _ExpenseReceiptImage extends ConsumerStatefulWidget {
  final Expense expense;
  const _ExpenseReceiptImage({required this.expense});

  @override
  ConsumerState<_ExpenseReceiptImage> createState() =>
      _ExpenseReceiptImageState();
}

class _ExpenseReceiptImageState extends ConsumerState<_ExpenseReceiptImage> {
  String? _url;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _url = widget.expense.receiptImagePath;
    if (_url == null || _url!.isEmpty) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final full = await ref
          .read(expensesRepositoryProvider)
          .getExpenseById(widget.expense.id);
      if (!mounted) return;
      setState(() {
        _url = full.receiptImagePath;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final url = _url;
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => showImageViewer(context, [url]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: pickedImage(url, width: double.infinity, height: 180),
      ),
    );
  }
}
