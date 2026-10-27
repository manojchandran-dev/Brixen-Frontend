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

/// Company admins record and review attendance, one day at a time (the
/// company's own date, in its time zone). Search by name or code, filter
/// shift or piece workers, and see the day's totals.
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  /// null = today in the company's zone (the server decides).
  String? _date;
  String _search = '';
  String? _kind;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  AttendanceQuery get _query => (date: _date, search: _search, kind: _kind);

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  static final _fmt = DateFormat('yyyy-MM-dd');

  void _shiftDay(String current, String today, int days) {
    final next = DateTime.parse(current).add(Duration(days: days));
    if (_fmt.format(next).compareTo(today) > 0) return;
    setState(() => _date = _fmt.format(next));
  }

  Future<void> _pickDay(String current, String today) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(current),
      firstDate: DateTime(2000),
      lastDate: DateTime.parse(today),
    );
    if (picked != null) setState(() => _date = _fmt.format(picked));
  }

  Future<void> _openForm(
    AttendanceList day,
    String current, {
    AttendanceRecord? edit,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AttendanceFormPage(
          date: current,
          today: day.today,
          edit: edit,
          recordedEmployeeIds: {for (final r in day.items) r.employeeId},
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
    final async = ref.watch(attendanceDayProvider(_query));
    final day = async.valueOrNull;
    final current = _date ?? day?.today;

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
          subtitle: day == null
              ? 'Shifts & pieces per day'
              : 'Times in ${day.timezone}',
        ),
        actions: [
          IconButton(
            tooltip: 'Company time zone',
            onPressed: day == null ? null : () => _changeTimezone(day.timezone),
            icon: const Icon(Icons.public_rounded),
          ),
          if (access.create && day != null && current != null)
            IconButton(
              tooltip: 'Record attendance',
              onPressed: () => _openForm(day, current),
              icon: const Icon(Icons.add_circle_rounded, size: 28),
              color: AppColors.brand,
            ),
        ],
      ),
      body: Column(
        children: [
          if (current != null && day != null)
            _DayBar(
              date: current,
              isToday: current == day.today,
              onPrev: () => _shiftDay(current, day.today, -1),
              onNext: current == day.today
                  ? null
                  : () => _shiftDay(current, day.today, 1),
              onPick: () => _pickDay(current, day.today),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchField(
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: PillSegmentedControl<String>(
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
          ),
          Expanded(
            child: async.when(
              skipError: true,
              loading: () => const SkeletonListView(),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(attendanceDayProvider(_query)),
              ),
              data: (list) => RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(attendanceDayProvider(_query).future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                  children: [
                    _DaySummary(list.items),
                    const SizedBox(height: 12),
                    if (list.items.isEmpty)
                      _Empty(
                        searching: _search.isNotEmpty || _kind != null,
                        canCreate: access.create,
                        onCreate: () => _openForm(list, current ?? list.today),
                      )
                    else
                      for (final r in list.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AttendanceCard(
                            record: r,
                            onTap: access.edit || access.delete
                                ? () => _openForm(
                                    list,
                                    current ?? list.today,
                                    edit: r,
                                  )
                                : null,
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      _date = null; // "today" may be a different date in the new zone
      ref.invalidate(attendanceDayProvider);
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

/// ‹  Tue, 27 Oct 2026 · Today  ›
class _DayBar extends StatelessWidget {
  final String date;
  final bool isToday;
  final VoidCallback onPrev, onPick;
  final VoidCallback? onNext;
  const _DayBar({
    required this.date,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Previous day',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPick,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_rounded, size: 18, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEE, d MMM yyyy').format(DateTime.parse(date)),
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
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
                ],
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next day',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    ),
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
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Icon(Icons.event_busy_rounded, size: 46, color: AppColors.textHint),
        const SizedBox(height: 10),
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
