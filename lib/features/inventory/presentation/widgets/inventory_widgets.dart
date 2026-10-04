import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../providers/inventory_provider.dart';

/// A product's stock with its catalogue details (SKU, size, colour, cost)
/// — `/inventory` gives the numbers, the Products list the rest.
class StockLine {
  final StockItem item;
  final Product? product;
  const StockLine(this.item, this.product);

  String get name => product?.productName ?? item.name;
  String get sku => product?.productCode ?? '';
  String get size => product?.size ?? '';
  String get color => product?.color ?? '';
  String get category =>
      item.category.isNotEmpty ? item.category : product?.category ?? '';
  double get unitCost => product?.costPrice ?? 0;

  /// Stock value: the server's figure, else quantity × cost.
  double get value => item.value != 0
      ? item.value
      : (item.quantity > 0 ? item.quantity * unitCost : 0);

  String get searchText => '$name $sku $size $color $category'.toLowerCase();
}

/// Stock lines joined with products; null while inventory loads.
List<StockLine>? watchStockLines(WidgetRef ref) {
  final inv = ref.watch(inventoryProvider).valueOrNull;
  if (inv == null) return null;
  final products = {
    for (final p
        in ref.watch(productsProvider).valueOrNull ?? const <Product>[])
      p.id: p,
  };
  return [for (final i in inv.items) StockLine(i, products[i.productId])];
}

(String, Color) stockStatusLook(String status) => switch (status) {
  'out' => ('Out of stock', AppColors.brandBlack),
  'low' => ('Low stock', AppColors.brandDeep),
  _ => ('In stock', AppColors.positive),
};

String reasonLabel(String r) =>
    r.isEmpty ? r : r[0].toUpperCase() + r.substring(1);

/// Tinted stat tile (dashboard, reports).
class InvStatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const InvStatTile(this.label, this.value, this.icon, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.accentGradient(color),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// White section card with a title (and optional trailing action).
class InvCard extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget? trailing;
  final Widget child;
  const InvCard({
    super.key,
    required this.title,
    required this.child,
    this.caption,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (caption != null)
                      Text(
                        caption!,
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Small tinted chip (SKU, size, colour).
class InvChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const InvChip(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One product's stock: qty badge · name / SKU·size·colour chips · status.
class StockLineTile extends StatelessWidget {
  final StockLine line;
  final VoidCallback? onTap;
  const StockLineTile({super.key, required this.line, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (label, color) = stockStatusLook(line.item.status);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${line.item.quantity}',
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    Text('qty', style: TextStyle(color: color, fontSize: 9.5)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (line.sku.isNotEmpty)
                          InvChip(Icons.qr_code_rounded, line.sku),
                        if (line.size.isNotEmpty)
                          InvChip(Icons.straighten_rounded, line.size),
                        if (line.color.isNotEmpty)
                          InvChip(Icons.palette_outlined, line.color),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rupees(line.value),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
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
}

/// One ledger row: in (purchase / + adjustment) or out (sale / − ).
class MovementTile extends StatelessWidget {
  final StockMovement m;
  final bool showProduct;
  const MovementTile(this.m, {super.key, this.showProduct = true});

  @override
  Widget build(BuildContext context) {
    final inbound = m.quantity >= 0;
    final (icon, color, title) = switch (m.type) {
      'purchase' => (
        Icons.south_west_rounded,
        AppColors.positive,
        'Stock in · Purchase',
      ),
      'sale' => (Icons.north_east_rounded, AppColors.brand, 'Stock out · Sale'),
      _ => (
        Icons.tune_rounded,
        AppColors.brandDeep,
        '${inbound ? 'Stock in' : 'Stock out'} · ${reasonLabel(m.reason ?? 'adjustment')}',
      ),
    };
    final sub = [
      if (showProduct && m.productName.isNotEmpty) m.productName,
      DateFormat('d MMM, h:mm a').format(m.at),
      if (m.by?.isNotEmpty == true) m.by!,
      if (m.note?.isNotEmpty == true) m.note!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${inbound ? '+' : ''}${m.quantity}',
                style: TextStyle(
                  color: inbound ? AppColors.positive : AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'bal ${m.balanceAfter}',
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
