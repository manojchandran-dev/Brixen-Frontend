import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../domain/entities/attendance_record.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';

class AttendanceBody extends StatefulWidget {
  const AttendanceBody({super.key});

  @override
  State<AttendanceBody> createState() => _AttendanceBodyState();
}

class _AttendanceBodyState extends State<AttendanceBody> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() => setState(
      () => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));

  void _nextMonth() => setState(
      () => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  void _openSheet(DateTime date) {
    setState(() => _selectedDate = date);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _AttendanceSheet(date: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      bloc: attendanceCubit,
      builder: (context, state) {
        final records =
            state is AttendanceLoaded ? state.records : <AttendanceRecord>[];
        final now = DateTime.now();
        final todayRecords = records
            .where((r) =>
                r.date.year == now.year &&
                r.date.month == now.month &&
                r.date.day == now.day)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TodayBanner(
                todayRecords: todayRecords,
                onMarkToday: () => _openSheet(now),
              ),
              const SizedBox(height: 16),
              _CalendarCard(
                focusedMonth: _focusedMonth,
                selectedDate: _selectedDate,
                records: records,
                onPrev: _prevMonth,
                onNext: _nextMonth,
                onDateTap: _openSheet,
              ),
              const SizedBox(height: 14),
              _SummaryGrid(month: _focusedMonth, records: records),
              const SizedBox(height: 14),
              _WeekStrip(records: records, onDateTap: _openSheet),
            ],
          ),
        );
      },
    );
  }
}

// ── Today Banner ──────────────────────────────────────────────────────────────

class _TodayBanner extends StatelessWidget {
  final List<AttendanceRecord> todayRecords;
  final VoidCallback onMarkToday;

  const _TodayBanner({required this.todayRecords, required this.onMarkToday});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final subtitle = todayRecords.isEmpty
        ? 'No attendance marked yet'
        : '${todayRecords.length} record${todayRecords.length > 1 ? 's' : ''} marked today';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ]),
      ),
      child: Column(
        children: [
          // Multicolor top strip
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: Row(children: [
              Expanded(child: Container(height: 3, color: AppColors.accentEmerald)),
              Expanded(child: Container(height: 3, color: AppColors.accentTeal)),
              Expanded(child: Container(height: 3, color: AppColors.accentIndigo)),
              Expanded(child: Container(height: 3, color: AppColors.accentViolet)),
              Expanded(child: Container(height: 3, color: AppColors.accentGold)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(now),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('d MMMM yyyy').format(now),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: todayRecords.isEmpty
                                  ? cs.onSurfaceVariant.withValues(alpha: 0.4)
                                  : AppColors.accentEmerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            subtitle,
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onMarkToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isDark ? AppColors.silverGradient : null,
                      color: isDark ? null : AppColors.lightPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.shadows([
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.25 : 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.edit_calendar_rounded,
                            size: 20,
                            color: isDark ? AppColors.black : AppColors.white),
                        const SizedBox(height: 4),
                        Text(
                          'Mark',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? AppColors.black : AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Calendar Card ─────────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final List<AttendanceRecord> records;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime) onDateTap;

  const _CalendarCard({
    required this.focusedMonth,
    required this.selectedDate,
    required this.records,
    required this.onPrev,
    required this.onNext,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ]),
      ),
      child: Column(
        children: [
          // Multicolor accent strip
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(17)),
            child: Row(
              children: [
                Expanded(child: Container(height: 3, color: AppColors.accentEmerald)),
                Expanded(child: Container(height: 3, color: AppColors.accentRose)),
                Expanded(child: Container(height: 3, color: AppColors.accentGold)),
                Expanded(child: Container(height: 3, color: AppColors.accentIndigo)),
              ],
            ),
          ),
          _MonthHeader(
              focusedMonth: focusedMonth, onPrev: onPrev, onNext: onNext),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _WeekdayRow(),
          _DayGrid(
            focusedMonth: focusedMonth,
            selectedDate: selectedDate,
            records: records,
            onDateTap: onDateTap,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Month Header ──────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader(
      {required this.focusedMonth, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          _NavArrow(icon: Icons.chevron_left_rounded, isDark: isDark, onTap: onPrev),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(focusedMonth),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: 0.3,
              ),
            ),
          ),
          _NavArrow(icon: Icons.chevron_right_rounded, isDark: isDark, onTap: onNext),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _NavArrow(
      {required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.silverGradient : null,
          color: isDark ? null : AppColors.lightPrimary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]),
        ),
        child: Icon(icon,
            size: 20,
            color: isDark ? AppColors.black : AppColors.white),
      ),
    );
  }
}

// ── Weekday Row ───────────────────────────────────────────────────────────────

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: days.asMap().entries
            .map((e) => Expanded(
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: e.key >= 5
                          ? AppColors.accentRose.withValues(alpha: 0.6)
                          : cs.onSurfaceVariant.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Day Grid ──────────────────────────────────────────────────────────────────

class _DayGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final List<AttendanceRecord> records;
  final void Function(DateTime) onDateTap;

  const _DayGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.records,
    required this.onDateTap,
  });

  List<AttendanceRecord> _forDate(DateTime d) => records
      .where((r) =>
          r.date.year == d.year &&
          r.date.month == d.month &&
          r.date.day == d.day)
      .toList();

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startPad = firstDay.weekday - 1;
    final totalCells = startPad + daysInMonth;
    final gridCount = ((totalCells / 7).ceil()) * 7;
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
        ),
        itemCount: gridCount,
        itemBuilder: (_, idx) {
          if (idx < startPad || idx >= startPad + daysInMonth) {
            return const SizedBox();
          }
          final day = idx - startPad + 1;
          final date = DateTime(focusedMonth.year, focusedMonth.month, day);
          final dayRecords = _forDate(date);
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
          final isSelected = selectedDate != null &&
              date.year == selectedDate!.year &&
              date.month == selectedDate!.month &&
              date.day == selectedDate!.day;
          final isWeekend = date.weekday >= 6;
          return _DayCell(
            date: date,
            records: dayRecords,
            isToday: isToday,
            isSelected: isSelected,
            isWeekend: isWeekend,
            onTap: () => onDateTap(date),
          );
        },
      ),
    );
  }
}

// ── Day Cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final DateTime date;
  final List<AttendanceRecord> records;
  final bool isToday;
  final bool isSelected;
  final bool isWeekend;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.records,
    required this.isToday,
    required this.isSelected,
    required this.isWeekend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    Color? bgColor;
    Color textColor;
    BoxBorder? border;

    if (isToday) {
      bgColor = AppColors.accentIndigo;
      textColor = Colors.white;
    } else if (isSelected) {
      bgColor = AppColors.accentIndigo.withValues(alpha: isDark ? 0.18 : 0.10);
      textColor = AppColors.accentIndigo;
      border = Border.all(
          color: AppColors.accentIndigo.withValues(alpha: 0.4), width: 1);
    } else if (records.isNotEmpty) {
      final statusColor = records.first.status.color;
      bgColor = statusColor.withValues(alpha: isDark ? 0.14 : 0.09);
      textColor = isWeekend
          ? cs.onSurface.withValues(alpha: 0.45)
          : cs.onSurface;
      border = Border.all(color: statusColor.withValues(alpha: 0.22), width: 1);
    } else if (isWeekend) {
      bgColor = null;
      textColor = cs.onSurface.withValues(alpha: 0.4);
    } else {
      bgColor = null;
      textColor = cs.onSurface;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: border,
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: AppColors.accentIndigo.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                color: textColor,
              ),
            ),
            if (records.isNotEmpty) ...[
              const SizedBox(height: 2),
              _AttendanceDots(records: records),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Attendance Dots ───────────────────────────────────────────────────────────

class _AttendanceDots extends StatelessWidget {
  final List<AttendanceRecord> records;
  const _AttendanceDots({required this.records});

  @override
  Widget build(BuildContext context) {
    final colors = records.take(3).map((r) => r.status.color).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final color in colors)
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        if (records.length > 3)
          Padding(
            padding: const EdgeInsets.only(left: 1),
            child: Text('+',
                style: TextStyle(
                    fontSize: 7,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
      ],
    );
  }
}

// ── Summary Grid (2×2) ────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  final DateTime month;
  final List<AttendanceRecord> records;

  const _SummaryGrid({required this.month, required this.records});

  @override
  Widget build(BuildContext context) {
    final monthRecords = records
        .where((r) => r.date.year == month.year && r.date.month == month.month)
        .toList();

    final present =
        monthRecords.where((r) => r.status == AttendanceStatus.present).length;
    final absent =
        monthRecords.where((r) => r.status == AttendanceStatus.absent).length;
    final leave =
        monthRecords.where((r) => r.status == AttendanceStatus.leave).length;
    final halfDay =
        monthRecords.where((r) => r.status == AttendanceStatus.halfDay).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.accentEmerald,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${DateFormat('MMMM').format(month)} Summary',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Present',
                count: present,
                color: AttendanceStatus.present.color,
                icon: AttendanceStatus.present.icon,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Absent',
                count: absent,
                color: AttendanceStatus.absent.color,
                icon: AttendanceStatus.absent.icon,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'On Leave',
                count: leave,
                color: AttendanceStatus.leave.color,
                icon: AttendanceStatus.leave.icon,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Half Day',
                count: halfDay,
                color: AttendanceStatus.halfDay.color,
                icon: AttendanceStatus.halfDay.icon,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: color),
              Container(
                width: 45,
                color: color.withValues(alpha: 0.15),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
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
}

// ── Week Strip ────────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  final List<AttendanceRecord> records;
  final void Function(DateTime) onDateTap;

  const _WeekStrip({required this.records, required this.onDateTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.accentIndigo,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'This Week',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: days.map((d) {
            final isToday = d.year == now.year &&
                d.month == now.month &&
                d.day == now.day;
            final dayRecords = records
                .where((r) =>
                    r.date.year == d.year &&
                    r.date.month == d.month &&
                    r.date.day == d.day)
                .toList();
            final isWeekend = d.weekday >= 6;
            return Expanded(
              child: GestureDetector(
                onTap: () => onDateTap(d),
                child: _WeekDay(
                  date: d,
                  isToday: isToday,
                  isWeekend: isWeekend,
                  records: dayRecords,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _WeekDay extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isWeekend;
  final List<AttendanceRecord> records;

  const _WeekDay({
    required this.date,
    required this.isToday,
    required this.isWeekend,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final label = dayLabels[date.weekday - 1];

    final hasRecords = records.isNotEmpty;
    final statusColor = hasRecords ? records.first.status.color : null;
    final dotColor = hasRecords ? statusColor! : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.accentIndigo
            : hasRecords
                ? statusColor!.withValues(alpha: isDark ? 0.14 : 0.09)
                : isDark
                    ? cs.surfaceContainerHighest
                    : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? null
            : hasRecords
                ? Border.all(color: statusColor!.withValues(alpha: 0.35))
                : Border.all(color: Theme.of(context).dividerColor),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppColors.accentIndigo.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : hasRecords
                ? [
                    BoxShadow(
                      color: statusColor!.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isToday
                  ? Colors.white70
                  : isWeekend
                      ? AppColors.accentRose.withValues(alpha: 0.6)
                      : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isToday
                  ? Colors.white
                  : hasRecords
                      ? statusColor
                      : cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.white.withValues(alpha: records.isEmpty ? 0.3 : 0.9)
                  : dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Attendance Sheet ──────────────────────────────────────────────────────────

class _AttendanceSheet extends ConsumerStatefulWidget {
  final DateTime date;
  const _AttendanceSheet({required this.date});

  @override
  ConsumerState<_AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends ConsumerState<_AttendanceSheet> {
  Employee? _employee;
  AttendanceStatus _status = AttendanceStatus.present;
  TimeOfDay? _inTime;
  TimeOfDay? _outTime;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _needsTimes =>
      _status == AttendanceStatus.present ||
      _status == AttendanceStatus.halfDay;

  Future<void> _pickTime(bool isIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isIn
          ? (_inTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_outTime ?? const TimeOfDay(hour: 18, minute: 0)),
    );
    if (picked != null) {
      setState(() => isIn ? _inTime = picked : _outTime = picked);
    }
  }

  void _save() {
    if (_employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select an employee'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    attendanceCubit.add(AttendanceRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      employeeId: _employee!.id,
      employeeName: _employee!.fullName,
      date: widget.date,
      status: _status,
      inTime: _needsTimes ? _inTime : null,
      outTime: _needsTimes ? _outTime : null,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final employees = ref.watch(employeesProvider).valueOrNull ?? <Employee>[];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Date header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppColors.accentIndigo),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(widget.date),
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                    Text(
                      DateFormat('d MMMM yyyy').format(widget.date),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Divider(height: 20, color: Theme.of(context).dividerColor),
          // Existing records
          BlocBuilder<AttendanceCubit, AttendanceState>(
            bloc: attendanceCubit,
            builder: (_, state) {
              final existing = state is AttendanceLoaded
                  ? state.forDate(widget.date)
                  : <AttendanceRecord>[];
              if (existing.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Text('Marked Attendance',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant)),
                  ),
                  ...existing.map((r) => _RecordTile(record: r)),
                  Divider(
                      height: 24, color: Theme.of(context).dividerColor),
                ],
              );
            },
          ),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Attendance',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  const SizedBox(height: 12),
                  employees.isEmpty
                      ? const _EmptyEmployeeBanner()
                      : BrixenDropdown<Employee>(
                          hint: 'Select Employee *',
                          value: _employee,
                          items: employees,
                          labelOf: (e) => e.fullName,
                          icon: Icons.person_outline_rounded,
                          onChanged: (e) => setState(() => _employee = e),
                        ),
                  const SizedBox(height: 16),
                  Text('Status',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _StatusSelector(
                    selected: _status,
                    onChanged: (s) => setState(() => _status = s),
                  ),
                  if (_needsTimes) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeField(
                            label: 'In Time',
                            time: _inTime,
                            icon: Icons.login_rounded,
                            onTap: () => _pickTime(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeField(
                            label: 'Out Time',
                            time: _outTime,
                            icon: Icons.logout_rounded,
                            onTap: () => _pickTime(false),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  _NoteField(controller: _noteCtrl),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.silver
                            : AppColors.lightPrimary,
                        foregroundColor:
                            isDark ? AppColors.black : AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Attendance',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Record Tile ───────────────────────────────────────────────────────────────

class _RecordTile extends StatelessWidget {
  final AttendanceRecord record;
  const _RecordTile({required this.record});

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final color = record.status.color;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.employeeName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                if (record.inTime != null || record.outTime != null)
                  Text(
                    '${record.inTime != null ? _fmt(record.inTime!) : '--'}'
                    '  →  '
                    '${record.outTime != null ? _fmt(record.outTime!) : '--'}',
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(record.status.label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => attendanceCubit.delete(record.id),
            child: Icon(Icons.delete_outline_rounded,
                size: 18, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Status Selector ───────────────────────────────────────────────────────────

class _StatusSelector extends StatelessWidget {
  final AttendanceStatus selected;
  final void Function(AttendanceStatus) onChanged;

  const _StatusSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final statuses = AttendanceStatus.values;
    return Row(
      children: statuses.asMap().entries.map((entry) {
        final idx = entry.key;
        final s = entry.value;
        final isSelected = s == selected;
        final color = s.color;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(right: idx < statuses.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? color
                      : color.withValues(alpha: 0.3),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(s.icon,
                      size: 18,
                      color: isSelected ? Colors.white : color),
                  const SizedBox(height: 3),
                  Text(
                    s.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Time Field ────────────────────────────────────────────────────────────────

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeField(
      {required this.label, this.time, required this.icon, required this.onTap});

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                  Text(
                    time != null ? _fmt(time!) : 'Tap to set',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: time != null ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.access_time_rounded,
                size: 15,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Note Field ────────────────────────────────────────────────────────────────

class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  const _NoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      maxLines: 2,
      style: TextStyle(fontSize: 14, color: cs.onSurface),
      decoration: InputDecoration(
        hintText: 'Note (optional)',
        hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        filled: true,
        fillColor:
            isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.silver, width: 1.5),
        ),
      ),
    );
  }
}

// ── Empty Employee Banner ─────────────────────────────────────────────────────

class _EmptyEmployeeBanner extends StatelessWidget {
  const _EmptyEmployeeBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: AppColors.accentGold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No employees found. Add employees in Menu → Employees.',
              style: TextStyle(fontSize: 12, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
