import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../data/repositories/products_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../providers/products_provider.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(productsProvider);

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
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Products',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  productsAsync.whenOrNull(
                        data: (list) => Text(
                          '${list.length} records',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ) ??
                      const SizedBox.shrink(),
                ],
              ),
        actions: [
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
                        BoxShadow(
                          color: AppColors.shadowDark.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: AppColors.highlightShadow(0.85),
                          blurRadius: 6,
                          offset: const Offset(-3, -3),
                        ),
                      ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, code or category…',
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SuperAdminCompanyFilterBar(),
          Expanded(
            child: productsAsync.when(
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(productsProvider),
              ),
              data: (list) {
                final q = _searchCtrl.text.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? list
                    : list
                          .where(
                            (p) =>
                                p.productName.toLowerCase().contains(q) ||
                                p.productCode.toLowerCase().contains(q) ||
                                p.category.toLowerCase().contains(q),
                          )
                          .toList();

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
                          list.isEmpty ? 'No products yet' : 'No results',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (list.isEmpty) ...[
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

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _ProductCard(product: filtered[i], index: i),
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

    final fg = AppColors.ink;
    final fgMuted = AppColors.ink.withValues(alpha: 0.55);

    return SwipeActions(
      onTap: () => _showProductDetail(context, ref, product, accent),
      actions: [
        SwipeAction(
          icon: Icons.sync_alt_rounded,
          label: 'Status',
          color: AppColors.accentGold,
          onTap: () => _openStatusPicker(context, ref),
        ),
        SwipeAction(
          icon: Icons.edit_outlined,
          label: 'Edit',
          color: AppColors.accentIndigo,
          onTap: () => context.push(AppRouter.createProduct, extra: product),
        ),
        SwipeAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          color: AppColors.brandBlack,
          onTap: () => _confirmDelete(context, ref),
        ),
      ],
      child: RichCardShell(
        accentColor: accent,
        backgroundColor: bg,
        backgroundGradient: AppColors.cardTintGradient(accent),
        edgeColor: accent,
        showAccentBar: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumb(product: product, accent: accent),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: fg,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Attributes',
                          style: TextStyle(fontSize: 9, color: fgMuted),
                        ),
                        Text(
                          [product.gender, product.designPattern, product.color]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(' · '),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _MiniLabelValue(
                              label: 'Unit',
                              value: product.unit ?? '—',
                              fgMuted: fgMuted,
                              fg: fg,
                            ),
                            const SizedBox(width: 18),
                            _MiniLabelValue(
                              label: 'Category',
                              value: product.category.isEmpty ? '—' : product.category,
                              fgMuted: fgMuted,
                              fg: fg,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${product.retailPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
                      Text(
                        'Retail Price',
                        style: TextStyle(fontSize: 10, color: fgMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: _StatBlock(
                      icon: Icons.currency_rupee_rounded,
                      amount: '₹${product.costPrice.toStringAsFixed(0)}',
                      label: 'Cost',
                      color: AppColors.positive,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatBlock(
                      icon: Icons.local_offer_outlined,
                      amount: '₹${product.wholesalePrice.toStringAsFixed(0)}',
                      label: 'Wholesale',
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatBlock(
                      icon: Icons.shopping_cart_outlined,
                      amount: '₹${product.retailPrice.toStringAsFixed(0)}',
                      label: 'Retail',
                      color: AppColors.brandBlack,
                    ),
                  ),
                ],
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
                      companyId: Session.isSuperAdmin ? product.companyId : null,
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
                color: AppColors.accentRose,
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
      width: 92,
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: images.isEmpty
                ? Container(
                    width: 92,
                    height: 108,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.accentGradient(accent),
                      ),
                    ),
                    child: const Icon(Icons.checkroom_rounded, size: 30, color: AppColors.white),
                  )
                : pickedImage(images.first, width: 92, height: 108),
          ),
          Positioned(top: 6, left: 6, child: _StatusPill(status: product.status)),
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
                child: Text('+$extra',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
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
    final active = status == 'Active';
    final color = active ? AppColors.positive : AppColors.brandBlack;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.accentGradient(color)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLabelValue extends StatelessWidget {
  final String label;
  final String value;
  final Color fgMuted;
  final Color fg;
  const _MiniLabelValue({
    required this.label,
    required this.value,
    required this.fgMuted,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: fgMuted)),
        Text(
          value,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final IconData icon;
  final String amount;
  final String label;
  final Color color;
  const _StatBlock({
    required this.icon,
    required this.amount,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: AppColors.white),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amount,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 9, color: AppColors.ink.withValues(alpha: 0.6)),
                  maxLines: 2,
                  softWrap: true,
                ),
              ],
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
                      companyId: Session.isSuperAdmin ? product.companyId : null,
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
  Product product,
  Color accent,
) {
  showDetailSheet(
    context,
    (ctx) => DetailSheetScaffold(
      avatarIcon: Icons.checkroom_rounded,
      avatarGradient: AppColors.accentGradient(accent),
      title: product.productName,
      subtitle: product.productCode,
      onEdit: () {
        Navigator.of(ctx).pop();
        ctx.push(AppRouter.createProduct, extra: product);
      },
      onDelete: () async {
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
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
          await ref.read(productsProvider.notifier).deleteProduct(
                product.id,
                companyId: Session.isSuperAdmin ? product.companyId : null,
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
        onTap: () => _openProductStatusPicker(ctx, ref, product),
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
        DetailSection(
          title: 'Pricing',
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
  ConsumerState<_ProductGallerySection> createState() => _ProductGallerySectionState();
}

class _ProductGallerySectionState extends ConsumerState<_ProductGallerySection> {
  bool _loading = true;
  List<String> _images = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final full = await ref.read(productsRepositoryProvider).getProductById(
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
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    if (_images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GALLERY',
            style: TextStyle(
                color: AppColors.textHint,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: pickedImage(_images[i], width: 92, height: 92),
            ),
          ),
        ),
      ],
    );
  }
}
