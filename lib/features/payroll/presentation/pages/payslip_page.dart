import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/brixen_button.dart';
import '../../../../shared/widgets/brixen_text_field.dart';
import '../../../attendance/domain/attendance.dart';
import '../../../attendance/presentation/salary_type_visuals.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../data/payroll_remote_datasource.dart';
import '../../domain/payroll.dart';
import '../payroll_providers.dart';

/// One payslip. Admins may adjust a draft's additions, deductions and note
/// ([canEdit]) or email a finalized one ([canSend]); employees just read
/// theirs. Pops true when something changed.
class PayslipPage extends ConsumerStatefulWidget {
  final Payslip payslip;
  final bool canEdit;
  final bool canSend;
  const PayslipPage({
    super.key,
    required this.payslip,
    this.canEdit = false,
    this.canSend = false,
  });

  @override
  ConsumerState<PayslipPage> createState() => _PayslipPageState();
}

class _PayslipPageState extends ConsumerState<PayslipPage> {
  late Payslip _slip = widget.payslip;
  late final _additions = TextEditingController(text: _plain(_slip.additions));
  late final _deductions = TextEditingController(
    text: _plain(_slip.deductions),
  );
  late final _notes = TextEditingController(text: _slip.notes ?? '');
  bool _busy = false;
  bool _changed = false;

  static String _plain(double v) => v == 0
      ? ''
      : v % 1 == 0
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(2);

  double _amount(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  bool get _editable => widget.canEdit && !_slip.isFinalized;

  @override
  void dispose() {
    _additions.dispose();
    _deductions.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final add = _amount(_additions), ded = _amount(_deductions);
    if (add < 0 || ded < 0) return _snack('Amounts must be 0 or more');
    if (ded > _slip.gross + add) {
      return _snack("Deductions can't be more than the pay");
    }
    setState(() => _busy = true);
    try {
      final saved = await ref
          .read(payrollDatasourceProvider)
          .updatePayslip(
            _slip.id,
            additions: add,
            deductions: ded,
            notes: _notes.text.trim(),
          );
      refreshPayroll(ref, _slip.runId);
      if (!mounted) return;
      setState(() {
        _slip = saved;
        _changed = true;
      });
      _snack('Payslip saved', error: false);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      final r = await ref
          .read(payrollDatasourceProvider)
          .send(_slip.runId, payslipIds: [_slip.id]);
      refreshPayroll(ref, _slip.runId);
      _changed = true;
      if (r.sent > 0) {
        _snack('Payslip emailed to ${_slip.email}', error: false);
      } else {
        _snack([...r.skipped, ...r.failed].join('\n'));
      }
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.dangerFill : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final add = _editable ? _amount(_additions) : _slip.additions;
    final ded = _editable ? _amount(_deductions) : _slip.deductions;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Payslip · ${monthLabel(_slip.month)}')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            PayslipView(slip: _slip, additions: add, deductions: ded),
            if (_editable) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.positive.withValues(alpha: 0.16),
                      AppColors.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.positiveDeep.withValues(alpha: 0.35),
                  ),
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
                              colors: AppColors.accentGradient(
                                AppColors.positiveDeep,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Adjust pay',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bonus or allowance to add, advance or other amounts to take off.',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: BrixenTextField(
                            label: 'Additions',
                            hint: '0',
                            controller: _additions,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixIcon: const Icon(
                              Icons.add_circle_outline_rounded,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: BrixenTextField(
                            label: 'Deductions',
                            hint: '0',
                            controller: _deductions,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixIcon: const Icon(
                              Icons.remove_circle_outline_rounded,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    BrixenTextField(
                      label: 'Note on the payslip',
                      hint: 'Optional, e.g. Advance recovered',
                      controller: _notes,
                      maxLines: 2,
                      prefixIcon: const Icon(Icons.notes_rounded),
                    ),
                    const SizedBox(height: 18),
                    BrixenButton(
                      label: 'Save payslip',
                      isLoading: _busy,
                      onPressed: _busy ? null : _save,
                    ),
                  ],
                ),
              ),
            ],
            if (widget.canSend && _slip.isFinalized) ...[
              const SizedBox(height: 20),
              if (_slip.email == null)
                Text(
                  'No email address for ${_slip.employeeName} — add one in '
                  'Employees to send payslips.',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                )
              else
                BrixenButton(
                  label: _slip.emailedAt == null
                      ? 'Email payslip'
                      : 'Email payslip again',
                  isLoading: _busy,
                  onPressed: _busy ? null : _send,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The payslip itself: employee, month, how they're paid, what they did,
/// and earned + additions − deductions = net pay.
class PayslipView extends StatelessWidget {
  final Payslip slip;

  /// Shown instead of the saved amounts while they're being edited.
  final double additions, deductions;
  const PayslipView({
    super.key,
    required this.slip,
    required this.additions,
    required this.deductions,
  });

  @override
  Widget build(BuildContext context) {
    final color = salaryTypeColor(slip.salaryType);
    final net = slip.gross + additions - deductions;
    Widget line(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong ? AppColors.ink : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.30)),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(21),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.accentGradient(color),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        slip.employeeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _WhitePill(
                      slip.isFinalized ? 'Finalized' : 'Draft',
                      slip.isFinalized
                          ? Icons.verified_rounded
                          : Icons.edit_note_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    slip.employeeCode,
                    if (slip.designation != null) slip.designation!,
                    if (slip.department != null) slip.department!,
                  ].join(' · '),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Net pay · ${monthLabel(slip.month)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  rupeesExact(net),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      salaryTypeIcon(slip.salaryType),
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${SalaryType.label(slip.salaryType)} · '
                        '${slip.rateLabel(rupeesExact)}',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                line('Days present', daysLabel(slip.daysPresent)),
                line('Worked', slip.workLabel),
                if (slip.salaryType == SalaryType.weekly && slip.rate != null)
                  line('Per day (week ÷ 6)', rupeesExact(slip.rate! / 6)),
                if (slip.salaryType == SalaryType.monthly &&
                    slip.rate != null &&
                    (slip.workingDays ?? 0) > 0)
                  line(
                    'Per day (month ÷ ${slip.workingDays})',
                    rupeesExact(slip.rate! / slip.workingDays!),
                  ),
                for (final p in slip.pieces)
                  line(
                    '  ${p.name} · ${p.quantity} × ${rupeesExact(p.rate)}',
                    rupeesExact(p.amount),
                  ),
                Divider(height: 20, color: AppColors.border),
                line('Earned', rupeesExact(slip.gross)),
                if (additions > 0)
                  line('Additions', '+ ${rupeesExact(additions)}'),
                if (deductions > 0)
                  line('Deductions', '− ${rupeesExact(deductions)}'),
                line('Net pay', rupeesExact(net), strong: true),
                if (slip.notes?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      slip.notes!,
                      style: TextStyle(color: AppColors.ink, fontSize: 12.5),
                    ),
                  ),
                ],
                if (slip.emailedAt != null || slip.emailError != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        slip.emailError == null
                            ? Icons.mark_email_read_rounded
                            : Icons.error_outline_rounded,
                        size: 15,
                        color: slip.emailError == null
                            ? AppColors.positiveDeep
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          slip.emailError == null
                              ? 'Emailed ${DateFormat('d MMM yyyy, h:mm a').format(slip.emailedAt!.toLocal())}'
                              : 'Email failed: ${slip.emailError}',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhitePill extends StatelessWidget {
  final String text;
  final IconData icon;
  const _WhitePill(this.text, this.icon);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white),
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
