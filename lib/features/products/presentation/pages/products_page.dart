import 'dart:async';
import 'package:intl/intl.dart';
import '../../../../shared/providers/list_filter_options_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/widgets/deleted_items_button.dart';
import 'package:go_router/go_router.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/action_sheet.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/rich_card_shell.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/detail_sheet.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/super_admin_company_filter_bar.dart';
import '../../../../shared/widgets/picked_image.dart';
import '../../../../shared/widgets/image_viewer.dart';
import '../../data/repositories/products_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../../../shared/widgets/chip_filter_sheet.dart';
import '../../../../shared/widgets/search_field.dart';
import '../providers/products_provider.dart';
import '../../../../shared/widgets/list_count_bar.dart';
import '../../../../shared/widgets/module_title.dart';
import '../../../../shared/widgets/module_tabs.dart';

class ProductsPage extends ConsumerStatefulWidget {
  final bool fromMasters;
  const ProductsPage({super.key, this.fromMasters = false});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Filter sheet choices (null = All) and the search text — both go to the
  // API (see productResultsProvider).
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

  void _openFilter(List<Product> all) {
    final server =
        ref
            .read(listFilterOptionsProvider(ApiEndpoints.products))
            .valueOrNull ??
        const {};
    List<(Object, String)> opts(String key, List<(Object, String)> fallback) {
      final o = serverOptions(server, key);
      return o.isEmpty ? fallback : o;
    }

    showChipFilterSheet(
      context,
      title: 'Filter products',
      sections: [
        FilterSection(
          key: 'category_id',
          title: 'Category',
          options: opts('categories', [
            for (final c in {
              for (final e in all)
                if (e.categoryId?.isNotEmpty ?? false)
                  e.categoryId!: e.category,
            }.entries)
              (c.key, c.value),
          ]),
        ),
        FilterSection(
          key: 'status',
          title: 'Status',
          options: opts('status', distinctOptions(all, (e) => e.status)),
        ),
        FilterSection(
          key: 'gender',
          title: 'Gender',
          options: opts('gender', distinctOptions(all, (e) => e.gender)),
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
    final productsAsync = query.isEmpty
        ? ref.watch(productsProvider)
        : ref.watch(productResultsProvider(query));
    // Loads the filter choices ahead of the sheet opening.
    ref.watch(listFilterOptionsProvider(ApiEndpoints.products));

    return Scaffold(
      extendBody: true,
      drawer: widget.fromMasters ? null : const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(activeIndex: 3),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        // One menu entry for the group: its screens as tabs (not when
        // opened from Masters).
        bottom: widget.fromMasters
            ? PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                ),
              )
            : const ModuleTabs(
                group: ModuleGroup.stock,
                current: AppRouter.products,
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
                      'Products',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            : ModuleTitle(title: 'Products', subtitle: 'Your product catalog'),
        actions: [
          // Stock levels, adjustments and history.
          IconButton(
            tooltip: 'Inventory',
            onPressed: () => context.push(AppRouter.inventory),
            icon: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.brand,
            ),
          ),
          if (ref.watch(moduleAccessProvider('Products')).create)
            GestureDetector(
              onTap: () => context.push(
                AppRouter.createProduct,
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
            onFilter: () => _openFilter(productsAsync.valueOrNull ?? const []),
            actions: [
              if (ref.watch(moduleAccessProvider('Products')).delete)
                DeletedItemsButton(
                  title: 'Deleted products',
                  listPath: ApiEndpoints.products,
                  restorePath: (p) =>
                      '${ApiEndpoints.products}/${p['id']}/restore',
                  labelOf: (p) => (p['product_name'] ?? '').toString(),
                  subtitleOf: (p) => p['color'] as String?,
                  onRestored: () => ref.invalidate(productsProvider),
                  inline: true,
                ),
            ],
          ),
          const SuperAdminCompanyFilterBar(),
          Expanded(
            child: productsAsync.when(
              skipError: true,
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(productsProvider),
              ),
              data: (all) {
                final filtered = all;

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.checkroom_rounded,
                          size: 56,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.isEmpty ? 'No products yet' : 'No results',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (query.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to add your first product',
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
                      label: 'Total Products',
                      count: filtered.length,
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        // Pull down to reload.
                        onRefresh: () => ref.refresh(productsProvider.future),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _ProductCard(product: filtered[i], index: i),
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

class _ProductCard extends ConsumerWidget {
  final Product product;
  final int index;
  const _ProductCard({required this.product, this.index = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColors = [
      AppColors.brand,
      AppColors.positive,
      AppColors.brandDeep,
      AppColors.brandLight,
      AppColors.brandBlack,
    ];
    final accent = accentColors[index % accentColors.length];
    final bg = Color.lerp(
      AppColors.surface,
      accent,
      AppColors.cardTintBlend(accent),
    )!;
    final meta = [
      product.category,
      product.gender,
      product.designPattern,
      if (!product.hasVariants) product.color,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');

    return SwipeActions(
      onTap: () => _showProductDetail(context, ref, product, accent),
      actions: [
        if (ref.watch(moduleAccessProvider('Products')).edit)
          SwipeAction(
            icon: Icons.sync_alt_rounded,
            label: 'Status',
            color: AppColors.accentGold,
            onTap: () => _openStatusPicker(context, ref),
          ),
        if (ref.watch(moduleAccessProvider('Products')).edit)
          SwipeAction(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: AppColors.accentIndigo,
            onTap: () => context.push(AppRouter.createProduct, extra: product),
          ),
        if (ref.watch(moduleAccessProvider('Products')).delete)
          SwipeAction(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: AppColors.brandBlack,
            onTap: () => _confirmDelete(context, ref),
          ),
      ],
      // Tinted card in the rotating theme colours, like the other lists.
      child: RichCardShell(
        accentColor: accent,
        backgroundColor: bg,
        backgroundGradient: AppColors.cardTintGradient(accent),
        edgeColor: accent,
        showAccentBar: false,
        // Picture · name & status / category · gender / sizes / price and
        // stock. Cost, unit and the rest are in the detail sheet (tap).
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(product: product, accent: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(status: product.status),
                      ],
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (product.hasVariants) ...[
                      const SizedBox(height: 8),
                      _SizeChips(product: product),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // One line: a price range shrinks to fit
                              // rather than wrapping.
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _priceText(product, wholesale: false),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: AppColors.isDark
                                        ? AppColors.brandLight
                                        : AppColors.brand,
                                  ),
                                ),
                              ),
                              Text(
                                'Wholesale ${_priceText(product, wholesale: true)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StockPill(product: product),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openStatusPicker(BuildContext context, WidgetRef ref) {
    _openProductStatusPicker(context, ref, product);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Product',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        content: Text(
          'Delete "${product.productName}"? This cannot be undone.',
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
                    .read(productsProvider.notifier)
                    .deleteProduct(
                      product.id,
                      companyId: Session.isSuperAdmin
                          ? product.companyId
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

class _Thumb extends StatelessWidget {
  final Product product;
  final Color accent;
  const _Thumb({required this.product, required this.accent});

  @override
  Widget build(BuildContext context) {
    final images = product.galleryPaths;
    final extra = images.length > 1 ? images.length - 1 : 0;
    return SizedBox(
      width: 78,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: images.isEmpty
                ? Container(
                    width: 78,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.accentGradient(accent),
                      ),
                    ),
                    child: const Icon(
                      Icons.checkroom_rounded,
                      size: 26,
                      color: AppColors.white,
                    ),
                  )
                : pickedImage(images.first, width: 78, height: 84),
          ),
          if (extra > 0)
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status.toLowerCase() == 'active';
    final color = active ? AppColors.positive : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? AppColors.positive : AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "12 in stock" · "Low · 3" · "Out of stock".
class _StockPill extends StatelessWidget {
  final Product product;
  const _StockPill({required this.product});

  @override
  Widget build(BuildContext context) {
    final (text, color) = product.isOutOfStock
        ? ('Out of stock', AppColors.error)
        : product.isLowStock
        ? ('Low · ${product.stockQuantity}', AppColors.brandDeep)
        : ('${product.stockQuantity} in stock', AppColors.brand);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: product.isOutOfStock || product.isLowStock ? 0.16 : 0.10,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            product.isOutOfStock || product.isLowStock
                ? Icons.warning_amber_rounded
                : Icons.inventory_2_outlined,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _productStatuses = ['Active', 'Inactive'];

void _openProductStatusPicker(
  BuildContext context,
  WidgetRef ref,
  Product product,
) {
  showActionSheet(
    context,
    title: 'Change Status',
    subtitle: product.productName,
    items: _productStatuses
        .map(
          (s) => ActionSheetItem(
            icon: Icons.circle,
            label: s,
            color: s == 'Active'
                ? AppColors.accentEmerald
                : AppColors.accentRose,
            selected: s == product.status,
            onTap: () async {
              if (s == product.status) return;
              try {
                await ref
                    .read(productsProvider.notifier)
                    .updateProduct(
                      product.copyWith(status: s),
                      companyId: Session.isSuperAdmin
                          ? product.companyId
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
          ),
        )
        .toList(),
  );
}

void _showProductDetail(
  BuildContext context,
  WidgetRef ref,
  Product initial,
  Color accent,
) {
  showDetailSheet(
    context,
    // Follows the live list, so a status/price/stock change made from the
    // sheet (or anywhere) shows here at once instead of after a refresh.
    (ctx) => Consumer(
      builder: (ctx, liveRef, _) {
        final product =
            liveRef
                .watch(productsProvider)
                .valueOrNull
                ?.where((p) => p.id == initial.id)
                .firstOrNull ??
            initial;
        return DetailSheetScaffold(
          avatarIcon: Icons.checkroom_rounded,
          avatarGradient: AppColors.accentGradient(accent),
          title: product.productName,
          subtitle: product.productCode,
          onEdit: !ref.read(moduleAccessProvider('Products')).edit
              ? null
              : () {
                  Navigator.of(ctx).pop();
                  ctx.push(AppRouter.createProduct, extra: product);
                },
          onDelete: !ref.read(moduleAccessProvider('Products')).delete
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
                        'Delete Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      content: Text(
                        'Delete "${product.productName}"? This cannot be undone.',
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
                        .read(productsProvider.notifier)
                        .deleteProduct(
                          product.id,
                          companyId: Session.isSuperAdmin
                              ? product.companyId
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
          statusRow: GestureDetector(
            onTap: !ref.read(moduleAccessProvider('Products')).edit
                ? null
                : () => _openProductStatusPicker(ctx, ref, product),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: product.status == 'Active'
                    ? AppColors.accentEmerald
                    : AppColors.accentRose,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.checkroom_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    product.status,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Tap to change',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.sync_alt_rounded,
                    color: AppColors.white,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
          sections: [
            _ProductGallerySection(product: product),
            DetailSection(
              title: 'Details',
              items: [
                DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: product.category,
                ),
                DetailRow(
                  icon: Icons.wc_rounded,
                  label: 'Gender',
                  value: product.gender,
                  iconColor: AppColors.positive,
                ),
                if (product.designPattern != null &&
                    product.designPattern!.isNotEmpty)
                  DetailRow(
                    icon: Icons.texture_rounded,
                    label: 'Design / Pattern',
                    value: product.designPattern!,
                  ),
                if (product.unit != null)
                  DetailRow(
                    icon: Icons.straighten_rounded,
                    label: 'Unit',
                    value: product.unit!,
                    iconColor: AppColors.positive,
                  ),
                if (product.color != null && product.color!.isNotEmpty)
                  DetailRow(
                    icon: Icons.palette_outlined,
                    label: 'Color',
                    value: product.color!,
                  ),
                if (product.size != null && product.size!.isNotEmpty)
                  DetailRow(
                    icon: Icons.straighten_outlined,
                    label: 'Size',
                    value: product.size!,
                    iconColor: AppColors.positive,
                  ),
              ],
            ),
            if (product.hasVariants)
              DetailSection(
                title: 'Sizes & stock',
                items: [
                  for (final v in product.variants)
                    DetailLineItem(
                      icon: Icons.straighten_rounded,
                      name: v.label,
                      tag: v.sku,
                      working:
                          'Retail ₹${product.retailFor(v).toStringAsFixed(2)} · '
                          'Wholesale ₹${product.wholesaleFor(v).toStringAsFixed(2)}',
                      total: v.stockQuantity > 0
                          ? '${v.stockQuantity} in stock'
                          // Below zero: sold more than was ever stocked.
                          : v.stockQuantity < 0
                          ? 'Out · oversold ${-v.stockQuantity}'
                          : 'Out of stock',
                    ),
                ],
              ),
            DetailSection(
              title: product.hasVariants ? 'Default pricing' : 'Pricing',
              items: [
                DetailRow(
                  icon: Icons.sell_outlined,
                  label: 'Cost Price',
                  value: '₹${product.costPrice.toStringAsFixed(2)}',
                ),
                DetailRow(
                  icon: Icons.storefront_outlined,
                  label: 'Retail Price',
                  value: '₹${product.retailPrice.toStringAsFixed(2)}',
                  iconColor: AppColors.positive,
                ),
                DetailRow(
                  icon: Icons.local_shipping_outlined,
                  label: 'Wholesale Price',
                  value: '₹${product.wholesalePrice.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

/// Fetches `GET /products/:id` on open and shows its gallery — the
/// list-loaded [Product] doesn't carry `gallery_urls`, so this is a
/// dedicated on-demand call each time the detail sheet opens.
class _ProductGallerySection extends ConsumerStatefulWidget {
  final Product product;
  const _ProductGallerySection({required this.product});

  @override
  ConsumerState<_ProductGallerySection> createState() =>
      _ProductGallerySectionState();
}

class _ProductGallerySectionState
    extends ConsumerState<_ProductGallerySection> {
  bool _loading = true;
  List<String> _images = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final full = await ref
          .read(productsRepositoryProvider)
          .getProductById(
            widget.product.id,
            companyId: Session.isSuperAdmin ? widget.product.companyId : null,
          );
      if (!mounted) return;
      setState(() {
        _images = full.galleryPaths;
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
    if (_images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GALLERY',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => showImageViewer(context, _images, initialIndex: i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: pickedImage(_images[i], width: 92, height: 92),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "₹150", or "₹150–₹180" when sizes are priced differently.
String _priceText(Product p, {required bool wholesale}) {
  final prices = p.hasVariants
      ? [
          for (final v in p.variants)
            wholesale ? p.wholesaleFor(v) : p.retailFor(v),
        ]
      : [wholesale ? p.wholesalePrice : p.retailPrice];
  String rs(double v) => '₹${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}';
  final lo = prices.reduce((a, b) => a < b ? a : b);
  final hi = prices.reduce((a, b) => a > b ? a : b);
  return lo == hi ? rs(lo) : '${rs(lo)}–${rs(hi)}';
}

/// A product's sizes as small chips (first few, then "+n"), plus how many
/// colours.
class _SizeChips extends StatelessWidget {
  final Product product;
  const _SizeChips({required this.product});

  static const _shown = 5;

  @override
  Widget build(BuildContext context) {
    final sizes = <String>[];
    final colours = <String>{};
    for (final v in product.variants) {
      final s = v.size?.trim();
      if (s != null && s.isNotEmpty && !sizes.contains(s)) sizes.add(s);
      final c = v.color?.trim();
      if (c != null && c.isNotEmpty) colours.add(c);
    }
    Widget chip(String text, {bool muted = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted ? Colors.transparent : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: muted ? AppColors.textSecondary : AppColors.ink,
        ),
      ),
    );
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final s in sizes.take(_shown)) chip(s),
        if (sizes.length > _shown)
          chip('+${sizes.length - _shown}', muted: true),
        if (colours.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 3),
                Text(
                  colours.length == 1
                      ? colours.first
                      : '${colours.length} colours',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
