import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/module_title.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_widgets.dart';
import '../widgets/stock_entry_sheet.dart';

/// Inventory: Overview · Stock · Movements · Transfers · Reports.
/// Stock is per product — each product is one size/colour variant. Purchases
/// add stock and sales take it automatically; Stock in / out / adjustment
/// cover everything else.
class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  static const _tabs = [
    (Icons.dashboard_rounded, 'Overview'),
    (Icons.inventory_2_rounded, 'Stock'),
    (Icons.swap_vert_rounded, 'Movements'),
    (Icons.local_shipping_rounded, 'Transfers'),
    (Icons.bar_chart_rounded, 'Reports'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          title: const ModuleTitle(
            title: 'Inventory',
            subtitle: 'Stock by product, size and colour',
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brand, AppColors.brandDeep],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                splashBorderRadius: BorderRadius.circular(20),
                tabs: [
                  for (final (icon, label) in _tabs)
                    Tab(
                      height: 38,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16),
                          const SizedBox(width: 6),
                          Text(label),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _StockTab(),
            _MovementsTab(),
            _TransfersTab(),
            _ReportsTab(),
          ],
        ),
      ),
    );
  }
}

/// Loading / error wrapper for tabs that need the stock lines.
class _WithStock extends ConsumerWidget {
  final Widget Function(List<StockLine> lines, StockSummary summary) builder;
  const _WithStock(this.builder);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inventoryProvider);
    final lines = watchStockLines(ref);
    if (lines == null) {
      return async.hasError
          ? ErrorCard(
              error: async.error!,
              onRetry: () => ref.invalidate(inventoryProvider),
            )
          : const SkeletonListView();
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(inventoryProvider.future),
      child: builder(lines, async.value!.summary),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: AppColors.accentGradient(color),
                  ),
                ),
                child: Icon(icon, size: 19, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stock in · Stock out · Adjust buttons.
class _EntryActions extends StatelessWidget {
  const _EntryActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, (mode, label, icon, color)) in const [
          (
            StockEntryMode.stockIn,
            'Stock in',
            Icons.south_west_rounded,
            AppColors.positive,
          ),
          (
            StockEntryMode.stockOut,
            'Stock out',
            Icons.north_east_rounded,
            AppColors.brand,
          ),
          (
            StockEntryMode.adjust,
            'Adjust',
            Icons.tune_rounded,
            AppColors.brandDeep,
          ),
        ].indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              label: label,
              icon: icon,
              color: color,
              onTap: () => showStockEntrySheet(context, mode: mode),
            ),
          ),
        ],
      ],
    );
  }
}

Widget _chips<T>({
  required List<(T, String)> options,
  required T selected,
  required ValueChanged<T> onSelected,
}) => Wrap(
  spacing: 8,
  children: [
    for (final (key, label) in options)
      ChoiceChip(
        label: Text(label),
        selected: selected == key,
        onSelected: (_) => onSelected(key),
        selectedColor: AppColors.brand.withValues(alpha: 0.16),
        labelStyle: TextStyle(
          color: selected == key ? AppColors.brand : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: AppColors.border),
        showCheckmark: false,
      ),
  ],
);

// ── Overview ──────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(moduleAccessProvider('Products')).edit;
    return _WithStock((lines, s) {
      final attention = [
        for (final l in lines)
          if (l.item.status != 'in') l,
      ]..sort((a, b) => a.item.quantity.compareTo(b.item.quantity));
      final recent = ref.watch(stockMovementsProvider(movementsQuery()));
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              InvStatTile(
                'Total stock',
                '${s.units} units',
                Icons.inventory_2_rounded,
                AppColors.brand,
              ),
              InvStatTile(
                'Stock value',
                rupees(s.value),
                Icons.account_balance_wallet_rounded,
                AppColors.positive,
              ),
              InvStatTile(
                'Low stock',
                '${s.low}',
                Icons.trending_down_rounded,
                AppColors.brandDeep,
              ),
              InvStatTile(
                'Out of stock',
                '${s.out}',
                Icons.remove_shopping_cart_rounded,
                AppColors.brandBlack,
              ),
            ],
          ),
          if (canEdit) ...[const SizedBox(height: 14), const _EntryActions()],
          const SizedBox(height: 16),
          InvCard(
            title: 'Needs attention',
            caption: '${attention.length} low or out of stock',
            child: attention.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Everything is well stocked',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  )
                : Column(
                    children: [
                      for (final l in attention.take(5)) ...[
                        StockLineTile(
                          line: l,
                          onTap: canEdit
                              ? () => showStockEntrySheet(
                                  context,
                                  mode: StockEntryMode.stockIn,
                                  line: l,
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          InvCard(
            title: 'Recent movements',
            child: recent.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) =>
                  Text('$e', style: TextStyle(color: AppColors.textSecondary)),
              data: (list) => list.isEmpty
                  ? Text(
                      'No stock changes yet',
                      style: TextStyle(color: AppColors.textHint),
                    )
                  : Column(
                      children: [for (final m in list.take(5)) MovementTile(m)],
                    ),
            ),
          ),
        ],
      );
    });
  }
}

// ── Stock management ──────────────────────────────────────────────────────

class _StockTab extends ConsumerStatefulWidget {
  const _StockTab();

  @override
  ConsumerState<_StockTab> createState() => _StockTabState();
}

class _StockTabState extends ConsumerState<_StockTab> {
  final _search = TextEditingController();
  String? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(moduleAccessProvider('Products')).edit;
    return _WithStock((lines, s) {
      final q = _search.text.trim().toLowerCase();
      final shown = [
        for (final l in lines)
          if ((_status == null || l.item.status == _status) &&
              (q.isEmpty || l.searchText.contains(q)))
            l,
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          SearchField(
            controller: _search,
            hintText: 'Search',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          _chips<String?>(
            options: [
              (null, 'All · ${s.products}'),
              ('in', 'In stock · ${s.inStock}'),
              ('low', 'Low · ${s.low}'),
              ('out', 'Out · ${s.out}'),
            ],
            selected: _status,
            onSelected: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  lines.isEmpty ? 'No products yet' : 'No products match',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            for (final l in shown) ...[
              StockLineTile(
                line: l,
                onTap: canEdit
                    ? () => showStockEntrySheet(
                        context,
                        mode: StockEntryMode.adjust,
                        line: l,
                      )
                    : null,
              ),
              const SizedBox(height: 10),
            ],
        ],
      );
    });
  }
}

// ── Movements (stock in / out / adjustments) ─────────────────────────────

class _MovementsTab extends ConsumerStatefulWidget {
  const _MovementsTab();

  @override
  ConsumerState<_MovementsTab> createState() => _MovementsTabState();
}

class _MovementsTabState extends ConsumerState<_MovementsTab> {
  String? _type; // purchase | sale | adjustment | null = all

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(moduleAccessProvider('Products')).edit;
    final query = movementsQuery(type: _type);
    final async = ref.watch(stockMovementsProvider(query));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(stockMovementsProvider(query).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          if (canEdit) ...[const _EntryActions(), const SizedBox(height: 14)],
          _chips<String?>(
            options: const [
              (null, 'All'),
              ('purchase', 'Purchases'),
              ('sale', 'Sales'),
              ('adjustment', 'Adjustments'),
            ],
            selected: _type,
            onSelected: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 8),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => ErrorCard(
              error: e,
              onRetry: () => ref.invalidate(stockMovementsProvider(query)),
            ),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'No stock changes yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : Column(children: [for (final m in list) MovementTile(m)]),
          ),
        ],
      ),
    );
  }
}

// ── Transfers ─────────────────────────────────────────────────────────────

/// Transfers need stock kept per location, which the backend doesn't have
/// yet (see docs/inventory_api_needs.md) — so this explains instead of
/// showing a form that couldn't save.
class _TransfersTab extends StatelessWidget {
  const _TransfersTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brand.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  size: 30,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Stock transfers are coming',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Moving stock between locations (shop, godown, branch) needs stock '
                'to be tracked per location. Today stock is one number per product '
                'for the whole company.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              for (final t in const [
                'Add your locations',
                'See stock per location',
                'Transfer from → to with a status (pending, in transit, received)',
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: AppColors.positive,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t,
                          style: TextStyle(color: AppColors.ink, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reports ───────────────────────────────────────────────────────────────

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _WithStock((lines, s) {
      // Stock summary by category: (products, units, value).
      final byCategory = <String, (int, int, double)>{};
      for (final l in lines) {
        final c = l.category.isEmpty ? 'Uncategorised' : l.category;
        final (n, units, value) = byCategory[c] ?? (0, 0, 0.0);
        byCategory[c] = (
          n + 1,
          units + (l.item.quantity > 0 ? l.item.quantity : 0),
          value + l.value,
        );
      }
      final cats = byCategory.entries.toList()
        ..sort((a, b) => b.value.$3.compareTo(a.value.$3));
      final lowOut = [
        for (final l in lines)
          if (l.item.status != 'in') l,
      ]..sort((a, b) => a.item.quantity.compareTo(b.item.quantity));
      final valued = [...lines]..sort((a, b) => b.value.compareTo(a.value));
      final now = DateTime.now();
      final moves = ref.watch(
        stockMovementsProvider(
          movementsQuery(from: now.subtract(const Duration(days: 29)), to: now),
        ),
      );

      Widget row(String a, String b, String c, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                a,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                b,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                c,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          InvCard(
            title: 'Stock summary',
            caption: '${s.products} products · ${s.units} units',
            child: Column(
              children: [
                row('Category', 'Units', 'Value', bold: true),
                Divider(color: AppColors.border, height: 12),
                for (final e in cats)
                  row(
                    '${e.key} (${e.value.$1})',
                    '${e.value.$2}',
                    rupees(e.value.$3),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          InvCard(
            title: 'Stock movement',
            caption: 'Last 30 days',
            child: moves.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) =>
                  Text('$e', style: TextStyle(color: AppColors.textSecondary)),
              data: (list) {
                int sum(bool Function(StockMovement) f) =>
                    list.where(f).fold(0, (a, m) => a + m.quantity);
                final bought = sum((m) => m.type == 'purchase');
                final sold = -sum((m) => m.type == 'sale');
                final adjIn = sum(
                  (m) => m.type == 'adjustment' && m.quantity > 0,
                );
                final adjOut = -sum(
                  (m) => m.type == 'adjustment' && m.quantity < 0,
                );
                return Column(
                  children: [
                    row('Stock in · purchases', '', '+$bought'),
                    row('Stock in · adjustments', '', '+$adjIn'),
                    row('Stock out · sales', '', '−$sold'),
                    row('Stock out · adjustments', '', '−$adjOut'),
                    Divider(color: AppColors.border, height: 12),
                    row(
                      'Net change',
                      '${list.length} entries',
                      '${bought + adjIn - sold - adjOut}',
                      bold: true,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          InvCard(
            title: 'Low & out of stock',
            caption: '${lowOut.length} products',
            child: lowOut.isEmpty
                ? Text(
                    'Everything is well stocked',
                    style: TextStyle(color: AppColors.textHint),
                  )
                : Column(
                    children: [
                      for (final l in lowOut)
                        row(
                          [
                            l.name,
                            if (l.size.isNotEmpty) l.size,
                            if (l.color.isNotEmpty) l.color,
                          ].join(' · '),
                          'alert ${l.item.lowStockThreshold}',
                          '${l.item.quantity}',
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          InvCard(
            title: 'Stock valuation',
            caption: 'At cost price · total ${rupees(s.value)}',
            child: Column(
              children: [
                row('Product', 'Qty × cost', 'Value', bold: true),
                Divider(color: AppColors.border, height: 12),
                for (final l in valued.take(20))
                  row(
                    l.name,
                    '${l.item.quantity} × ${rupees(l.unitCost)}',
                    rupees(l.value),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
