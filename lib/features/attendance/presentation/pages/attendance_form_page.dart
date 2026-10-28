import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_date_field.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/pill_segmented_control.dart';
import '../../../../shared/widgets/theme_banner.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../../masters/domain/entities/master_item.dart';
import '../../../masters/presentation/cubit/master_cubit.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../data/attendance_remote_datasource.dart';
import '../../domain/attendance.dart';
import '../attendance_providers.dart';
import '../salary_type_visuals.dart';

/// Record (or edit) one employee's attendance for one day, by their salary
/// type: up to three shifts (1/4 … 3 each); work types with quantities, each
/// priced at the work type's rate; hours worked; or a full / half day.
class AttendanceFormPage extends ConsumerStatefulWidget {
  /// The day, "YYYY-MM-DD" (the list page's date).
  final String date;

  /// Today in the company's zone: no later date can be picked.
  final String today;

  /// Editing this record; null = a new one.
  final AttendanceRecord? edit;

  /// Employees already recorded on [date] (they're edited, not re-added).
  final Set<String> recordedEmployeeIds;

  const AttendanceFormPage({
    super.key,
    required this.date,
    required this.today,
    this.edit,
    this.recordedEmployeeIds = const {},
  });

  @override
  ConsumerState<AttendanceFormPage> createState() => _AttendanceFormPageState();
}

/// One work-type line being edited.
class _PieceDraft {
  String? workTypeId;
  final TextEditingController qty;
  _PieceDraft({this.workTypeId, int? quantity})
    : qty = TextEditingController(text: quantity?.toString() ?? '');
}

class _AttendanceFormPageState extends ConsumerState<AttendanceFormPage> {
  final _form = GlobalKey<FormState>();
  final _notes = TextEditingController();
  late DateTime _date = DateTime.parse(widget.date);
  Employee? _employee;
  final List<double> _shifts = [];
  final List<_PieceDraft> _pieces = [];
  final _hours = TextEditingController();
  double _dayUnits = 1;

  /// Marked absent: no shifts, pieces, hours or day — and not paid.
  bool _absent = false;
  bool _saving = false;

  bool get _isEdit => widget.edit != null;
  String get _kind =>
      widget.edit?.kind ?? _employee?.salaryType ?? SalaryType.shift;
  bool get _isShift => _kind == SalaryType.shift;
  bool get _isPiece => _kind == SalaryType.piece;
  bool get _isHourly => _kind == SalaryType.hourly;

  @override
  void initState() {
    super.initState();
    masterCubit.refresh('workType').then((_) {
      if (mounted) setState(() {});
    }, onError: (_) {});
    final r = widget.edit;
    if (r != null) {
      _shifts.addAll(r.shifts);
      for (final p in r.pieces) {
        _pieces.add(
          _PieceDraft(workTypeId: p.workTypeId, quantity: p.quantity),
        );
      }
      if (r.hours != null) _hours.text = hoursLabel(r.hours!);
      _dayUnits = r.dayUnits ?? 1;
      _absent = r.isAbsent;
      _notes.text = r.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _hours.dispose();
    for (final p in _pieces) {
      p.qty.dispose();
    }
    super.dispose();
  }

  /// Fresh lines for the picked employee's salary type.
  void _pickEmployee(Employee? e) {
    setState(() {
      _employee = e;
      _shifts.clear();
      for (final p in _pieces) {
        p.qty.dispose();
      }
      _pieces.clear();
      if (e?.salaryType == SalaryType.shift) _shifts.add(1);
      if (e?.salaryType == SalaryType.piece) _pieces.add(_PieceDraft());
      _hours.text = e?.salaryType == SalaryType.hourly ? '8' : '';
      _dayUnits = 1;
    });
  }

  /// Active work types, plus any already on this record (kept at their old
  /// rate even if made inactive since).
  List<MasterItem> get _workTypes {
    final onRecord = {
      for (final p in widget.edit?.pieces ?? const <PieceLine>[]) p.workTypeId,
    };
    return [
      for (final w in masterCubit.allItemsOfType('workType'))
        if (w.isActive || onRecord.contains(w.id)) w,
    ];
  }

  /// The rate a line is priced at: the record's own for a work type already
  /// on it, else the work type's current rate.
  double _rateOf(String? workTypeId) {
    if (workTypeId == null) return 0;
    final kept = widget.edit?.pieces
        .where((p) => p.workTypeId == workTypeId)
        .firstOrNull;
    if (kept != null) return kept.rate;
    return masterCubit
            .allItemsOfType('workType')
            .where((w) => w.id == workTypeId)
            .firstOrNull
            ?.rate ??
        0;
  }

  double get _totalShifts => _shifts.fold(0, (a, s) => a + s);
  int get _totalPieces =>
      _pieces.fold(0, (a, p) => a + (int.tryParse(p.qty.text) ?? 0));
  double get _totalAmount => _pieces.fold(
    0,
    (a, p) => a + (int.tryParse(p.qty.text) ?? 0) * _rateOf(p.workTypeId),
  );

  /// The salary per shift or per hour (null when the record's amount isn't
  /// priced that way, e.g. the employee's salary type changed since).
  double? get _rate {
    final r = widget.edit;
    if (r != null) {
      return r.totalAmount == null ? null : r.salary;
    }
    return SalaryType.hasAmount(_employee?.salaryType)
        ? _employee?.salary
        : null;
  }

  double? get _hoursValue => double.tryParse(_hours.text.trim());

  /// Present ↔ absent. Back to present starts the work lines afresh if an
  /// absent day had none.
  void _setAbsent(bool absent) => setState(() {
    _absent = absent;
    if (absent) return;
    if (_isShift && _shifts.isEmpty) _shifts.add(1);
    if (_isPiece && _pieces.isEmpty) _pieces.add(_PieceDraft());
    if (_isHourly && _hours.text.trim().isEmpty) _hours.text = '8';
  });

  String? _problem() {
    if (!_isEdit && _employee == null) return 'Pick an employee';
    if (_absent) return null;
    if (_isHourly) {
      final h = _hoursValue;
      if (h == null || h <= 0 || h > kMaxHours) {
        return 'Hours must be more than 0 and at most $kMaxHours';
      }
      if ((h * 4).round() != h * 4) return 'Hours go in quarter hours (7.25)';
    } else if (SalaryType.isDayBased(_kind)) {
      // A full or half day: always set.
    } else if (_isShift) {
      if (_shifts.isEmpty) return 'Add at least one shift';
      if (_shifts.length > kMaxShifts) {
        return 'At most $kMaxShifts shifts can be recorded for one day';
      }
    } else {
      if (_pieces.isEmpty) return 'Add at least one work type';
      final ids = <String>{};
      for (final (i, p) in _pieces.indexed) {
        if (p.workTypeId == null) return 'Line ${i + 1}: pick a work type';
        if (!ids.add(p.workTypeId!)) {
          return 'A work type is listed twice. Add its quantities together';
        }
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final problem = _problem();
    if (problem != null) return _snack(problem);
    setState(() => _saving = true);
    final body = {
      if (!_isEdit) 'employee_id': int.parse(_employee!.id),
      if (!_isEdit) 'work_date': DateFormat('yyyy-MM-dd').format(_date),
      'status': _absent ? 'ABSENT' : 'PRESENT',
      if (_isShift && !_absent)
        'shifts': [
          for (final s in _shifts) {'units': s},
        ],
      if (_isHourly && !_absent) 'hours': _hoursValue,
      if (SalaryType.isDayBased(_kind) && !_absent) 'day_units': _dayUnits,
      if (_isPiece && !_absent)
        'pieces': [
          for (final p in _pieces)
            {'work_type_id': p.workTypeId, 'quantity': int.parse(p.qty.text)},
        ],
      'notes': _notes.text.trim(),
    };
    try {
      final ds = ref.read(attendanceDatasourceProvider);
      _isEdit ? await ds.update(widget.edit!.id, body) : await ds.create(body);
      ref.invalidate(attendanceMonthProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete attendance?'),
        content: Text(
          '${widget.edit!.employeeName} · ${widget.edit!.workDate} will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(attendanceDatasourceProvider).delete(widget.edit!.id);
      ref.invalidate(attendanceMonthProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.dangerFill),
    );
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(moduleAccessProvider('Attendance'));
    final all = ref.watch(employeesProvider).valueOrNull ?? const <Employee>[];
    final active = [
      for (final e in all)
        if (e.status == 'Active') e,
    ];
    final pickable = [
      for (final e in active)
        if (e.salaryType != null && !widget.recordedEmployeeIds.contains(e.id))
          e,
    ];
    final noType = active.where((e) => e.salaryType == null).length;
    final recorded = active
        .where((e) => widget.recordedEmployeeIds.contains(e.id))
        .length;
    final hint = TextStyle(color: AppColors.textHint, fontSize: 11.5);
    final section = TextStyle(
      color: AppColors.ink,
      fontSize: 14,
      fontWeight: FontWeight.w800,
    );
    final showLines = _isEdit || _employee != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit attendance' : 'Record attendance'),
        actions: [
          if (_isEdit && access.delete)
            IconButton(
              tooltip: 'Delete',
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ThemeBanner(
              icon: showLines
                  ? salaryTypeIcon(_kind)
                  : Icons.how_to_reg_rounded,
              title: _isEdit
                  ? widget.edit!.employeeName
                  : _employee?.fullName ?? 'Record attendance',
              subtitle: [
                DateFormat('EEE, d MMM yyyy').format(_date),
                if (showLines) '${SalaryType.label(_kind)} salary',
              ].join(' · '),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              icon: Icons.badge_rounded,
              title: 'Employee & date',
              color: AppColors.brand,
              children: [
                if (_isEdit)
                  _InfoTile(
                    icon: Icons.person_rounded,
                    title: widget.edit!.employeeName,
                    subtitle: [
                      widget.edit!.employeeCode,
                      if (widget.edit!.department != null)
                        widget.edit!.department!,
                      SalaryType.label(widget.edit!.kind),
                    ].join(' · '),
                  )
                else ...[
                  BrixenDropdown<Employee>(
                    hint: 'Employee *',
                    value: _employee,
                    items: pickable,
                    labelOf: (e) => e.fullName,
                    subtitleOf: (e) => [
                      e.employeeCode,
                      if (e.department != null) e.department!,
                      SalaryType.label(e.salaryType),
                    ].join(' · '),
                    icon: Icons.person_search_rounded,
                    onChanged: _pickEmployee,
                  ),
                  if (recorded > 0 || noType > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (recorded > 0)
                          '$recorded already recorded on this day — edit them from the list.',
                        if (noType > 0)
                          '$noType without a salary type — set it in Employees first.',
                      ].join(' '),
                      style: hint,
                    ),
                  ],
                ],
                const SizedBox(height: 18),
                if (_isEdit)
                  _InfoTile(
                    icon: Icons.event_rounded,
                    title: DateFormat('EEE, d MMM yyyy').format(_date),
                    subtitle: 'Recorded ${widget.edit!.recordedLocal}',
                  )
                else
                  BrixenDateField(
                    label: 'Date *',
                    value: _date,
                    onChanged: (d) => setState(() => _date = d),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.parse(widget.today),
                  ),
              ],
            ),
            if (showLines) ...[
              const SizedBox(height: 14),
              // Present (record the work) or absent (nothing to record).
              PillSegmentedControl<bool>(
                value: _absent,
                onChanged: _setAbsent,
                segments: const [
                  PillSegment(
                    value: false,
                    label: 'Present',
                    icon: Icons.how_to_reg_rounded,
                  ),
                  PillSegment(
                    value: true,
                    label: 'Absent',
                    icon: Icons.person_off_outlined,
                  ),
                ],
              ),
            ],
            if (showLines && _absent) ...[
              const SizedBox(height: 14),
              _SectionCard(
                icon: Icons.person_off_outlined,
                title: 'Absent',
                color: AppColors.brandBlack,
                children: [
                  Text(
                    'No shifts, pieces or hours are recorded for an absent '
                    'day, and it isn\'t paid.',
                    style: hint,
                  ),
                ],
              ),
            ],
            if (showLines && !_absent) ...[
              const SizedBox(height: 14),
              _SectionCard(
                icon: salaryTypeIcon(_kind),
                title: switch (_kind) {
                  SalaryType.shift => 'Shifts worked',
                  SalaryType.piece => 'Pieces made',
                  SalaryType.hourly => 'Hours worked',
                  _ => 'Day',
                },
                color: salaryTypeColor(_kind),
                children: [
                  if (_isShift)
                    ..._shiftSection(section, hint)
                  else if (_isPiece)
                    ..._pieceSection(section, hint)
                  else if (_isHourly)
                    ..._hourSection(section, hint)
                  else
                    ..._daySection(section, hint),
                ],
              ),
            ],
            const SizedBox(height: 14),
            _SectionCard(
              icon: Icons.notes_rounded,
              title: 'Notes',
              color: AppColors.brandDeep,
              children: [
                BrixenTextField(
                  label: 'Notes',
                  hint: 'Optional',
                  controller: _notes,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (access.create || (_isEdit && access.edit))
              BrixenButton(
                label: _isEdit ? 'Save changes' : 'Save attendance',
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _shiftSection(TextStyle section, TextStyle hint) => [
    Text(
      'Up to $kMaxShifts a day · each from ¼ to 3, in quarters',
      style: hint,
    ),
    const SizedBox(height: 12),
    for (var i = 0; i < _shifts.length; i++)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Shift ${i + 1}',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${shiftUnitLabel(_shifts[i])} '
                  'shift${_shifts[i] == 1 ? '' : 's'}',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove shift',
                  visualDensity: VisualDensity.compact,
                  onPressed: _shifts.length == 1
                      ? null
                      : () => setState(() => _shifts.removeAt(i)),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // ¼ to 3 in quarters: four a row.
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final u in kShiftUnits)
                  _UnitTile(
                    label: shiftUnitLabel(u),
                    selected: _shifts[i] == u,
                    onTap: () => setState(() => _shifts[i] = u),
                  ),
              ],
            ),
          ],
        ),
      ),
    if (_shifts.length < kMaxShifts)
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _shifts.add(1)),
          icon: const Icon(Icons.add_rounded),
          label: Text('Add shift ${_shifts.length + 1}'),
        ),
      ),
    const SizedBox(height: 8),
    _TotalBar(
      label: 'Day total',
      value:
          '${shiftTotalLabel(_totalShifts)} shift${_totalShifts == 1 ? '' : 's'}',
      amount: _rate == null ? null : _totalShifts * _rate!,
      color: salaryTypeColor(SalaryType.shift),
    ),
  ];

  List<Widget> _hourSection(TextStyle section, TextStyle hint) {
    final color = salaryTypeColor(SalaryType.hourly);
    final h = _hoursValue ?? 0;
    return [
      Text(
        _rate == null
            ? 'Quarter hours, up to $kMaxHours'
            : 'At ${rupeesExact(_rate!)} per hour · quarter hours, up to $kMaxHours',
        style: hint,
      ),
      const SizedBox(height: 12),
      BrixenTextField(
        label: 'Hours *',
        hint: 'e.g. 8 or 7.5',
        controller: _hours,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefixIcon: Icon(salaryTypeIcon(SalaryType.hourly)),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final q in const [4.0, 6.0, 8.0, 9.0, 10.0, 12.0])
            ChoiceChip(
              label: Text('${hoursLabel(q)} h'),
              selected: h == q,
              onSelected: (_) => setState(() => _hours.text = hoursLabel(q)),
              selectedColor: color.withValues(alpha: 0.22),
              labelStyle: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
      const SizedBox(height: 14),
      _TotalBar(
        label: 'Day total',
        value: '${hoursLabel(h)} hour${h == 1 ? '' : 's'}',
        amount: _rate == null ? null : h * _rate!,
        color: color,
      ),
    ];
  }

  List<Widget> _daySection(TextStyle section, TextStyle hint) {
    final color = salaryTypeColor(_kind);
    Widget option(double units, String title, String sub, IconData icon) {
      final on = _dayUnits == units;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _dayUnits = units),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: on
                  ? LinearGradient(colors: AppColors.accentGradient(color))
                  : null,
              color: on ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: on ? Colors.transparent : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: on ? Colors.white : color),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: on ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    color: on
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textHint,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return [
      Text(
        '${SalaryType.label(_kind)} salary · the pay is worked out at salary '
        'generation',
        style: hint,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          option(1, 'Full day', 'Counts 1 day', Icons.wb_sunny_rounded),
          const SizedBox(width: 10),
          option(0.5, 'Half day', 'Counts ½ day', Icons.wb_twilight_rounded),
        ],
      ),
    ];
  }

  List<Widget> _pieceSection(TextStyle section, TextStyle hint) {
    final types = _workTypes;
    return [
      Text(
        types.isEmpty
            ? 'No work types yet — add them in Masters → Work Type.'
            : 'Each work type at its rate per piece',
        style: hint,
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < _pieces.length; i++) ...[
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              BrixenDropdown<MasterItem>(
                hint: 'Work type *',
                value: types
                    .where((w) => w.id == _pieces[i].workTypeId)
                    .firstOrNull,
                // A work type already on another line isn't offered twice.
                items: [
                  for (final w in types)
                    if (w.id == _pieces[i].workTypeId ||
                        !_pieces.any((p) => p.workTypeId == w.id))
                      w,
                ],
                labelOf: (w) => w.name,
                subtitleOf: (w) => '${rupeesExact(w.rate ?? 0)} per piece',
                icon: Icons.content_cut_rounded,
                onChanged: (w) => setState(() => _pieces[i].workTypeId = w?.id),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: BrixenTextField(
                      label: 'Quantity *',
                      hint: 'Pieces done',
                      controller: _pieces[i].qty,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 1) {
                          return 'Whole number, 1 or more';
                        }
                        if (n > 1000000) return 'Too many';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '× ${rupeesExact(_rateOf(_pieces[i].workTypeId))}',
                          style: hint,
                        ),
                        Text(
                          rupeesExact(
                            (int.tryParse(_pieces[i].qty.text) ?? 0) *
                                _rateOf(_pieces[i].workTypeId),
                          ),
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove line',
                    onPressed: _pieces.length == 1
                        ? null
                        : () =>
                              setState(() => _pieces.removeAt(i).qty.dispose()),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
      if (_pieces.length < types.length)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _pieces.add(_PieceDraft())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add work type'),
          ),
        ),
      const SizedBox(height: 8),
      _TotalBar(
        label: 'Day total',
        value: '$_totalPieces piece${_totalPieces == 1 ? '' : 's'}',
        amount: _totalAmount,
        color: salaryTypeColor(SalaryType.piece),
      ),
    ];
  }
}

/// One shift size to pick: filled blue when picked.
class _UnitTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _UnitTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [AppColors.brand, AppColors.brandDeep],
              )
            : null,
        color: selected ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : AppColors.brand.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

/// A titled part of the form, edged and tinted in [color].
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.12), AppColors.surface],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: 0.30)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.accentGradient(color),
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.brand),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// "Day total · 1¾ shifts ............ ₹1,050".
class _TotalBar extends StatelessWidget {
  final String label, value;
  final double? amount;
  final Color color;
  const _TotalBar({
    required this.label,
    required this.value,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: AppColors.accentGradient(color)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (amount != null)
          Text(
            rupeesExact(amount!),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    ),
  );
}
