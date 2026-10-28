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
import '../../../attendance/presentation/salary_type_visuals.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../../masters/domain/entities/master_item.dart';
import '../../../masters/presentation/cubit/master_cubit.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../data/payroll_remote_datasource.dart';
import '../../domain/piece_pay.dart';
import '../../domain/salary_summary.dart';
import '../payroll_providers.dart';
import '../widgets/salary_summary_widgets.dart';

final _ym = DateFormat('yyyy-MM');
final _ymd = DateFormat('yyyy-MM-dd');

void _snack(BuildContext context, String text, {bool error = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: error ? AppColors.dangerFill : null,
    ),
  );
}

/// Salary → Piece rate: a month's piece pays (entered after sales), with
/// totals and "Add piece pay". Tap one to confirm, email or change it.
class PiecePayView extends ConsumerWidget {
  final DateTime month;
  const PiecePayView({super.key, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(moduleAccessProvider('Employees'));
    final key = _ym.format(month);
    final async = ref.watch(piecePaysMonthProvider(key));
    final sold = ref.watch(salesByDayProvider(key)).valueOrNull;
    final summary = ref.watch(salarySummaryProvider(key)).valueOrNull;
    final items = async.valueOrNull ?? const <PiecePay>[];
    final total = items.fold<double>(0, (a, p) => a + p.amount);
    final pieces = items.fold<int>(0, (a, p) => a + p.pieces);
    final drafts = items.where((p) => !p.isConfirmed).length;

    Future<void> open(PiecePay p) => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PiecePayDetailPage(pay: p)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final (i, s) in [
              BannerStat('${items.length}', 'entries', AppColors.brand),
              BannerStat(
                NumberFormat.decimalPattern('en_IN').format(pieces),
                'pieces',
                AppColors.brandBlack,
              ),
              BannerStat(
                rupees(total),
                'to pay',
                AppColors.positiveDeep,
                exact: total,
              ),
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _Stat(s)),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'After a sale, add what each piece-rate employee did: the work '
          'type (its rate per piece) × quantity — in pieces or in combos of a '
          'product. Confirm it, then email the payslip.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
        if (access.create) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PiecePayFormPage())),
            style: FilledButton.styleFrom(
              backgroundColor: salaryTypeColor(SalaryType.piece),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add piece pay',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
        // Enter piece pay from what sold, day by day.
        if (sold != null) ...[
          const SizedBox(height: 14),
          SalesByDayList(
            lines: sold,
            onPick: access.create
                ? (l) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PiecePayFormPage(sold: l),
                    ),
                  )
                : null,
          ),
        ],
        if (drafts > 0) ...[
          const SizedBox(height: 10),
          Text(
            '$drafts not confirmed yet — tap one to confirm it.',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 14),
        async.when(
          skipError: true,
          loading: () => const Shimmer(
            child: SkeletonBox(width: double.infinity, height: 120),
          ),
          error: (e, _) => ErrorCard(
            error: e,
            onRetry: () => ref.invalidate(piecePaysMonthProvider(key)),
          ),
          data: (list) => list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No piece pay for ${DateFormat('MMMM').format(month)} yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : Column(
                  children: [
                    for (final p in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PiecePayTile(pay: p, onTap: () => open(p)),
                      ),
                  ],
                ),
        ),
        // Each piece-rate employee's pieces and pay this month.
        if (summary != null) ...[
          const SizedBox(height: 6),
          EmployeeWorkList(
            title: 'Each piece-rate employee',
            caption: 'Pieces and piece pay this month',
            items: [
              for (final e in summary.items)
                if (e.salaryType == SalaryType.piece) e,
            ],
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final BannerStat s;
  const _Stat(this.s);

  @override
  Widget build(BuildContext context) => ExactAmount(
    amount: s.exact,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            s.tone.withValues(alpha: 0.16),
            s.tone.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              s.value,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            s.label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

/// A piece pay in a list: who, the work and quantity, the amount, and
/// whether it's confirmed / emailed. [showEmployee] false on an employee's
/// own list.
class PiecePayTile extends StatelessWidget {
  final PiecePay pay;
  final VoidCallback onTap;
  final bool showEmployee;
  const PiecePayTile({
    super.key,
    required this.pay,
    required this.onTap,
    this.showEmployee = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = pay;
    final color = salaryTypeColor(SalaryType.piece);
    final day = DateTime.tryParse(p.payDate);
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
                color.withValues(alpha: 0.18),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.accentGradient(color),
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  day == null ? '' : '${day.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showEmployee ? p.employeeName : p.workTypeName,
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
                        if (showEmployee) p.workTypeName,
                        '${p.pieces} pcs × ${rupeesExact(p.rate)}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusPill(p),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ExactAmount(
                amount: p.amount,
                child: Text(
                  rupees(p.amount),
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

class _StatusPill extends StatelessWidget {
  final PiecePay p;
  const _StatusPill(this.p);

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = p.isConfirmed
        ? (
            p.emailedAt != null ? 'Confirmed · emailed' : 'Confirmed',
            Icons.verified_rounded,
            AppColors.positiveDeep,
          )
        : ('To confirm', Icons.edit_note_rounded, AppColors.brandLight);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.accentGradient(color)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// One piece pay: the working and, for whoever may, its actions — a draft
/// can be confirmed, edited or deleted; a confirmed one emailed or opened to
/// change again. [readOnly] for an employee's own view.
class PiecePayDetailPage extends ConsumerStatefulWidget {
  final PiecePay pay;
  final bool readOnly;
  const PiecePayDetailPage({
    super.key,
    required this.pay,
    this.readOnly = false,
  });

  @override
  ConsumerState<PiecePayDetailPage> createState() => _PiecePayDetailPageState();
}

class _PiecePayDetailPageState extends ConsumerState<PiecePayDetailPage> {
  late PiecePay _pay = widget.pay;
  bool _busy = false;

  Future<void> _act(String action, String done) async {
    setState(() => _busy = true);
    try {
      final next = await ref
          .read(payrollDatasourceProvider)
          .piecePayAction(_pay.id, action);
      refreshPiecePays(ref);
      if (!mounted) return;
      setState(() => _pay = next);
      _snack(context, done, error: false);
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete this piece pay?'),
        content: Text('${_pay.employeeName} · ${rupees(_pay.amount)}'),
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
    setState(() => _busy = true);
    try {
      await ref.read(payrollDatasourceProvider).deletePiecePay(_pay.id);
      refreshPiecePays(ref);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(moduleAccessProvider('Employees'));
    final p = _pay;
    final day = DateTime.tryParse(p.payDate);
    Widget line(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Piece pay')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          ThemeBanner(
            icon: Icons.content_cut_rounded,
            title: p.employeeName,
            subtitle: [
              p.employeeCode,
              if (day != null) DateFormat('d MMM yyyy').format(day),
            ].join(' · '),
            stats: [
              BannerStat(
                rupees(p.amount),
                'pay',
                AppColors.positive,
                exact: p.amount,
              ),
              BannerStat(
                p.isConfirmed ? 'Confirmed' : 'To confirm',
                'status',
                p.isConfirmed ? AppColors.positive : AppColors.brand,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                line('Work', p.workTypeName),
                line('Quantity', p.quantityLabel),
                line('Rate', '${rupeesExact(p.rate)} per piece'),
                Divider(color: AppColors.border, height: 18),
                line(
                  'Pay',
                  '${p.pieces} × ${rupeesExact(p.rate)} = '
                      '${rupeesExact(p.amount)}',
                  strong: true,
                ),
                if (p.notes?.isNotEmpty ?? false) line('Note', p.notes!),
                if (p.emailedAt != null)
                  line(
                    'Emailed',
                    DateFormat(
                      'd MMM yyyy, h:mm a',
                    ).format(p.emailedAt!.toLocal()),
                  ),
                if (p.emailError != null) line('Email failed', p.emailError!),
              ],
            ),
          ),
          if (!widget.readOnly) ...[
            const SizedBox(height: 20),
            if (!p.isConfirmed) ...[
              if (access.create)
                BrixenButton(
                  label: 'Confirm',
                  isLoading: _busy,
                  onPressed: _busy
                      ? null
                      : () => _act('confirm', 'Piece pay confirmed'),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (access.edit)
                    Expanded(
                      child: BrixenButton(
                        label: 'Edit',
                        isOutlined: true,
                        onPressed: _busy
                            ? null
                            : () async {
                                final saved = await Navigator.of(context)
                                    .push<PiecePay>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PiecePayFormPage(edit: p),
                                      ),
                                    );
                                if (saved != null && mounted) {
                                  setState(() => _pay = saved);
                                }
                              },
                      ),
                    ),
                  if (access.edit && access.delete) const SizedBox(width: 10),
                  if (access.delete)
                    Expanded(
                      child: BrixenButton(
                        label: 'Delete',
                        isOutlined: true,
                        onPressed: _busy ? null : _delete,
                      ),
                    ),
                ],
              ),
            ] else ...[
              if (access.create)
                p.email == null
                    ? Text(
                        'No email address for ${p.employeeName} — add one in '
                        'Employees to send it.',
                        style: TextStyle(color: AppColors.textHint),
                      )
                    : BrixenButton(
                        label: p.emailedAt == null
                            ? 'Email payslip'
                            : 'Email payslip again',
                        isLoading: _busy,
                        onPressed: _busy
                            ? null
                            : () => _act('send', 'Emailed to ${p.email}'),
                      ),
              if (access.edit) ...[
                const SizedBox(height: 10),
                BrixenButton(
                  label: 'Edit again',
                  isOutlined: true,
                  onPressed: _busy
                      ? null
                      : () => _act('reopen', 'Open to change again'),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

/// Add or edit a piece pay: employee (piece rate), work type (its rate),
/// pieces or combos of a product, the date — with the working as you type.
/// Pops the saved [PiecePay]. [sold]: start from a product sold that day
/// (its date, quantity, and product when sold in combos).
class PiecePayFormPage extends ConsumerStatefulWidget {
  final PiecePay? edit;
  final SoldLine? sold;
  const PiecePayFormPage({super.key, this.edit, this.sold});

  @override
  ConsumerState<PiecePayFormPage> createState() => _PiecePayFormPageState();
}

class _PiecePayFormPageState extends ConsumerState<PiecePayFormPage> {
  final _form = GlobalKey<FormState>();
  late final _qty = TextEditingController(
    text:
        widget.edit?.quantity.toString() ??
        (widget.sold == null
            ? ''
            : '${widget.sold!.isCombo ? widget.sold!.quantity : widget.sold!.pieces}'),
  );
  late final _notes = TextEditingController(
    text:
        widget.edit?.notes ??
        (widget.sold == null ? '' : 'Sold: ${widget.sold!.productName}'),
  );
  late String? _employeeId = widget.edit?.employeeId;
  late String? _workTypeId = widget.edit?.workTypeId;
  late String? _productId =
      widget.edit?.productId ??
      (widget.sold?.isCombo ?? false ? widget.sold!.productId : null);
  late bool _combo = widget.edit?.isCombo ?? widget.sold?.isCombo ?? false;
  late DateTime _date = widget.edit != null
      ? DateTime.parse(widget.edit!.payDate)
      : widget.sold != null
      ? DateTime.parse(widget.sold!.date)
      : DateTime.now();
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

  /// Active work types, plus this entry's own even if made inactive since.
  List<MasterItem> get _workTypes => [
    for (final w in masterCubit.allItemsOfType('workType'))
      if (w.isActive || w.id == widget.edit?.workTypeId) w,
  ];

  /// The entry's rate when its work type is unchanged, else the work type's.
  double get _rate {
    final e = widget.edit;
    if (e != null && e.workTypeId == _workTypeId) return e.rate;
    return _workTypes.where((w) => w.id == _workTypeId).firstOrNull?.rate ?? 0;
  }

  int get _quantity => int.tryParse(_qty.text.trim()) ?? 0;

  Future<void> _save(List<Product> combos) async {
    if (!_form.currentState!.validate()) return;
    if (_employeeId == null) return _snack(context, 'Pick an employee');
    if (_workTypeId == null) return _snack(context, 'Pick a work type');
    if (_combo && _productId == null) {
      return _snack(context, 'Pick the product sold in combos');
    }
    setState(() => _saving = true);
    try {
      final saved = await ref.read(payrollDatasourceProvider).savePiecePay({
        'employee_id': int.parse(_employeeId!),
        'work_type_id': _workTypeId,
        'pay_date': _ymd.format(_date),
        'unit': _combo ? PiecePay.combo : PiecePay.piece,
        'quantity': _quantity,
        if (_combo) 'product_id': _productId,
        'notes': _notes.text.trim(),
      }, id: widget.edit?.id);
      refreshPiecePays(ref);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = [
      for (final e
          in ref.watch(employeesProvider).valueOrNull ?? const <Employee>[])
        if (e.salaryType == SalaryType.piece &&
            (e.status == 'Active' || e.id == widget.edit?.employeeId))
          e,
    ]..sort((a, b) => a.fullName.compareTo(b.fullName));
    final combos = [
      for (final p
          in ref.watch(productsProvider).valueOrNull ?? const <Product>[])
        if ((p.comboSize ?? 0) > 0) p,
    ];
    final product = combos.where((p) => p.id == _productId).firstOrNull;
    final comboSize = _combo
        ? (product?.comboSize ?? widget.edit?.comboSize ?? 0)
        : 1;
    final pieces = _quantity * comboSize;
    final amount = pieces * _rate;
    final types = _workTypes;
    final hint = TextStyle(color: AppColors.textHint, fontSize: 11.5);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit piece pay' : 'Add piece pay')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            BrixenDropdown<Employee>(
              hint: 'Employee (piece rate) *',
              value: employees.where((e) => e.id == _employeeId).firstOrNull,
              items: employees,
              labelOf: (e) => e.fullName,
              subtitleOf: (e) => e.employeeCode,
              icon: Icons.person_search_rounded,
              onChanged: (e) => setState(() => _employeeId = e?.id),
            ),
            if (employees.isEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'No piece-rate employees yet — set an employee\'s salary type '
                'to Piece Rate in Employees.',
                style: hint,
              ),
            ],
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
            PillSegmentedControl<bool>(
              value: _combo,
              onChanged: (c) => setState(() => _combo = c),
              segments: const [
                PillSegment(
                  value: false,
                  label: 'Pieces',
                  icon: Icons.checkroom_rounded,
                ),
                PillSegment(
                  value: true,
                  label: 'Combos',
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            ),
            if (_combo) ...[
              const SizedBox(height: 14),
              BrixenDropdown<Product>(
                hint: 'Product (sold in combos) *',
                value: product,
                items: combos,
                labelOf: (p) => p.productName,
                subtitleOf: (p) => '${p.comboSize} pieces a combo',
                icon: Icons.inventory_2_outlined,
                onChanged: (p) => setState(() => _productId = p?.id),
              ),
              if (combos.isEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'No combo products yet — set "Sold as: Combo" on a product.',
                  style: hint,
                ),
              ],
            ],
            const SizedBox(height: 14),
            BrixenTextField(
              label: _combo ? 'Combos *' : 'Pieces *',
              hint: _combo ? 'e.g. 10' : 'e.g. 250',
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
            BrixenDateField(
              label: 'Date *',
              value: _date,
              onChanged: (d) => setState(() => _date = d),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            ),
            const SizedBox(height: 14),
            // The working: 10 combos × 12 = 120 pieces × ₹0.50 = ₹60.
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
                      if (_combo)
                        '$_quantity combos × $comboSize = $pieces pieces'
                      else
                        '$pieces pieces',
                      '× ${rupeesExact(_rate)}',
                    ].join(' '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
            const SizedBox(height: 14),
            BrixenTextField(
              label: 'Note',
              hint: 'Optional, e.g. the sale or bill no.',
              controller: _notes,
              maxLines: 2,
              prefixIcon: const Icon(Icons.notes_rounded),
            ),
            const SizedBox(height: 24),
            BrixenButton(
              label: _isEdit ? 'Save changes' : 'Save piece pay',
              isLoading: _saving,
              onPressed: _saving ? null : () => _save(combos),
            ),
          ],
        ),
      ),
    );
  }
}
