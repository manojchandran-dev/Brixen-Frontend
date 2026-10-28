import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/exact_amount.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../domain/attendance.dart';
import '../salary_type_visuals.dart';

/// One day's attendance: who (or which date, on the employee's own screen),
/// a salary-type badge in that type's colour, what was worked (shifts, each
/// work type's quantity × rate, hours, or a full / half day) and the day's
/// total.
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
    // An absent day reads dark (ink), not in its salary type's colour.
    final accent = r.isAbsent
        ? (AppColors.isDark ? AppColors.textHint : AppColors.brandBlack)
        : salaryTypeColor(r.kind);
    final day = DateTime.tryParse(r.workDate);
    final title = showEmployee
        ? r.employeeName
        : (day == null
              ? r.workDate
              : DateFormat('EEE, d MMM yyyy').format(day));
    final subtitle = showEmployee
        ? [r.employeeCode, if (r.department != null) r.department!].join(' · ')
        : 'Recorded ${r.recordedLocal}';

    // The whole card in the salary type's colour: a solid band with who it
    // is, then the day's work on a tint of the same colour.
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withValues(alpha: 0.22),
                accent.withValues(alpha: 0.10),
              ],
            ),
            boxShadow: AppColors.shadows([
              BoxShadow(
                color: accent.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(17),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.accentGradient(accent),
                  ),
                ),
                child: _header(r, day, title, subtitle, accent),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _work(r, accent),
                    const SizedBox(height: 10),
                    _total(r, accent),
                    if (showEmployee || (r.notes?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (showEmployee) 'Recorded ${r.recordedLocal}',
                          if (r.notes?.isNotEmpty ?? false) r.notes!,
                        ].join(' · '),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(
    AttendanceRecord r,
    DateTime? day,
    String title,
    String subtitle,
    Color accent,
  ) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Text(
          showEmployee
              ? (r.employeeName.isEmpty ? '?' : r.employeeName[0].toUpperCase())
              : (day == null ? '' : '${day.day}'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 6),
      r.isAbsent
          ? _Badge('Absent', Icons.person_off_outlined, accent)
          : _Badge(SalaryType.label(r.kind), salaryTypeIcon(r.kind), accent),
    ],
  );

  Widget _work(AttendanceRecord r, Color accent) {
    if (r.isAbsent) {
      return _Pill('Absent — nothing recorded, not paid', accent);
    }
    switch (r.kind) {
      case SalaryType.shift:
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (i, s) in r.shifts.indexed)
              _Pill('Shift ${i + 1} · ${shiftUnitLabel(s)}', accent),
          ],
        );
      case SalaryType.piece:
        // Paid on the sales of the products they make, not by the day.
        return _Pill('Present · paid from sales of products made', accent);
      case SalaryType.hourly:
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Pill('${hoursLabel(r.hours ?? 0)} h worked', accent),
            if (r.salary != null)
              _Pill('${rupeesExact(r.salary!)} per hour', accent, faint: true),
          ],
        );
      default:
        final half = (r.dayUnits ?? 1) < 1;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Pill(half ? 'Half day' : 'Full day', accent),
            _Pill(
              '${SalaryType.label(r.kind)} salary — paid at salary generation',
              accent,
              faint: true,
            ),
          ],
        );
    }
  }

  Widget _total(AttendanceRecord r, Color accent) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: accent.withValues(alpha: 0.35)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Day total · ${r.workSummary}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (r.totalAmount != null)
          ExactAmount(
            amount: r.totalAmount,
            child: Text(
              rupees(r.totalAmount!),
              style: TextStyle(
                color: AppColors.isDark ? accent : AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _Badge(this.text, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
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
  final Color color;

  /// A side note rather than the day's work.
  final bool faint;
  const _Pill(this.text, this.color, {this.faint = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: faint ? 0.55 : 0.9),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.30)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: faint ? AppColors.textSecondary : AppColors.ink,
        fontSize: 12,
        fontWeight: faint ? FontWeight.w600 : FontWeight.w700,
      ),
    ),
  );
}
