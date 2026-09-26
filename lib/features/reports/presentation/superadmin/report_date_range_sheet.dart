import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brixen_button.dart';

/// Opens the date range bottom sheet (quick picks + calendar) and returns
/// the chosen range, or null if dismissed.
Future<DateTimeRange?> showReportDateRangeSheet(
  BuildContext context, {
  DateTimeRange? initial,
}) => showModalBottomSheet<DateTimeRange>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => ReportDateRangeSheet(initialRange: initial),
);

// ── Custom date range picker sheet ───────────────────────────────────────────

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class ReportDateRangeSheet extends StatefulWidget {
  final DateTimeRange? initialRange;
  const ReportDateRangeSheet({super.key, this.initialRange});

  @override
  State<ReportDateRangeSheet> createState() => _ReportDateRangeSheetState();
}

class _ReportDateRangeSheetState extends State<ReportDateRangeSheet> {
  late DateTime _visibleMonth;
  DateTime? _start;
  DateTime? _end;

  static final _fmt = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
    final base = _start ?? DateTime.now();
    _visibleMonth = DateTime(base.year, base.month, 1);
  }

  void _selectDay(DateTime day) {
    setState(() {
      if (_start == null || _end != null) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  void _quickSelect({
    int? lastDays,
    bool thisMonth = false,
    bool lastMonth = false,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      if (thisMonth) {
        _start = DateTime(now.year, now.month, 1);
        _end = today;
      } else if (lastMonth) {
        _start = DateTime(now.year, now.month - 1, 1);
        _end = DateTime(now.year, now.month, 0);
      } else {
        _start = today.subtract(Duration(days: (lastDays ?? 7) - 1));
        _end = today;
      }
      _visibleMonth = DateTime(_start!.year, _start!.month, 1);
    });
  }

  void _changeMonth(int delta) => setState(
    () => _visibleMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + delta,
      1,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final leadingBlanks = _visibleMonth.weekday % 7;
    final canGoForward = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      1,
    ).isBefore(DateTime(now.year, now.month + 1, 1));

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Date Range',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: AppColors.shadows([
                          BoxShadow(
                            color: AppColors.shadowDark.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: AppColors.highlightShadow(0.85),
                            blurRadius: 3,
                            offset: const Offset(-2, -2),
                          ),
                        ]),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _start == null
                    ? 'Pick a start date'
                    : _end == null
                    ? '${_fmt.format(_start!)} → Pick an end date'
                    : '${_fmt.format(_start!)} → ${_fmt.format(_end!)}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // ── Quick select chips ───────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickChip(
                      label: '7 Days',
                      onTap: () => _quickSelect(lastDays: 7),
                    ),
                    const SizedBox(width: 8),
                    _QuickChip(
                      label: '30 Days',
                      onTap: () => _quickSelect(lastDays: 30),
                    ),
                    const SizedBox(width: 8),
                    _QuickChip(
                      label: 'This Month',
                      onTap: () => _quickSelect(thisMonth: true),
                    ),
                    const SizedBox(width: 8),
                    _QuickChip(
                      label: 'Last Month',
                      onTap: () => _quickSelect(lastMonth: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Calendar card ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppColors.shadows([
                    BoxShadow(
                      color: AppColors.shadowDark.withValues(alpha: 0.07),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.highlightShadow(0.85),
                      blurRadius: 8,
                      offset: const Offset(-3, -3),
                    ),
                  ]),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _MonthNavButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => _changeMonth(-1),
                        ),
                        Expanded(
                          child: Text(
                            DateFormat('MMMM yyyy').format(_visibleMonth),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        _MonthNavButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: canGoForward ? () => _changeMonth(1) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                          .map(
                            (d) => Expanded(
                              child: Center(
                                child: Text(
                                  d,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: leadingBlanks + daysInMonth,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                          ),
                      itemBuilder: (_, i) {
                        if (i < leadingBlanks) return const SizedBox.shrink();
                        final day = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month,
                          i - leadingBlanks + 1,
                        );
                        final isFuture = day.isAfter(
                          DateTime(now.year, now.month, now.day),
                        );
                        final isStart =
                            _start != null && _sameDay(day, _start!);
                        final isEnd = _end != null && _sameDay(day, _end!);
                        final inRange =
                            _start != null &&
                            _end != null &&
                            day.isAfter(_start!) &&
                            day.isBefore(_end!);
                        final isToday = _sameDay(day, now);

                        return GestureDetector(
                          onTap: isFuture ? null : () => _selectDay(day),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              decoration: BoxDecoration(
                                color: inRange
                                    ? AppColors.brand.withValues(alpha: 0.12)
                                    : null,
                                gradient: (isStart || isEnd)
                                    ? const LinearGradient(
                                        colors: [
                                          AppColors.brand,
                                          AppColors.brandDeep,
                                        ],
                                      )
                                    : null,
                                shape: BoxShape.circle,
                                border: isToday && !isStart && !isEnd
                                    ? Border.all(
                                        color: AppColors.brand,
                                        width: 1.3,
                                      )
                                    : null,
                                boxShadow: (isStart || isEnd)
                                    ? AppColors.shadows([
                                        BoxShadow(
                                          color: AppColors.brand.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ])
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: (isStart || isEnd)
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: (isStart || isEnd)
                                      ? AppColors.white
                                      : isFuture
                                      ? AppColors.textHint.withValues(
                                          alpha: 0.4,
                                        )
                                      : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              BrixenButton(
                label: 'Apply Range',
                onPressed: (_start != null && _end != null)
                    ? () => Navigator.pop(
                        context,
                        DateTimeRange(start: _start!, end: _end!),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: AppColors.highlightShadow(0.85),
              blurRadius: 4,
              offset: const Offset(-2, -2),
            ),
          ]),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.brand,
          ),
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _MonthNavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: AppColors.highlightShadow(0.85),
              blurRadius: 3,
              offset: const Offset(-2, -2),
            ),
          ]),
        ),
        child: Icon(
          icon,
          size: 18,
          color: disabled
              ? AppColors.textHint.withValues(alpha: 0.4)
              : AppColors.ink,
        ),
      ),
    );
  }
}

/// Mirrors the real report's period-selector / hero / split / chart-card
/// shape so nothing jumps in size once the summary call resolves.
