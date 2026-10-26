import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/exact_amount.dart';
import 'company_reports_data.dart';

/// A product in the Product sales list: rank, name, units and revenue; tap
/// to open its sizes and a table of how many of each size every customer
/// bought.
class ProductSizeRow extends StatefulWidget {
  final int rank;
  final ProductSales product;
  const ProductSizeRow({super.key, required this.rank, required this.product});

  @override
  State<ProductSizeRow> createState() => _ProductSizeRowState();
}

class _ProductSizeRowState extends State<ProductSizeRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final rank = widget.rank;
    final sizes = p.sizes;
    final buyers = p.buyers;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: _open ? AppColors.background : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? AppColors.positive
                          : AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rank == 1 ? Colors.white : AppColors.ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          [
                            p.category.isEmpty ? 'Uncategorised' : p.category,
                            _count(sizes.length, 'size'),
                            _count(buyers.length, 'customer'),
                          ].join(' · '),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ExactAmount(
                        amount: p.amount,
                        child: Text(
                          rupees(p.amount),
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${p.quantity} sold',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Caption('Sold by size'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final s in sizes) _SizePill(s)],
                  ),
                  const SizedBox(height: 12),
                  _Caption('Customers × size'),
                  _BuyerSizeTable(p),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _count(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
}

class _Caption extends StatelessWidget {
  final String text;
  const _Caption(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.textHint,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    ),
  );
}

/// "S · 120 sold · ₹16,200".
class _SizePill extends StatelessWidget {
  final Tally size;
  const _SizePill(this.size);

  @override
  Widget build(BuildContext context) => ExactAmount(
    amount: size.amount,
    child: Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              size.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '${size.quantity} sold · ${rupees(size.amount)}',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Rows = customers, columns = the product's sizes, cells = units bought,
/// last column the customer's total units (tap it for the amount). Scrolls
/// sideways when there are many sizes.
class _BuyerSizeTable extends StatelessWidget {
  final ProductSales product;
  const _BuyerSizeTable(this.product);

  static const _nameW = 128.0, _cellW = 46.0, _totalW = 56.0;

  @override
  Widget build(BuildContext context) {
    final sizes = product.sizes;
    final head = TextStyle(
      color: AppColors.textHint,
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
    );
    Widget cell(String text, double w, TextStyle style, {bool left = false}) =>
        SizedBox(
          width: w,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: left ? TextAlign.start : TextAlign.center,
            style: style,
          ),
        );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  cell('CUSTOMER', _nameW, head, left: true),
                  for (final s in sizes) cell(s.label, _cellW, head),
                  cell('TOTAL', _totalW, head),
                ],
              ),
            ),
            for (final b in product.buyers) ...[
              SizedBox(
                width: _nameW + _cellW * sizes.length + _totalW,
                child: Divider(height: 1, color: AppColors.border),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: _nameW,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (b.sub.isNotEmpty)
                            Text(
                              b.sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 10.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (final s in sizes)
                      _units(cell, product.unitsOf(b.key, s.label)),
                    SizedBox(
                      width: _totalW,
                      child: ExactAmount(
                        amount: b.amount,
                        child: Text(
                          '${b.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.positive,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// A size cell: the units, or a faint dash for none.
  Widget _units(
    Widget Function(String, double, TextStyle, {bool left}) cell,
    int n,
  ) => cell(
    n == 0 ? '–' : '$n',
    _cellW,
    TextStyle(
      color: n == 0 ? AppColors.textHint : AppColors.ink,
      fontSize: 12,
      fontWeight: n == 0 ? FontWeight.w400 : FontWeight.w800,
    ),
  );
}
