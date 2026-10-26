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
  const CategorySizeList(this.categories, {super.key, this.showBuyers = true});

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

/// A customer's buying in the period: spend, invoices, units, then what
/// they bought by category and size.
Future<void> showCustomerBreakdown(
  BuildContext context, {
  required Tally customer,
  required List<CategorySales> categories,
  required String periodLabel,
}) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => DraggableScrollableSheet(
    initialChildSize: 0.75,
    minChildSize: 0.4,
    maxChildSize: 0.95,
    expand: false,
    builder: (context, scroll) => Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            customer.label,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            [
              if (customer.sub.isNotEmpty) customer.sub,
              periodLabel,
            ].join(' · '),
            style: TextStyle(color: AppColors.textHint, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Figure(
                'Spent',
                rupees(customer.amount),
                AppColors.brand,
                amount: customer.amount,
              ),
              const SizedBox(width: 8),
              _Figure('Invoices', '${customer.count}', AppColors.positive),
              const SizedBox(width: 8),
              _Figure('Units', '${customer.quantity}', AppColors.brandDeep),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Bought by category & size',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          CategorySizeList(categories, showBuyers: false),
        ],
      ),
    ),
  ),
);

class _Figure extends StatelessWidget {
  final String label, value;
  final Color color;
  final double? amount;
  const _Figure(this.label, this.value, this.color, {this.amount});

  @override
  Widget build(BuildContext context) => Expanded(
    child: ExactAmount(
      amount: amount,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}
