import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_date_field.dart';
import '../../../../shared/widgets/brixen_dropdown.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/exact_amount.dart';
import '../../../../shared/widgets/pill_segmented_control.dart';
import '../../../../shared/widgets/skeleton.dart';
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

final _ym = DateFormat('yyyy-MM');
final _ymd = DateFormat('yyyy-MM-dd');

/// Lots: piece work counted once a lot is delivered rather than day by day
/// (e.g. 800 dozen × 12 × ₹0.40). A month's deliveries with their totals;
/// salary generation pays each lot in the period of its delivery date.
class LotsPage extends ConsumerStatefulWidget {
  const LotsPage({super.key});

  @override
  ConsumerState<LotsPage> createState() => _LotsPageState();
}

class _LotsPageState extends ConsumerState<LotsPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrent =>
      _ym.format(_month) ==
      _ym.format(DateTime(DateTime.now().year, DateTime.now().month));

  Future<void> _open({PieceLot? edit}) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => LotFormPage(edit: edit)));
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(edit == null ? 'Lot saved' : 'Lot updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(moduleAccessProvider('Attendance'));
    final month = _ym.format(_month);
    final async = ref.watch(lotsMonthProvider(month));
    final lots = async.valueOrNull ?? const <PieceLot>[];
    final pieces = lots.fold<int>(0, (a, l) => a + l.pieces);
    final amount = lots.fold<double>(0, (a, l) => a + l.amount);

    Widget arrow(IconData icon, VoidCallback? onTap) => Opacity(
      opacity: onTap == null ? 0.35 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lots delivered'),
        actions: [
          if (access.create)
            IconButton(
              tooltip: 'Add a lot',
              onPressed: () => _open(),
              icon: const Icon(Icons.add_circle_rounded, size: 28),
              color: AppColors.brand,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(lotsMonthProvider(month).future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            ThemeBanner(
              icon: Icons.local_shipping_rounded,
              title: DateFormat('MMMM yyyy').format(_month),
              subtitle: 'Piece work counted at delivery',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  arrow(
                    Icons.chevron_left_rounded,
                    () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  arrow(
                    Icons.chevron_right_rounded,
                    _isCurrent
                        ? null
                        : () => setState(
                            () => _month = DateTime(
                              _month.year,
                              _month.month + 1,
                            ),
                          ),
                  ),
                ],
              ),
              stats: [
                BannerStat('${lots.length}', 'lots', AppColors.brand),
                BannerStat(
                  NumberFormat.decimalPattern('en_IN').format(pieces),
                  'pieces',
                  AppColors.brandBlack,
                ),
                BannerStat(
                  rupees(amount),
                  'to pay',
                  AppColors.positive,
                  exact: amount,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'When pieces are counted only after the whole lot is delivered, '
              'add it here — e.g. 800 dozen × 12 × ₹0.40. Salary generation '
              'pays it in the week or month of its delivery date.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            async.when(
              skipError: true,
              loading: () => const Shimmer(
                child: SkeletonBox(width: double.infinity, height: 140),
              ),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(lotsMonthProvider(month)),
              ),
              data: (items) => items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        'No lots delivered this month',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : Column(
                      children: [
                        for (final l in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: LotCard(
                              lot: l,
                              onTap: access.edit || access.delete
                                  ? () => _open(edit: l)
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

/// One lot: who, the work type, "800 dozen (9,600 pieces) × ₹0.40", the
/// amount and the delivery date. [showEmployee] false on an employee's own
/// list.
class LotCard extends StatelessWidget {
  final PieceLot lot;
  final bool showEmployee;
  final VoidCallback? onTap;
  const LotCard({
    super.key,
    required this.lot,
    this.showEmployee = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = lot;
    final color = salaryTypeColor(SalaryType.piece);
    final day = DateTime.tryParse(l.lotDate);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.45)),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.20),
                color.withValues(alpha: 0.06),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.accentGradient(color),
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showEmployee ? l.employeeName : l.workTypeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      [
                        if (showEmployee) l.workTypeName,
                        if (day != null) DateFormat('d MMM yyyy').format(day),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${l.quantityLabel} × ${rupeesExact(l.rate)}',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ExactAmount(
                amount: l.amount,
                child: Text(
                  rupees(l.amount),
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add or edit a lot: employee, delivery date, work type, and the quantity
/// in dozens or pieces — with the working shown as you type.
class LotFormPage extends ConsumerStatefulWidget {
  final PieceLot? edit;
  const LotFormPage({super.key, this.edit});

  @override
  ConsumerState<LotFormPage> createState() => _LotFormPageState();
}

class _LotFormPageState extends ConsumerState<LotFormPage> {
  final _form = GlobalKey<FormState>();
  late final _qty = TextEditingController(
    text: widget.edit?.quantity.toString() ?? '',
  );
  late final _notes = TextEditingController(text: widget.edit?.notes ?? '');
  Employee? _employee;
  late String? _workTypeId = widget.edit?.workTypeId;
  late String _unit = widget.edit?.unit ?? PieceLot.dozen;
  late DateTime _date = widget.edit == null
      ? DateTime.now()
      : DateTime.parse(widget.edit!.lotDate);
  bool _saving = false;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    masterCubit.refresh('workType').then((_) {
      if (mounted) setState(() {});
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _qty.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Active work types, plus this lot's own even if made inactive since.
  List<MasterItem> get _workTypes => [
    for (final w in masterCubit.allItemsOfType('workType'))
      if (w.isActive || w.id == widget.edit?.workTypeId) w,
  ];

  /// The lot's rate when its work type is unchanged, else the work type's.
  double get _rate {
    final e = widget.edit;
    if (e != null && e.workTypeId == _workTypeId) return e.rate;
    return _workTypes.where((w) => w.id == _workTypeId).firstOrNull?.rate ?? 0;
  }

  int get _quantity => int.tryParse(_qty.text.trim()) ?? 0;
  int get _pieces => _unit == PieceLot.dozen ? _quantity * 12 : _quantity;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.dangerFill),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_isEdit && _employee == null) return _snack('Pick an employee');
    if (_workTypeId == null) return _snack('Pick a work type');
    setState(() => _saving = true);
    try {
      await ref.read(attendanceDatasourceProvider).saveLot({
        if (!_isEdit) 'employee_id': int.parse(_employee!.id),
        'lot_date': _ymd.format(_date),
        'work_type_id': _workTypeId,
        'unit': _unit,
        'quantity': _quantity,
        'notes': _notes.text.trim(),
      }, id: widget.edit?.id);
      ref.invalidate(lotsMonthProvider);
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
        title: const Text('Delete this lot?'),
        content: Text(
          '${widget.edit!.employeeName} · ${widget.edit!.quantityLabel} will '
          'be removed.',
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
      await ref.read(attendanceDatasourceProvider).deleteLot(widget.edit!.id);
      ref.invalidate(lotsMonthProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(moduleAccessProvider('Attendance'));
    final employees =
        [
          for (final e
              in ref.watch(employeesProvider).valueOrNull ?? const <Employee>[])
            if (e.status == 'Active') e,
        ]..sort((a, b) {
          // Piece-rate staff first: lots are mostly theirs.
          final pa = a.salaryType == SalaryType.piece ? 0 : 1;
          final pb = b.salaryType == SalaryType.piece ? 0 : 1;
          return pa != pb ? pa - pb : a.fullName.compareTo(b.fullName);
        });
    final types = _workTypes;
    final amount = _pieces * _rate;
    final hint = TextStyle(color: AppColors.textHint, fontSize: 11.5);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit lot' : 'Add a lot'),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (_isEdit)
              ThemeBanner(
                icon: Icons.person_rounded,
                title: widget.edit!.employeeName,
                subtitle: widget.edit!.employeeCode,
              )
            else
              BrixenDropdown<Employee>(
                hint: 'Employee *',
                value: _employee,
                items: employees,
                labelOf: (e) => e.fullName,
                subtitleOf: (e) => [
                  e.employeeCode,
                  SalaryType.label(e.salaryType),
                ].join(' · '),
                icon: Icons.person_search_rounded,
                onChanged: (e) => setState(() => _employee = e),
              ),
            const SizedBox(height: 18),
            BrixenDateField(
              label: 'Delivery date *',
              value: _date,
              onChanged: (d) => setState(() => _date = d),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            ),
            const SizedBox(height: 18),
            BrixenDropdown<MasterItem>(
              hint: 'Work type *',
              value: types.where((w) => w.id == _workTypeId).firstOrNull,
              items: types,
              labelOf: (w) => w.name,
              subtitleOf: (w) => '${rupeesExact(w.rate ?? 0)} per piece',
              icon: Icons.content_cut_rounded,
              onChanged: (w) => setState(() => _workTypeId = w?.id),
            ),
            if (types.isEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'No work types yet — add them in Masters → Work Type.',
                style: hint,
              ),
            ],
            const SizedBox(height: 18),
            PillSegmentedControl<String>(
              value: _unit,
              onChanged: (u) => setState(() => _unit = u),
              segments: const [
                PillSegment(
                  value: PieceLot.dozen,
                  label: 'Dozens',
                  icon: Icons.grid_view_rounded,
                ),
                PillSegment(
                  value: PieceLot.piece,
                  label: 'Pieces',
                  icon: Icons.checkroom_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            BrixenTextField(
              label: _unit == PieceLot.dozen ? 'Dozens *' : 'Pieces *',
              hint: _unit == PieceLot.dozen ? 'e.g. 800' : 'e.g. 9600',
              controller: _qty,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.numbers_rounded),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 1) return 'Whole number, 1 or more';
                if (n > 1000000) return 'Too many';
                return null;
              },
            ),
            const SizedBox(height: 14),
            // The working: 800 dozen × 12 = 9,600 pieces × ₹0.40 = ₹3,840.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: kThemeSweepGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (_unit == PieceLot.dozen)
                        '$_quantity dozen × 12 = $_pieces pieces'
                      else
                        '$_pieces pieces',
                      '× ${rupeesExact(_rate)}',
                    ].join(' '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rupeesExact(amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            BrixenTextField(
              label: 'Notes',
              hint: 'Optional, e.g. lot or invoice no.',
              controller: _notes,
              maxLines: 2,
              prefixIcon: const Icon(Icons.notes_rounded),
            ),
            const SizedBox(height: 24),
            if (_isEdit ? access.edit : access.create)
              BrixenButton(
                label: _isEdit ? 'Save changes' : 'Save lot',
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
          ],
        ),
      ),
    );
  }
}
