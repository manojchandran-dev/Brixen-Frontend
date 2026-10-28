import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/exact_amount.dart';
import '../../../attendance/domain/attendance.dart';
import '../../../attendance/presentation/salary_type_visuals.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../domain/salary_summary.dart';

/// "22 days · 2 absent", "24 shifts", "160 h", "1,200 pieces" — what an
/// employee did in the period, by their salary type.
String workLine(EmployeeWork e) {
  final parts = switch (e.salaryType) {
    SalaryType.shift => [
      '${shiftTotalLabel(e.shifts)} shift${e.shifts == 1 ? '' : 's'}',
      '${daysLabel(e.daysPresent)} days',
    ],
    SalaryType.hourly => [
      '${hoursLabel(e.hours)} h',
      '${daysLabel(e.daysPresent)} days',
    ],
    SalaryType.piece => [
      '${NumberFormat.decimalPattern('en_IN').format(e.pieces)} pieces',
      if (e.pieceUnconfirmed > 0) '${e.pieceUnconfirmed} to confirm',
    ],
    _ => ['${daysLabel(e.daysPresent)} days present'],
  };
  return [...parts, if (e.absent > 0) '${e.absent} absent'].join(' · ');
}

/// Each employee's work and pay so far for the period, with the total.
class EmployeeWorkList extends StatelessWidget {
  final List<EmployeeWork> items;
  final String title;
  final String? caption;
  const EmployeeWorkList({
    super.key,
    required this.items,
    required this.title,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (a, e) => a + e.amount);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ExactAmount(
                amount: total,
                child: Text(
                  rupees(total),
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (caption != null)
            Text(
              caption!,
              style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
            ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Nobody here yet',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          for (final (i, e) in items.indexed) ...[
            if (i > 0) Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.accentGradient(
                          salaryTypeColor(e.salaryType),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      salaryTypeIcon(e.salaryType),
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
                          e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${SalaryType.label(e.salaryType)} · ${workLine(e)}',
                          maxLines: 2,
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
                        amount: e.amount,
                        child: Text(
                          rupees(e.amount),
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (e.payslipNet != null)
                        Text(
                          'Payslip ${rupees(e.payslipNet!)}',
                          style: TextStyle(
                            color: AppColors.positiveDeep,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What sold in the month, day by day: each product with the quantity and
/// pieces. Tap a line to enter piece pay for it ([onPick]).
class SalesByDayList extends StatelessWidget {
  final List<SoldLine> lines;
  final ValueChanged<SoldLine>? onPick;
  const SalesByDayList({super.key, required this.lines, this.onPick});

  @override
  Widget build(BuildContext context) {
    final byDay = <String, List<SoldLine>>{};
    for (final l in lines) {
      byDay.putIfAbsent(l.date, () => []).add(l);
    }
    final color = salaryTypeColor(SalaryType.piece);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sold this month',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            onPick == null
                ? 'Products sold, by bill date'
                : 'Tap a product to pay piece rate for it',
            style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
          ),
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'No sales this month',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          for (final entry in byDay.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text(
                DateFormat(
                  'EEE, d MMM',
                ).format(DateTime.parse(entry.key)).toUpperCase(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            for (final l in entry.value)
              InkWell(
                onTap: onPick == null ? null : () => onPick!(l),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.sell_rounded, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        l.isCombo
                            ? '${l.quantity} combo${l.quantity == 1 ? '' : 's'} = ${l.pieces} pcs'
                            : '${l.pieces} pcs',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (onPick != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 18,
                          color: color,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
