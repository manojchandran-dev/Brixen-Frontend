import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/exact_amount.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../sales/domain/entities/sale.dart';
import 'category_size_sales.dart';
import 'company_reports_data.dart';

final _day = DateFormat('d MMM yyyy');

/// A customer in the Customer purchases list: rank, name and shop, chips
/// for invoices / units / last purchase, and what they spent.
class CustomerBuyRow extends StatelessWidget {
  final int rank;
  final Tally customer;
  final VoidCallback onTap;
  const CustomerBuyRow({
    super.key,
    required this.rank,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = customer;
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank == 1 ? AppColors.positive : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: rank == 1 ? Colors.white : AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (t.sub.isNotEmpty)
                      Text(
                        t.sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Chip(
                          Icons.receipt_long_rounded,
                          '${t.count} invoice${t.count == 1 ? '' : 's'}',
                        ),
                        _Chip(
                          Icons.inventory_2_outlined,
                          '${t.quantity} units',
                        ),
                        if (t.last != null)
                          _Chip(
                            Icons.schedule_rounded,
                            DateFormat('d MMM').format(t.last!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ExactAmount(
                amount: t.amount,
                child: Text(
                  rupees(t.amount),
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.brand),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

/// Everything about one customer for the period: contact details, spend,
/// invoices, units and balance due, what they bought by category and size,
/// and each invoice.
Future<void> showCustomerDetails(
  BuildContext context, {
  required Tally summary,
  required Customer? customer,
  required List<Sale> sales,
  required List<CategorySales> categories,
  required String periodLabel,
}) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => DraggableScrollableSheet(
    initialChildSize: 0.85,
    minChildSize: 0.4,
    maxChildSize: 0.95,
    expand: false,
    builder: (context, scroll) {
      final c = customer;
      final due = sales.fold<double>(0, (a, s) => a + s.balance);
      final invoices = [...sales]
        ..sort((a, b) => b.billDate.compareTo(a.billDate));
      String? has(String? v) =>
          v != null && v.trim().isNotEmpty ? v.trim() : null;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.background,
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
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.accentGradient(AppColors.brand),
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    summary.label.trim().isEmpty
                        ? '?'
                        : summary.label.trim()[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.label,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        periodLabel,
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Figure(
                  'Spent',
                  rupees(summary.amount),
                  AppColors.brand,
                  amount: summary.amount,
                ),
                const SizedBox(width: 8),
                _Figure('Invoices', '${summary.count}', AppColors.positive),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Figure('Units', '${summary.quantity}', AppColors.brandDeep),
                const SizedBox(width: 8),
                _Figure(
                  'Balance due',
                  rupees(due),
                  AppColors.brandBlack,
                  amount: due,
                ),
              ],
            ),
            if (c != null) ...[
              _Heading('Contact'),
              _Card(
                children: [
                  if (has(c.shopName) case final v?)
                    _Line(Icons.storefront_rounded, 'Shop', v),
                  if (has(c.phone) case final v?)
                    _Line(Icons.phone_outlined, 'Phone', v),
                  if (has(c.email) case final v?)
                    _Line(Icons.email_outlined, 'Email', v),
                  if (has(c.address) case final v?)
                    _Line(Icons.location_on_outlined, 'Address', v),
                  if (has(c.gstNumber) case final v?)
                    _Line(Icons.verified_outlined, 'GSTIN', v.toUpperCase()),
                  _Line(
                    Icons.event_rounded,
                    'Customer since',
                    _day.format(c.createdAt),
                  ),
                ],
              ),
            ],
            _Heading('Bought by category & size'),
            _Card(
              padding: const EdgeInsets.all(10),
              children: [CategorySizeList(categories, showBuyers: false)],
            ),
            _Heading('Invoices · ${invoices.length}'),
            _Card(
              children: [
                for (final s in invoices)
                  _Line(
                    s.isGst
                        ? Icons.verified_outlined
                        : Icons.receipt_long_outlined,
                    [
                      _day.format(s.billDate),
                      if (s.billNo != null) s.billNo!,
                    ].join(' · '),
                    '${rupees(s.totalAmount)} · ${s.paymentStatus}',
                    amount: s.totalAmount,
                  ),
              ],
            ),
          ],
        ),
      );
    },
  ),
);

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 20, 2, 8),
    child: Text(
      text,
      style: TextStyle(
        color: AppColors.ink,
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  const _Card({
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(children: children),
  );
}

/// Icon, label on the left, value on the right (wraps under long values).
class _Line extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final double? amount;
  const _Line(this.icon, this.label, this.value, {this.amount});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.brand),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(color: AppColors.textHint, fontSize: 12.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: ExactAmount(
            amount: amount,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.accentGradient(color),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
