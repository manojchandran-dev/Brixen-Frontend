import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/exact_amount.dart';
import '../../domain/attendance.dart';

/// One day's attendance: who (or which date, on the employee's own screen),
/// shift or piece badge, the shifts or each work type's quantity × rate,
/// and the day's total.
class AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;

  /// Admin list: show the employee. Employee's own list: show the date.
  final bool showEmployee;
  final VoidCallback? onTap;
  const AttendanceCard({
    super.key,
    required this.record,
    this.showEmployee = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = record;
    final accent = r.isShift ? AppColors.brand : AppColors.positive;
    final day = DateTime.tryParse(r.workDate);
    final title = showEmployee
        ? r.employeeName
        : (day == null
              ? r.workDate
              : DateFormat('EEE, d MMM yyyy').format(day));
    final subtitle = showEmployee
        ? [r.employeeCode, if (r.department != null) r.department!].join(' · ')
        : 'Recorded ${r.recordedLocal}';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.accentGradient(accent),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: showEmployee
                        ? Text(
                            r.employeeName.isEmpty
                                ? '?'
                                : r.employeeName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          )
                        : Text(
                            day == null ? '' : '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitle,
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
                  _Badge(
                    r.isShift ? 'Shift' : 'Piece',
                    r.isShift
                        ? Icons.schedule_rounded
                        : Icons.content_cut_rounded,
                    accent,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (r.isShift)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final (i, s) in r.shifts.indexed)
                      _Pill('Shift ${i + 1} · ${shiftUnitLabel(s)}'),
                  ],
                )
              else
                Column(
                  children: [
                    for (final p in r.pieces)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 6, color: accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.workTypeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${p.quantity} × ${rupeesExact(p.rate)} = ',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              rupeesExact(p.amount),
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      r.isShift
                          ? 'Day total · ${shiftTotalLabel(r.totalShifts)} shift${r.totalShifts == 1 ? '' : 's'}'
                          : 'Day total · ${r.totalPieces} piece${r.totalPieces == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (r.totalAmount != null)
                      ExactAmount(
                        amount: r.totalAmount,
                        child: Text(
                          rupees(r.totalAmount!),
                          style: TextStyle(
                            color: accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (showEmployee || (r.notes?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 8),
                Text(
                  [
                    if (showEmployee) 'Recorded ${r.recordedLocal}',
                    if (r.notes?.isNotEmpty ?? false) r.notes!,
                  ].join(' · '),
                  style: TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _Badge(this.text, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: AppColors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
