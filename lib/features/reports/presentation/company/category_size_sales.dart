import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/exact_amount.dart';
import 'company_reports_data.dart';

/// Categories with units sold and revenue; tap one to open its sizes, each
/// with units, revenue and a bar against the category's best-selling size.
class CategorySizeList extends StatefulWidget {
  final List<CategorySales> categories;

  /// Whether an open size lists who bought it (off inside one customer's
  /// own breakdown).
  final bool showBuyers;

  /// Sizes straight away, in size order, without category headers — for
  /// one group covering every product.
  final bool flat;
  const CategorySizeList(
    this.categories, {
    super.key,
    this.showBuyers = true,
    this.flat = false,
  });

  @override
  State<CategorySizeList> createState() => _CategorySizeListState();
}

class _CategorySizeListState extends State<CategorySizeList> {
  /// Open categories, by name. The top one starts open.
  late final Set<String> _open = {
    if (widget.categories.isNotEmpty) widget.categories.first.name,
  };

  @override
  Widget build(BuildContext context) {
    final cats = widget.categories;
    if (cats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'Nothing sold in this period',
          style: TextStyle(color: AppColors.textHint, fontSize: 13),
        ),
      );
    }
    if (widget.flat) {
      return Column(
        children: [
          for (final c in cats)
            for (final s in c.sizesInOrder)
              _SizeRow(
                category: c,
                size: s,
                fraction: c.sizes.first.quantity == 0
                    ? 0
                    : s.quantity / c.sizes.first.quantity,
                showBuyers: widget.showBuyers,
              ),
        ],
      );
    }
    final total = cats.fold<int>(0, (a, c) => a + c.quantity);
    return Column(
      children: [
        for (final c in cats)
          _CategoryTile(
            category: c,
            share: total == 0 ? 0 : c.quantity / total,
            open: _open.contains(c.name),
            showBuyers: widget.showBuyers,
            onTap: () => setState(
              () => _open.contains(c.name)
                  ? _open.remove(c.name)
                  : _open.add(c.name),
            ),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategorySales category;

  /// Fraction of all units sold in the period.
  final double share;
  final bool open;
  final bool showBuyers;
  final VoidCallback onTap;
  const _CategoryTile({
    required this.category,
    required this.share,
    required this.open,
    required this.showBuyers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = category;
    final sizes = c.sizes;
    final best = sizes.isEmpty ? 1 : sizes.first.quantity;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.category_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${c.quantity} sold · ${(share * 100).round()}% of units'
                          ' · ${sizes.length} size${sizes.length == 1 ? '' : 's'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ExactAmount(
                    amount: c.amount,
                    child: Text(
                      rupees(c.amount),
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (final s in sizes)
                    _SizeRow(
                      category: c,
                      size: s,
                      fraction: s.quantity / best,
                      showBuyers: showBuyers,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One size: units, revenue and a bar; tap to see who bought it and which
/// products, each with units and revenue.
class _SizeRow extends StatefulWidget {
  final CategorySales category;
  final Tally size;

  /// Units against the category's best-selling size, for the bar.
  final double fraction;
  final bool showBuyers;
  const _SizeRow({
    required this.category,
    required this.size,
    required this.fraction,
    required this.showBuyers,
  });

  @override
  State<_SizeRow> createState() => _SizeRowState();
}

class _SizeRowState extends State<_SizeRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final fraction = widget.fraction;
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _open = !_open),
          child: _row(size, fraction),
        ),
        if (_open)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 6, left: 4),
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showBuyers)
                  _Group(
                    title: 'Bought by',
                    icon: Icons.person_rounded,
                    rows: widget.category.buyersOf(size.label),
                  ),
                _Group(
                  title: 'Products',
                  icon: Icons.checkroom_rounded,
                  rows: widget.category.productsOf(size.label),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _row(Tally size, double fraction) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              size.label,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction.clamp(0, 1).toDouble(),
                minHeight: 8,
                color: AppColors.positive,
                backgroundColor: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Text(
              '${size.quantity} sold',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: ExactAmount(
              amount: size.amount,
              child: Text(
                rupees(size.amount),
                textAlign: TextAlign.right,
                style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
              ),
            ),
          ),
          Icon(
            _open
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }
}

/// "Bought by" / "Products" under an open size: name (and shop), units,
/// revenue.
class _Group extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Tally> rows;
  const _Group({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        for (final t in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(icon, size: 14, color: AppColors.brand),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: t.label,
                      children: [
                        if (t.sub.isNotEmpty)
                          TextSpan(
                            text: ' · ${t.sub}',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${t.quantity} sold',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                ExactAmount(
                  amount: t.amount,
                  child: Text(
                    rupees(t.amount),
                    style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
