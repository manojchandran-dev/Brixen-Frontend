import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/exact_amount.dart';
import '../../../../shared/widgets/module_title.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/theme_banner.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../domain/attendance.dart';
import '../attendance_providers.dart';
import '../salary_type_visuals.dart';
import '../widgets/attendance_card.dart';
import 'attendance_form_page.dart';

final _ymd = DateFormat('yyyy-MM-dd');
final _ym = DateFormat('yyyy-MM');

/// Company admins record and review attendance on a month calendar: every
/// day with records is marked (a dot per salary type, how many); tap a day
/// for its records, totals and to record more. Dates are the company's own
/// (Asia/Kolkata unless set otherwise); search by name or code and filter by
/// salary type.
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
    final canRecord =
        access.create && month != null && selected.compareTo(month.today) <= 0;

    return Scaffold(
      drawer: const AppDrawer(),
      // AppBottomNav fills the Scaffold height (its pill is Align-ed to the
      // bottom) — without extendBody the body gets zero height.
      extendBody: true,
      bottomNavigationBar: const AppBottomNav(activeIndex: 1),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const ModuleTitle(
          title: 'Attendance',
          subtitle: 'Shifts, pieces, hours & days',
        ),
        actions: [
          if (canRecord)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _GradientIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Record attendance',
                onTap: () => _openForm(month, selected),
              ),
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
            const SizedBox(height: 10),
            _KindFilter(
              value: _kind,
              onChanged: (v) => setState(() => _kind = v),
            ),
            const SizedBox(height: 16),
            _DayHeader(day: selected, isToday: selected == today),
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
                    // Recording is the + at the top.
                    _Empty(searching: _search.isNotEmpty || _kind != null)
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
}

class _GradientIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _GradientIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brand, AppColors.brandDeep],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    ),
  );
}

// ── Month calendar ────────────────────────────────────────────────────────

/// The month as a grid (Monday first) under a blue header with the month's
/// totals: each day with records shows a dot per salary type and how many;
/// today ringed, the picked day filled, days after today dimmed and not
/// tappable.
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
    final people = {for (final r in items) r.employeeId}.length;
    final amount = items.fold<double>(0, (a, r) => a + (r.totalAmount ?? 0));
    final kinds = {for (final r in items) r.kind};

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ]),
      ),
      child: Column(
        children: [
          // Header: month, arrows and the month's totals on the theme sweep.
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
              gradient: kThemeSweepGradient,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _Arrow(Icons.chevron_left_rounded, onPrev),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy').format(month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _Arrow(
                      Icons.chevron_right_rounded,
                      isLatest ? null : onNext,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: BannerStatTile(
                        BannerStat(
                          '${items.length}',
                          'record${items.length == 1 ? '' : 's'}',
                          AppColors.brand,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BannerStatTile(
                        BannerStat('$people', 'staff', AppColors.brandBlack),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BannerStatTile(
                        BannerStat(
                          rupees(amount),
                          'priced',
                          AppColors.positive,
                          exact: amount,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
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
                        color: i == 6
                            ? AppColors.positiveDeep
                            : AppColors.brand,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: GridView.builder(
              // Not the Scaffold's inset: the bottom nav makes it the page height.
              padding: EdgeInsets.zero,
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
                  isSunday: date.weekday == 7,
                  disabled: future,
                  loading: loading,
                  onTap: future ? null : () => onPick(key),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final t in SalaryType.all)
                  _Legend(
                    salaryTypeColor(t),
                    SalaryType.label(t),
                    dim: kinds.isNotEmpty && !kinds.contains(t),
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
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    ),
  );
}

class _DayCell extends StatelessWidget {
  final int day;
  final List<AttendanceRecord> records;
  final bool isToday, isSelected, isSunday, disabled, loading;
  final VoidCallback? onTap;
  const _DayCell({
    required this.day,
    required this.records,
    required this.isToday,
    required this.isSelected,
    required this.isSunday,
    required this.disabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The day's salary types, most records first.
    final counts = <String, int>{};
    for (final r in records) {
      counts[r.kind] = (counts[r.kind] ?? 0) + 1;
    }
    final kinds = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final has = records.isNotEmpty;
    final tint = has ? salaryTypeColor(kinds.first) : null;
    final fg = isSelected
        ? Colors.white
        : disabled
        ? AppColors.textHint.withValues(alpha: 0.5)
        : isSunday
        ? AppColors.positiveDeep
        : AppColors.ink;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brand, AppColors.brandDeep],
                )
              : has
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tint!.withValues(alpha: 0.20),
                    tint.withValues(alpha: 0.07),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(11),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.brand, width: 1.8)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.40),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                fontWeight: isToday || isSelected || has
                    ? FontWeight.w900
                    : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            if (has)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final k in kinds.take(3))
                    _Dot(isSelected ? Colors.white : salaryTypeColor(k)),
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

  /// No records of this type this month.
  final bool dim;
  const _Legend(this.color, this.label, {this.dim = false});

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: dim ? 0.45 : 1,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// ── Filter, day header, totals ────────────────────────────────────────────

/// All, or one salary type — coloured chips that scroll sideways.
class _KindFilter extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _KindFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String? kind) {
      final on = value == kind;
      final color = kind == null ? AppColors.brand : salaryTypeColor(kind);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onChanged(kind),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: on
                  ? LinearGradient(colors: AppColors.accentGradient(color))
                  : null,
              color: on ? null : color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  kind == null ? Icons.groups_rounded : salaryTypeIcon(kind),
                  size: 16,
                  color: on ? Colors.white : color,
                ),
                const SizedBox(width: 6),
                Text(
                  kind == null ? 'All' : SalaryType.label(kind),
                  style: TextStyle(
                    color: on ? Colors.white : AppColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [chip(null), for (final t in SalaryType.all) chip(t)],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String day;
  final bool isToday;
  const _DayHeader({required this.day, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final d = DateTime.parse(day);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.accentGradient(
                isToday ? AppColors.positive : AppColors.brand,
              ),
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${d.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                DateFormat('MMM').format(d).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(d),
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                DateFormat('d MMMM yyyy').format(d),
                style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
              ),
            ],
          ),
        ),
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.accentGradient(AppColors.positive),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

/// The day's totals: present, then each kind of work recorded (shifts,
/// pieces, hours, days) and the priced amount — each in its type's colour.
class _DaySummary extends StatelessWidget {
  final List<AttendanceRecord> items;
  const _DaySummary(this.items);

  @override
  Widget build(BuildContext context) {
    double sum(String kind, double Function(AttendanceRecord) f) =>
        items.where((r) => r.kind == kind).fold<double>(0, (a, r) => a + f(r));
    final shifts = sum(SalaryType.shift, (r) => r.totalShifts);
    final pieces = sum(SalaryType.piece, (r) => r.totalPieces.toDouble());
    final hours = sum(SalaryType.hourly, (r) => r.hours ?? 0);
    final days =
        sum(SalaryType.weekly, (r) => r.dayUnits ?? 1) +
        sum(SalaryType.monthly, (r) => r.dayUnits ?? 1);
    final amount = items.fold<double>(0, (a, r) => a + (r.totalAmount ?? 0));

    final tiles = <Widget>[
      _Tile(
        Icons.how_to_reg_rounded,
        'Present',
        '${items.length}',
        AppColors.brand,
      ),
      if (shifts > 0)
        _Tile(
          salaryTypeIcon(SalaryType.shift),
          'Shifts',
          shiftTotalLabel(shifts),
          salaryTypeColor(SalaryType.shift),
        ),
      if (pieces > 0)
        _Tile(
          salaryTypeIcon(SalaryType.piece),
          'Pieces',
          pieces.toStringAsFixed(0),
          salaryTypeColor(SalaryType.piece),
        ),
      if (hours > 0)
        _Tile(
          salaryTypeIcon(SalaryType.hourly),
          'Hours',
          hoursLabel(hours),
          salaryTypeColor(SalaryType.hourly),
        ),
      if (days > 0)
        _Tile(
          salaryTypeIcon(SalaryType.monthly),
          'Days',
          daysLabel(days),
          salaryTypeColor(SalaryType.monthly),
        ),
      _Tile(
        Icons.currency_rupee_rounded,
        'Amount',
        rupees(amount),
        AppColors.positiveDeep,
        exact: amount,
        solid: true,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = tiles.length <= 3 ? tiles.length : 3;
        final w = (c.maxWidth - 8 * (perRow - 1)) / perRow;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final double? exact;

  /// Filled with the colour (the amount stands out).
  final bool solid;
  const _Tile(
    this.icon,
    this.label,
    this.value,
    this.color, {
    this.exact,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) => ExactAmount(
    amount: exact,
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: solid
              ? AppColors.accentGradient(color)
              : [color.withValues(alpha: 0.18), color.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: solid
                  ? Colors.white.withValues(alpha: 0.22)
                  : color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: solid ? Colors.white : color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: solid ? Colors.white : AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: solid
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

class _Empty extends StatelessWidget {
  final bool searching;
  const _Empty({required this.searching});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
    decoration: BoxDecoration(
      color: AppColors.brand.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.brand.withValues(alpha: 0.15)),
    ),
    child: Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.accentGradient(AppColors.brandLight),
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.event_busy_rounded,
            size: 28,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          searching
              ? 'No attendance matches'
              : 'No attendance recorded for this day',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),

      ],
    ),
  );
}
