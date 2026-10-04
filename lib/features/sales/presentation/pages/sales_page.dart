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
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/entities/sale.dart';
import '../../../../shared/widgets/chip_filter_sheet.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../domain/entities/sale_item.dart';
import '../providers/sales_provider.dart';
import '../../../../shared/widgets/list_count_bar.dart';
import '../../../../shared/widgets/module_title.dart';

class SalesPage extends ConsumerStatefulWidget {
  final bool fromMasters;
  const SalesPage({super.key, this.fromMasters = false});

  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends ConsumerState<SalesPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Filter sheet choices (null = All) and the search text — both go to the
  // API (see saleResultsProvider).
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

  void _openFilter(List<Sale> all) {
    final server =
        ref.read(listFilterOptionsProvider(ApiEndpoints.sales)).valueOrNull ??
        const {};
    List<(Object, String)> opts(String key, List<(Object, String)> fallback) {
      final o = serverOptions(server, key);
      return o.isEmpty ? fallback : o;
    }

    showChipFilterSheet(
      context,
      title: 'Filter sales',
      sections: [
        FilterSection(
          key: 'payment_status',
          title: 'Payment status',
          options: opts(
            'payment_status',
            distinctOptions(all, (e) => e.paymentStatus),
          ),
        ),
        FilterSection(
          key: 'payment_type',
          title: 'Payment type',
          options: opts(
            'payment_type',
            distinctOptions(all, (e) => e.paymentType),
          ),
        ),
        FilterSection(
          key: 'invoice_type',
          title: 'Invoice type',
          options: opts(
            'invoice_type',
            distinctOptions(all, (e) => e.invoiceType),
          ),
        ),
        FilterSection(
          key: 'days',
          title: 'Bill date',
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
    final salesAsync = query.isEmpty
        ? ref.watch(salesProvider)
        : ref.watch(saleResultsProvider(query));
    // Loads the filter choices ahead of the sheet opening.
    ref.watch(listFilterOptionsProvider(ApiEndpoints.sales));

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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      'Sales',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : ModuleTitle(title: 'Sales', subtitle: 'Invoices and sales'),
        actions: [
          if (ref.watch(moduleAccessProvider('Sales')).create)
            GestureDetector(
              onTap: () => context.push(
                AppRouter.createSale,
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
          // Search bar
          SearchFilterBar(
            controller: _searchCtrl,
            hintText: 'Search',
            onChanged: _onSearch,
            filterActive: _filters.values.any((v) => v != null),
            onFilter: () => _openFilter(salesAsync.valueOrNull ?? const []),
          ),
          const SuperAdminCompanyFilterBar(),

          // List
          Expanded(
            child: salesAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(salesProvider),
              ),
              data: (all) {
                final filtered = all;

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.isEmpty ? 'No sales yet' : 'No results',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (query.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to create your first sale',
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
                    ListCountBar(label: 'Total Sales', count: filtered.length),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _SaleCard(sale: filtered[i], index: i),
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

class _SaleCard extends ConsumerWidget {
  final Sale sale;
  final int index;

  const _SaleCard({required this.sale, this.index = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(sale.paymentStatus);
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final title = sale.customerName ?? sale.invoiceType ?? 'Sale';

    // Cards cycle through the 5-colour rotation as a pale tinted background
    // (opaque blend, not translucent, so the swipe buttons underneath stay
    // hidden until the card is actually swiped) plus a thin left accent bar.
    final accentColors = [
      AppColors.brand,
      AppColors.positive,
      AppColors.brandDeep,
      AppColors.brandLight,
      AppColors.brandBlack,
    ];
    final accent = accentColors[index % accentColors.length];

    final fg = AppColors.ink;
    final fgMuted = AppColors.ink.withValues(alpha: 0.6);
    // "₹9,450" — paise only when there are some.
    String money(double v) => v % 1 == 0
        ? '₹${NumberFormat('#,##,##0', 'en_IN').format(v)}'
        : '₹${fmt.format(v)}';
    final meta = [
      DateFormat('d MMM yyyy').format(sale.billDate),
      if (sale.paymentType?.isNotEmpty == true) sale.paymentType!,
    ].join(' · ');

    return SwipeActions(
      onTap: () => _showSaleDetail(context, ref, sale, accent),
      actions: [
        if (ref.watch(moduleAccessProvider('Sales')).edit)
          SwipeAction(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: AppColors.accentIndigo,
            onTap: () => context.push(
              AppRouter.createSale,
              extra: {'sale': sale, 'fromMasters': false, 'fromMenu': false},
            ),
          ),
        if (ref.watch(moduleAccessProvider('Sales')).delete)
          SwipeAction(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: AppColors.brandBlack,
            onTap: () => _confirmDelete(context, ref),
          ),
      ],
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: accent.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(2, 6),
            ),
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.highlightShadow(0.85),
              blurRadius: 8,
              offset: const Offset(-4, -4),
            ),
          ]),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.cardTintGradient(accent),
                  ),
                ),
                // Compact: avatar · customer / date · method / status · total pill.
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.accentGradient(accent),
                        ),
                        shape: BoxShape.circle,
                        boxShadow: AppColors.shadows([
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]),
                      ),
                      child: Text(
                        title.trim().isNotEmpty
                            ? title.trim()[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
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
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: fgMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _StatusChip(
                                status: sale.paymentStatus,
                                color: statusColor,
                              ),
                              // Partial: what's still owed.
                              if (sale.balance > 0 &&
                                  sale.paymentStatus.toLowerCase() == 'partial')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withValues(
                                      alpha: 0.7,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${money(sale.balance)} due',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: fg,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // The total is what you look for — a solid pill.
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
                        money(sale.totalAmount),
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
              Positioned.fill(
                child: CustomPaint(
                  painter: GradientEdgePainter(
                    radius: 18,
                    strokeWidth: 3,
                    colors: AppColors.accentGradient(accent),
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
          'Delete Sale',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        content: Text(
          'Delete this sale? This cannot be undone.',
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
                    .read(salesProvider.notifier)
                    .deleteSale(
                      sale.id,
                      companyId: Session.isSuperAdmin ? sale.companyId : null,
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

  Color _statusColor(String status) => _saleStatusColor(status);
}

Color _saleStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return AppColors.accentEmerald;
    case 'pending':
      return AppColors.accentGold;
    case 'partial':
      return AppColors.accentIndigo;
    case 'cancelled':
      return AppColors.accentRose;
    default:
      return AppColors.accentSlate;
  }
}

void _showSaleDetail(
  BuildContext context,
  WidgetRef ref,
  Sale sale,
  Color accent,
) {
  final fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final statusColor = _saleStatusColor(sale.paymentStatus);
  final title = sale.customerName ?? sale.invoiceType ?? 'Sale';

  showDetailSheet(
    context,
    (ctx) => DetailSheetScaffold(
      avatarText: title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : '?',
      avatarGradient: AppColors.accentGradient(accent),
      title: title,
      subtitle: sale.invoiceType,
      onEdit: !ref.read(moduleAccessProvider('Sales')).edit
          ? null
          : () {
              Navigator.of(ctx).pop();
              ctx.push(
                AppRouter.createSale,
                extra: {'sale': sale, 'fromMasters': false, 'fromMenu': false},
              );
            },
      onDelete: !ref.read(moduleAccessProvider('Sales')).delete
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
                    'Delete Sale',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  content: Text(
                    'Delete this sale? This cannot be undone.',
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
                    .read(salesProvider.notifier)
                    .deleteSale(
                      sale.id,
                      companyId: Session.isSuperAdmin ? sale.companyId : null,
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
          color: statusColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              sale.paymentStatus,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '₹${fmt.format(sale.totalAmount)}',
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
          title: 'Invoice',
          items: [
            DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Bill Date',
              value: DateFormat('dd MMM yyyy').format(sale.billDate),
            ),
            if (sale.invoiceType != null)
              DetailRow(
                icon: Icons.description_outlined,
                label: 'Type',
                value: sale.invoiceType!,
                iconColor: AppColors.positive,
              ),
            if (sale.paymentType != null)
              DetailRow(
                icon: Icons.payments_outlined,
                label: 'Payment Method',
                value: sale.paymentType!,
              ),
          ],
        ),
        _SaleBillImage(sale: sale),
        _SaleItemsSection(sale: sale),
        DetailSection(
          title: 'Amount',
          items: [
            DetailRow(
              icon: Icons.receipt_outlined,
              label: 'Subtotal',
              value: '₹${fmt.format(sale.subtotal)}',
            ),
            DetailRow(
              icon: Icons.percent_rounded,
              label: 'Tax',
              value: '₹${fmt.format(sale.taxAmount)}',
              iconColor: AppColors.positive,
            ),
            DetailRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total',
              value: '₹${fmt.format(sale.totalAmount)}',
            ),
            DetailRow(
              icon: Icons.payments_outlined,
              label: 'Paid',
              value: '₹${fmt.format(sale.totalAmount - sale.balance)}',
              iconColor: AppColors.positive,
            ),
            if (sale.balance > 0)
              DetailRow(
                icon: Icons.pending_actions_rounded,
                label: 'Balance due',
                value: '₹${fmt.format(sale.balance)}',
              ),
          ],
        ),
        if (sale.notes != null && sale.notes!.isNotEmpty)
          DetailSection(
            title: 'Notes',
            items: [
              DetailRow(
                icon: Icons.notes_rounded,
                label: 'Notes',
                value: sale.notes!,
              ),
            ],
          ),
      ],
    ),
  );
}

/// The sale list response doesn't always carry `bill_image_path` (only the
/// single-record `GET /sales/:id` reliably does) — shows it immediately if
/// the list item already had it, otherwise fetches the full record by id
/// on open, same pattern as [_SaleItemsSection] below.
class _SaleBillImage extends ConsumerStatefulWidget {
  final Sale sale;
  const _SaleBillImage({required this.sale});

  @override
  ConsumerState<_SaleBillImage> createState() => _SaleBillImageState();
}

class _SaleBillImageState extends ConsumerState<_SaleBillImage> {
  String? _url;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _url = widget.sale.billImagePath;
    if (_url == null || _url!.isEmpty) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final full = await ref
          .read(salesRepositoryProvider)
          .getSaleById(
            widget.sale.id,
            companyId: Session.isSuperAdmin ? widget.sale.companyId : null,
          );
      if (!mounted) return;
      setState(() {
        _url = full.billImagePath;
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

/// Fetches `GET /sales/:id/items` on open and renders the line items as
/// their own detail section — the sale list/detail payload doesn't carry
/// them, so this is a dedicated on-demand call each time the sheet opens.
class _SaleItemsSection extends ConsumerStatefulWidget {
  final Sale sale;
  const _SaleItemsSection({required this.sale});

  @override
  ConsumerState<_SaleItemsSection> createState() => _SaleItemsSectionState();
}

class _SaleItemsSectionState extends ConsumerState<_SaleItemsSection> {
  bool _loading = true;
  String? _error;
  List<SaleItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ref
          .read(salesRepositoryProvider)
          .getSaleItems(
            widget.sale.id,
            companyId: Session.isSuperAdmin ? widget.sale.companyId : null,
          );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
    if (_error != null) return const SizedBox.shrink();
    if (_items.isEmpty) return const SizedBox.shrink();

    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    return DetailSection(
      title: 'Products',
      items: _items
          .map(
            (it) => DetailRow(
              icon: Icons.checkroom_rounded,
              label:
                  '${it.productName} (${it.priceType == 'wholesale' ? 'Wholesale' : 'Retail'})',
              value:
                  '${it.quantity} × ₹${fmt.format(it.price)} = ₹${fmt.format(it.amount)}',
              iconColor: AppColors.accentIndigo,
            ),
          )
          .toList(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}
