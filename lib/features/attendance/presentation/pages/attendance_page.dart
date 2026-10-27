import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/exact_amount.dart';
import '../../../../shared/widgets/module_title.dart';
import '../../../../shared/widgets/pill_segmented_control.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../domain/attendance.dart';
import '../attendance_providers.dart';
import '../widgets/attendance_card.dart';
import 'attendance_form_page.dart';

final _ymd = DateFormat('yyyy-MM-dd');
final _ym = DateFormat('yyyy-MM');

/// Company admins record and review attendance on a month calendar: every
/// day with records is marked (shift, piece, how many); tap a day for its
/// records, totals and to record more. Dates are the company's own, in its
/// time zone; search by name or code and filter shift or piece workers.
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  /// "YYYY-MM-DD"; null = today in the company's zone, once known.
  String? _selected;
  String _search = '';
  String? _kind;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  AttendanceQuery get _query =>
      (month: _ym.format(_month), search: _search, kind: _kind);

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _shiftMonth(int by, String today) {
    final next = DateTime(_month.year, _month.month + by);
    // No months after the company's current one.
    if (_ym.format(next).compareTo(today.substring(0, 7)) > 0) return;
    setState(() {
      _month = next;
      _selected = null;
    });
  }

  Future<void> _openForm(
    AttendanceList month,
    String day, {
    AttendanceRecord? edit,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AttendanceFormPage(
          date: day,
          today: month.today,
          edit: edit,
          recordedEmployeeIds: {
            for (final r in month.items)
              if (r.workDate == day) r.employeeId,
          },
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            edit == null ? 'Attendance saved' : 'Attendance updated',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(moduleAccessProvider('Attendance'));
    final async = ref.watch(attendanceMonthProvider(_query));
    final month = async.valueOrNull;
    final today = month?.today;
    // Default: today when this is the current month, else the 1st.
    final selected =
        _selected ??
        (today != null && today.startsWith(_ym.format(_month))
            ? today
            : '${_ym.format(_month)}-01');
    final dayItems = [
      for (final r in month?.items ?? const <AttendanceRecord>[])
        if (r.workDate == selected) r,
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: ModuleTitle(
          title: 'Attendance',
          subtitle: month == null
              ? 'Shifts & pieces per day'
              : 'Times in ${month.timezone}',
        ),
        actions: [
          IconButton(
            tooltip: 'Company time zone',
            onPressed: month == null
                ? null
                : () => _changeTimezone(month.timezone),
            icon: const Icon(Icons.public_rounded),
          ),
          if (access.create &&
              month != null &&
              selected.compareTo(month.today) <= 0)
            IconButton(
              tooltip: 'Record attendance',
              onPressed: () => _openForm(month, selected),
              icon: const Icon(Icons.add_circle_rounded, size: 28),
              color: AppColors.brand,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(attendanceMonthProvider(_query).future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            _CalendarCard(
              month: _month,
              selected: selected,
              today: today,
              items: month?.items ?? const [],
              loading: month == null,
              onPrev: () =>
                  _shiftMonth(-1, today ?? _ymd.format(DateTime.now())),
              onNext: () =>
                  _shiftMonth(1, today ?? _ymd.format(DateTime.now())),
              onPick: (d) => setState(() => _selected = d),
            ),
            const SizedBox(height: 14),
            SearchField(
              controller: _searchCtrl,
              hintText: 'Search name or employee ID',
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 350),
                  () => setState(() => _search = v),
                );
              },
            ),
            const SizedBox(height: 8),
            PillSegmentedControl<String>(
              value: _kind ?? 'ALL',
              onChanged: (v) => setState(() => _kind = v == 'ALL' ? null : v),
              segments: const [
                PillSegment(value: 'ALL', label: 'All'),
                PillSegment(
                  value: SalaryType.shift,
                  label: 'Shift',
                  icon: Icons.schedule_rounded,
                ),
                PillSegment(
                  value: SalaryType.piece,
                  label: 'Piece',
                  icon: Icons.content_cut_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat(
                      'EEEE, d MMM yyyy',
                    ).format(DateTime.parse(selected)),
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected == today)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.positive.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        color: AppColors.positive,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            async.when(
              skipError: true,
              loading: () => const Shimmer(
                child: SkeletonBox(width: double.infinity, height: 160),
              ),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(attendanceMonthProvider(_query)),
              ),
              data: (list) => Column(
                children: [
                  _DaySummary(dayItems),
                  const SizedBox(height: 12),
                  if (dayItems.isEmpty)
                    _Empty(
                      searching: _search.isNotEmpty || _kind != null,
                      canCreate:
                          access.create && selected.compareTo(list.today) <= 0,
                      onCreate: () => _openForm(list, selected),
                    )
                  else
                    for (final r in dayItems)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AttendanceCard(
                          record: r,
                          onTap: access.edit || access.delete
                              ? () => _openForm(list, selected, edit: r)
                              : null,
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The company's time zone for attendance dates and times.
  Future<void> _changeTimezone(String current) async {
    const zones = [
      'Asia/Kolkata',
      'Asia/Dubai',
      'Asia/Singapore',
      'Asia/Dhaka',
      'Asia/Kathmandu',
      'Asia/Colombo',
      'Asia/Riyadh',
      'Europe/London',
      'America/New_York',
      'UTC',
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Company time zone',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'Attendance dates and times use this zone. Records already '
                'saved keep their date.',
              ),
            ),
            for (final z in {current, ...zones})
              ListTile(
                title: Text(z),
                trailing: z == current
                    ? const Icon(Icons.check_rounded, color: AppColors.brand)
                    : null,
                onTap: () => Navigator.of(ctx).pop(z),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == current || !mounted) return;
    try {
      await ref
          .read(dioProvider)
          .put(ApiEndpoints.me, data: {'timezone': picked});
      _selected = null; // "today" may be a different date in the new zone
      ref.invalidate(attendanceMonthProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Time zone set to $picked')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.dangerFill,
          ),
        );
      }
    }
  }
}

// ── Month calendar ────────────────────────────────────────────────────────

/// The month as a grid (Monday first): each day with records shows how
/// many and whether shift (blue) or piece (green); today ringed, the picked
/// day filled, days after today dimmed and not tappable.
class _CalendarCard extends StatelessWidget {
  final DateTime month;
  final String selected;
  final String? today;
  final List<AttendanceRecord> items;
  final bool loading;
  final VoidCallback onPrev, onNext;
  final ValueChanged<String> onPick;
  const _CalendarCard({
    required this.month,
    required this.selected,
    required this.today,
    required this.items,
    required this.loading,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final byDay = <String, List<AttendanceRecord>>{};
    for (final r in items) {
      byDay.putIfAbsent(r.workDate, () => []).add(r);
    }
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final pad = first.weekday - 1;
    final cells = ((pad + days) / 7).ceil() * 7;
    final isLatest =
        today != null && _ym.format(month) == today!.substring(0, 7);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ]),
      ),
      child: Column(
        children: [
          // Accent strip, like the rest of the app's cards.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: Row(
              children: [
                for (final c in [
                  AppColors.brand,
                  AppColors.positive,
                  AppColors.brandDeep,
                  AppColors.brandLight,
                ])
                  Expanded(child: Container(height: 3, color: c)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                _Arrow(Icons.chevron_left_rounded, onPrev),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(month),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _Arrow(Icons.chevron_right_rounded, isLatest ? null : onNext),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (final (i, d) in const [
                  'M',
                  'T',
                  'W',
                  'T',
                  'F',
                  'S',
                  'S',
                ].indexed)
                  Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: i >= 5
                            ? AppColors.brandDeep.withValues(alpha: 0.6)
                            : AppColors.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.9,
              ),
              itemCount: cells,
              itemBuilder: (_, i) {
                if (i < pad || i >= pad + days) return const SizedBox();
                final date = DateTime(month.year, month.month, i - pad + 1);
                final key = _ymd.format(date);
                final future = today != null && key.compareTo(today!) > 0;
                return _DayCell(
                  day: date.day,
                  records: byDay[key] ?? const [],
                  isToday: key == today,
                  isSelected: key == selected,
                  isWeekend: date.weekday >= 6,
                  disabled: future,
                  loading: loading,
                  onTap: future ? null : () => onPick(key),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _Legend(AppColors.brand, 'Shift'),
                const SizedBox(width: 14),
                _Legend(AppColors.positive, 'Piece'),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${items.length} record${items.length == 1 ? '' : 's'} this month',
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textHint, fontSize: 11),
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

class _Arrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Arrow(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? 0.35 : 1,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.accentGradient(AppColors.brand),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    ),
  );
}

class _DayCell extends StatelessWidget {
  final int day;
  final List<AttendanceRecord> records;
  final bool isToday, isSelected, isWeekend, disabled, loading;
  final VoidCallback? onTap;
  const _DayCell({
    required this.day,
    required this.records,
    required this.isToday,
    required this.isSelected,
    required this.isWeekend,
    required this.disabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shifts = records.where((r) => r.isShift).length;
    final pieces = records.length - shifts;
    final has = records.isNotEmpty;
    final Color? bg = isSelected
        ? AppColors.brand
        : has
        ? (pieces > shifts ? AppColors.positive : AppColors.brand).withValues(
            alpha: 0.10,
          )
        : null;
    final fg = isSelected
        ? Colors.white
        : disabled
        ? AppColors.textHint.withValues(alpha: 0.5)
        : isWeekend
        ? AppColors.ink.withValues(alpha: 0.55)
        : AppColors.ink;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.brand, width: 1.6)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: fg,
                fontSize: 13.5,
                fontWeight: isToday || isSelected
                    ? FontWeight.w900
                    : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            if (has)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (shifts > 0)
                    _Dot(isSelected ? Colors.white : AppColors.brand),
                  if (pieces > 0)
                    _Dot(isSelected ? Colors.white : AppColors.positive),
                  const SizedBox(width: 2),
                  Text(
                    '${records.length}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            else
              const SizedBox(height: 11),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 5,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Dot(color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: AppColors.textHint, fontSize: 11)),
    ],
  );
}

/// Present · shifts · pieces · amount for the day.
class _DaySummary extends StatelessWidget {
  final List<AttendanceRecord> items;
  const _DaySummary(this.items);

  @override
  Widget build(BuildContext context) {
    final shifts = items.fold<double>(0, (a, r) => a + r.totalShifts);
    final pieces = items.fold<int>(0, (a, r) => a + r.totalPieces);
    final amount = items.fold<double>(0, (a, r) => a + (r.totalAmount ?? 0));
    Widget tile(String label, String value, Color c, {double? exact}) =>
        Expanded(
          child: ExactAmount(
            amount: exact,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.10),
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
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Row(
      children: [
        tile('Present', '${items.length}', AppColors.brand),
        const SizedBox(width: 6),
        tile('Shifts', shiftTotalLabel(shifts), AppColors.brandDeep),
        const SizedBox(width: 6),
        tile('Pieces', '$pieces', AppColors.positive),
        const SizedBox(width: 6),
        tile('Amount', rupees(amount), AppColors.brandBlack, exact: amount),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final bool searching;
  final bool canCreate;
  final VoidCallback onCreate;
  const _Empty({
    required this.searching,
    required this.canCreate,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(Icons.event_busy_rounded, size: 42, color: AppColors.textHint),
        const SizedBox(height: 8),
        Text(
          searching
              ? 'No attendance matches'
              : 'No attendance recorded for this day',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        if (!searching && canCreate) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Record attendance'),
          ),
        ],
      ],
    ),
  );
}
