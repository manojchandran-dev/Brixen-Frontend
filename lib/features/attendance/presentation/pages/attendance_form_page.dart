import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_date_field.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../../masters/domain/entities/master_item.dart';
import '../../../masters/presentation/cubit/master_cubit.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../data/attendance_remote_datasource.dart';
import '../../domain/attendance.dart';
import '../attendance_providers.dart';

/// Record (or edit) one employee's attendance for one day. A shift-rate
/// employee gets up to three shifts (1/4 … 3 each); a piece-rate employee
/// gets work types with quantities, each priced at the work type's rate.
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
  bool _saving = false;

  bool get _isEdit => widget.edit != null;
  String get _kind =>
      widget.edit?.kind ?? _employee?.salaryType ?? SalaryType.shift;
  bool get _isShift => _kind == SalaryType.shift;

  @override
  void initState() {
    super.initState();
    masterCubit.ensureLoaded('workType').then((_) {
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
      _notes.text = r.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notes.dispose();
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

  /// Pay for the day for a shift-rate employee paid daily.
  double? get _shiftPay {
    final period = widget.edit?.salaryPeriod ?? _employee?.salaryPeriod;
    final salary = widget.edit?.salary ?? _employee?.salary;
    if (period != 'DAILY' || salary == null) return null;
    return _totalShifts * salary;
  }

  String? _problem() {
    if (!_isEdit && _employee == null) return 'Pick an employee';
    if (_isShift) {
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
      if (_isShift)
        'shifts': [
          for (final s in _shifts) {'units': s},
        ],
      if (!_isShift)
        'pieces': [
          for (final p in _pieces)
            {'work_type_id': p.workTypeId, 'quantity': int.parse(p.qty.text)},
        ],
      'notes': _notes.text.trim(),
    };
    try {
      final ds = ref.read(attendanceDatasourceProvider);
      _isEdit ? await ds.update(widget.edit!.id, body) : await ds.create(body);
      ref.invalidate(attendanceDayProvider);
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
      ref.invalidate(attendanceDayProvider);
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (_isEdit)
              _InfoTile(
                icon: Icons.person_rounded,
                title: widget.edit!.employeeName,
                subtitle: [
                  widget.edit!.employeeCode,
                  if (widget.edit!.department != null) widget.edit!.department!,
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
            if (showLines) ...[
              const SizedBox(height: 24),
              if (_isShift)
                ..._shiftSection(section, hint)
              else
                ..._pieceSection(section, hint),
            ],
            const SizedBox(height: 20),
            BrixenTextField(
              label: 'Notes',
              hint: 'Optional',
              controller: _notes,
              maxLines: 2,
              prefixIcon: const Icon(Icons.notes_rounded),
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
    Text('Shifts', style: section),
    Text(
      'Up to $kMaxShifts a day · each 1/4, 1/2, 3/4, 1, 2 or 3',
      style: hint,
    ),
    const SizedBox(height: 12),
    for (var i = 0; i < _shifts.length; i++)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(
                'Shift ${i + 1}',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final u in kShiftUnits)
                    ChoiceChip(
                      label: Text(shiftUnitLabel(u)),
                      selected: _shifts[i] == u,
                      onSelected: (_) => setState(() => _shifts[i] = u),
                      selectedColor: AppColors.brand.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: _shifts[i] == u
                            ? AppColors.brand
                            : AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove shift',
              onPressed: _shifts.length == 1
                  ? null
                  : () => setState(() => _shifts.removeAt(i)),
              icon: const Icon(Icons.remove_circle_outline_rounded),
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
      amount: _shiftPay,
      color: AppColors.brand,
    ),
  ];

  List<Widget> _pieceSection(TextStyle section, TextStyle hint) {
    final types = _workTypes;
    return [
      Text('Work done', style: section),
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
        color: AppColors.positive,
      ),
    ];
  }
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
