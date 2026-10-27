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
import '../../../attendance/presentation/salary_type_visuals.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../permissions/presentation/providers/module_access_provider.dart';
import '../../data/payroll_remote_datasource.dart';
import '../../domain/payroll.dart';
import '../payroll_providers.dart';
import 'payslip_page.dart';

final _ym = DateFormat('yyyy-MM');

void _snack(BuildContext context, String text, {bool error = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: error ? AppColors.dangerFill : null,
    ),
  );
}

/// Salary Generation (part of Employees): pick a month and generate its
/// payslips from attendance, then review, finalize and email them. Below,
/// every month generated so far.
class SalaryGenerationPage extends ConsumerStatefulWidget {
  const SalaryGenerationPage({super.key});

  @override
  ConsumerState<SalaryGenerationPage> createState() =>
      _SalaryGenerationPageState();
}

class _SalaryGenerationPageState extends ConsumerState<SalaryGenerationPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _busy = false;

  bool get _isCurrent =>
      _ym.format(_month) ==
      _ym.format(DateTime(DateTime.now().year, DateTime.now().month));

  Future<void> _generate(List<PayrollRun> runs) async {
    final month = _ym.format(_month);
    final existing = runs.where((r) => r.month == month).firstOrNull;
    if (existing?.isFinalized ?? false) {
      return _open(existing!.id);
    }
    final ds = ref.read(payrollDatasourceProvider);
    setState(() => _busy = true);
    try {
      final preview = await ds.preview(month);
      if (!mounted) return;
      final days = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _GenerateSheet(
          month: month,
          workingDays: preview.workingDays,
          again: existing != null,
        ),
      );
      if (days == null) return;
      final run = await ds.generate(month, workingDays: days);
      refreshPayroll(ref, run.id);
      if (!mounted) return;
      _snack(
        context,
        '${run.label}: ${run.payslipCount} payslips generated',
        error: false,
      );
      _open(run.id);
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(String runId) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => SalaryRunPage(runId: runId)));

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(moduleAccessProvider('Employees'));
    final runs = ref.watch(payrollRunsProvider);
    final list = runs.valueOrNull ?? const <PayrollRun>[];
    final current = list
        .where((r) => r.month == _ym.format(_month))
        .firstOrNull;

    return Scaffold(
      drawer: const AppDrawer(),
      // AppBottomNav fills the Scaffold height (its pill is Align-ed to the
      // bottom) — without extendBody the body gets zero height.
      extendBody: true,
      bottomNavigationBar: const AppBottomNav(activeIndex: 3),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const ModuleTitle(
          title: 'Salary Generation',
          subtitle: 'Payslips from attendance',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(payrollRunsProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            _GenerateCard(
              month: _month,
              run: current,
              busy: _busy,
              canNext: !_isCurrent,
              canGenerate: access.create,
              onPrev: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              onNext: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1),
              ),
              onGenerate: () => _generate(list),
              onOpen: current == null ? null : () => _open(current.id),
            ),
            const SizedBox(height: 18),
            StepGuide(
              steps: kSalarySteps,
              current: current == null
                  ? 0
                  : current.isFinalized
                  ? 2
                  : 1,
            ),
            const SizedBox(height: 18),
            const _PayRules(),
            const SizedBox(height: 20),
            Text(
              'Salary months',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            runs.when(
              skipError: true,
              loading: () => const Shimmer(
                child: SkeletonBox(width: double.infinity, height: 140),
              ),
              error: (e, _) => ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(payrollRunsProvider),
              ),
              data: (items) => items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No salary generated yet. Pick a month above and '
                        'generate it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : Column(
                      children: [
                        for (final r in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RunTile(run: r, onTap: () => _open(r.id)),
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

/// The month picker and Generate button, on the brand gradient.
class _GenerateCard extends StatelessWidget {
  final DateTime month;
  final PayrollRun? run;
  final bool busy, canNext, canGenerate;
  final VoidCallback onPrev, onNext, onGenerate;
  final VoidCallback? onOpen;
  const _GenerateCard({
    required this.month,
    required this.run,
    required this.busy,
    required this.canNext,
    required this.canGenerate,
    required this.onPrev,
    required this.onNext,
    required this.onGenerate,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final r = run;
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: kThemeSweepGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.accentGradient(AppColors.positive),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.payments_rounded, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Generate salary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              arrow(Icons.chevron_left_rounded, onPrev),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              arrow(Icons.chevron_right_rounded, canNext ? onNext : null),
            ],
          ),
          const SizedBox(height: 12),
          if (r == null)
            Text(
              'Not generated yet. Tap Generate: each employee\'s pay is worked '
              'out from this month\'s attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: BannerStatTile(
                    BannerStat(
                      r.isFinalized ? 'Finalized' : 'Draft',
                      'status',
                      r.isFinalized ? AppColors.positive : AppColors.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BannerStatTile(
                    BannerStat(
                      '${r.payslipCount}',
                      'payslips',
                      AppColors.brandBlack,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BannerStatTile(
                    BannerStat(
                      rupees(r.totalNet),
                      'net pay',
                      AppColors.positive,
                      exact: r.totalNet,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (r != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpen,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('Open'),
                  ),
                ),
              if (r != null && canGenerate && !r.isFinalized)
                const SizedBox(width: 10),
              if (canGenerate && !(r?.isFinalized ?? false))
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onGenerate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.positive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(r == null ? 'Generate' : 'Generate again'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Generate → review → finalize & send.
const kSalarySteps = [
  (Icons.auto_awesome_rounded, 'Generate', 'From attendance'),
  (Icons.fact_check_rounded, 'Review', 'Bonus & deductions'),
  (Icons.send_rounded, 'Finalize', 'Lock & email'),
];

/// How each salary type's pay is worked out, in its colour.
class _PayRules extends StatelessWidget {
  const _PayRules();

  @override
  Widget build(BuildContext context) {
    const rules = {
      SalaryType.shift: 'Shifts worked × amount per shift',
      SalaryType.piece: 'Pieces × each work type\'s rate',
      SalaryType.hourly: 'Hours worked × amount per hour',
      SalaryType.weekly: 'Days present × (weekly salary ÷ 6)',
      SalaryType.monthly: 'Days present × (monthly salary ÷ working days)',
    };
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.accentGradient(AppColors.brandDeep),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calculate_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            title: Text(
              'How pay is worked out',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              'Half days count ½ · additions and deductions are added after',
              style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
            ),
            children: [
              for (final e in rules.entries)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        salaryTypeColor(e.key).withValues(alpha: 0.16),
                        salaryTypeColor(e.key).withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        salaryTypeIcon(e.key),
                        size: 18,
                        color: salaryTypeColor(e.key),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 74,
                        child: Text(
                          SalaryType.label(e.key),
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
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

/// Confirms the month's working days (what a monthly salary is divided by)
/// before generating. Pops the days, or null.
class _GenerateSheet extends StatefulWidget {
  final String month;
  final int workingDays;
  final bool again;
  const _GenerateSheet({
    required this.month,
    required this.workingDays,
    required this.again,
  });

  @override
  State<_GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends State<_GenerateSheet> {
  late int _days = widget.workingDays;

  int get _max {
    final d = DateTime.parse('${widget.month}-01');
    return DateTime(d.year, d.month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, int by) => IconButton.filledTonal(
      onPressed: (_days + by) < 1 || (_days + by) > _max
          ? null
          : () => setState(() => _days += by),
      icon: Icon(icon),
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.again ? 'Generate again' : 'Generate'} · '
              '${monthLabel(widget.month)}',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.again
                  ? 'Pay is worked out again from attendance. Additions, '
                        'deductions and notes already entered are kept.'
                  : 'Pay is worked out from attendance: shifts × rate, pieces × '
                        'work type rates, hours × rate, and weekly / monthly '
                        'salaries by days present.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Working days',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'A monthly salary ÷ these days = one day\'s pay. '
                        'Default: the month less Sundays.',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                step(Icons.remove_rounded, -1),
                SizedBox(
                  width: 44,
                  child: Text(
                    '$_days',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                step(Icons.add_rounded, 1),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_days),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(widget.again ? 'Generate again' : 'Generate'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool finalized;
  const _StatusChip(this.finalized);

  @override
  Widget build(BuildContext context) {
    final color = finalized ? AppColors.positiveDeep : AppColors.brandLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.accentGradient(color)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            finalized ? Icons.verified_rounded : Icons.edit_note_rounded,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            finalized ? 'Finalized' : 'Draft',
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
}

class _RunTile extends StatelessWidget {
  final PayrollRun run;
  final VoidCallback onTap;
  const _RunTile({required this.run, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = run.isFinalized ? AppColors.positiveDeep : AppColors.brand;
    final d = DateTime.parse('${run.month}-01');
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.07), AppColors.surface],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.accentGradient(color),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM').format(d).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${d.year}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      run.label,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusChip(run.isFinalized),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${run.payslipCount} payslips',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ExactAmount(
                amount: run.totalNet,
                child: Text(
                  rupees(run.totalNet),
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

// ── One month ─────────────────────────────────────────────────────────────

/// A month's payslips: totals, then each employee's net pay. Draft: adjust
/// payslips, generate again, finalize or delete. Finalized: email payslips
/// or reopen.
class SalaryRunPage extends ConsumerStatefulWidget {
  final String runId;
  const SalaryRunPage({super.key, required this.runId});

  @override
  ConsumerState<SalaryRunPage> createState() => _SalaryRunPageState();
}

class _SalaryRunPageState extends ConsumerState<SalaryRunPage> {
  bool _busy = false;
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _type;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _act(
    Future<void> Function() fn, {
    String? done,
    bool pop = false,
  }) async {
    setState(() => _busy = true);
    try {
      await fn();
      refreshPayroll(ref, widget.runId);
      if (!mounted) return;
      if (done != null) _snack(context, done, error: false);
      if (pop) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _send(PayrollRun run) async {
    final withEmail = run.payslips.where((p) => p.email != null).length;
    if (!await _confirm(
      'Email payslips?',
      '$withEmail of ${run.payslips.length} employees have an email address '
          'and will get their ${run.label} payslip.',
      'Send',
    )) {
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await ref.read(payrollDatasourceProvider).send(run.id);
      refreshPayroll(ref, run.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text('${r.sent} payslip${r.sent == 1 ? '' : 's'} emailed'),
          content: r.skipped.isEmpty && r.failed.isEmpty
              ? null
              : SingleChildScrollView(
                  child: Text(
                    [
                      if (r.skipped.isNotEmpty)
                        'Not sent:\n${r.skipped.join('\n')}',
                      if (r.failed.isNotEmpty)
                        'Failed:\n${r.failed.join('\n')}',
                    ].join('\n\n'),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(d).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _snack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(moduleAccessProvider('Employees'));
    final async = ref.watch(payrollRunProvider(widget.runId));
    final run = async.valueOrNull;
    final ds = ref.read(payrollDatasourceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(run?.label ?? 'Salary'),
        actions: [
          if (run != null && !run.isFinalized && access.delete)
            IconButton(
              tooltip: 'Delete this month',
              onPressed: _busy
                  ? null
                  : () async {
                      if (await _confirm(
                        'Delete ${run.label}?',
                        'Its draft payslips are removed. Attendance stays.',
                        'Delete',
                      )) {
                        _act(
                          () => ds.deleteRun(run.id),
                          done: '${run.label} deleted',
                          pop: true,
                        );
                      }
                    },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: async.when(
        skipError: true,
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Shimmer(
            child: SkeletonBox(width: double.infinity, height: 220),
          ),
        ),
        error: (e, _) => ErrorCard(
          error: e,
          onRetry: () => ref.invalidate(payrollRunProvider(widget.runId)),
        ),
        data: (run) {
          final q = _search.trim().toLowerCase();
          final slips = [
            for (final p in run.payslips)
              if ((_type == null || p.salaryType == _type) &&
                  (q.isEmpty ||
                      p.employeeName.toLowerCase().contains(q) ||
                      p.employeeCode.toLowerCase().contains(q)))
                p,
          ];
          final types = {for (final p in run.payslips) p.salaryType};
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(payrollRunProvider(widget.runId).future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                _RunSummary(run: run),
                const SizedBox(height: 16),
                StepGuide(
                  steps: kSalarySteps,
                  current: run.isFinalized ? 2 : 1,
                ),
                const SizedBox(height: 10),
                Text(
                  run.isFinalized
                      ? 'Done. Email the payslips to your employees; they also '
                            'see them in the app. Reopen to change anything.'
                      : 'Check each payslip below — tap one to add a bonus or '
                            'take off an advance — then Finalize.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                _actions(run, access, ds),
                const SizedBox(height: 18),
                SearchField(
                  controller: _searchCtrl,
                  hintText: 'Search name or employee ID',
                  onChanged: (v) => setState(() => _search = v),
                ),
                if (types.length > 1) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TypeChip(
                          label: 'All',
                          color: AppColors.brand,
                          selected: _type == null,
                          onTap: () => setState(() => _type = null),
                        ),
                        for (final t in SalaryType.all)
                          if (types.contains(t))
                            _TypeChip(
                              label: SalaryType.label(t),
                              icon: salaryTypeIcon(t),
                              color: salaryTypeColor(t),
                              selected: _type == t,
                              onTap: () => setState(() => _type = t),
                            ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (slips.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No payslips match',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                for (final p in slips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PayslipTile(
                      slip: p,
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => PayslipPage(
                              payslip: p,
                              canEdit: access.edit,
                              canSend: access.create,
                            ),
                          ),
                        );
                        if (changed == true) {
                          ref.invalidate(payrollRunProvider(widget.runId));
                        }
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _actions(
    PayrollRun run,
    ModuleAccess access,
    PayrollRemoteDatasource ds,
  ) {
    final buttons = <Widget>[
      if (!run.isFinalized && access.create)
        _ActionButton(
          icon: Icons.refresh_rounded,
          label: 'Generate again',
          color: AppColors.brandLight,
          onTap: _busy
              ? null
              : () => _act(
                  () => ds.generate(run.month, workingDays: run.workingDays),
                  done: 'Worked out again from attendance',
                ),
        ),
      if (!run.isFinalized && access.create)
        _ActionButton(
          icon: Icons.verified_rounded,
          label: 'Finalize',
          color: AppColors.positiveDeep,
          onTap: _busy
              ? null
              : () async {
                  if (await _confirm(
                    'Finalize ${run.label}?',
                    'Payslips are locked (reopen to change them), can be '
                        'emailed, and count in the salary report.',
                    'Finalize',
                  )) {
                    _act(
                      () => ds.finalize(run.id),
                      done: '${run.label} finalized',
                    );
                  }
                },
        ),
      if (run.isFinalized && access.create)
        _ActionButton(
          icon: Icons.forward_to_inbox_rounded,
          label: 'Email payslips',
          color: AppColors.brand,
          onTap: _busy ? null : () => _send(run),
        ),
      if (run.isFinalized && access.edit)
        _ActionButton(
          icon: Icons.lock_open_rounded,
          label: 'Reopen',
          color: AppColors.brandDeep,
          onTap: _busy
              ? null
              : () => _act(
                  () => ds.reopen(run.id),
                  done: '${run.label} reopened as a draft',
                ),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (final (i, b) in buttons.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: b),
        ],
      ],
    );
  }
}

class _RunSummary extends StatelessWidget {
  final PayrollRun run;
  const _RunSummary({required this.run});

  @override
  Widget build(BuildContext context) {
    final adds = run.payslips.fold<double>(0, (a, p) => a + p.additions);
    final deds = run.payslips.fold<double>(0, (a, p) => a + p.deductions);
    Widget stat(String label, String value, {double? exact}) => Expanded(
      child: ExactAmount(
        amount: exact,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: kThemeSweepGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Net pay · ${run.payslips.length} employees',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusChip(run.isFinalized),
            ],
          ),
          ExactAmount(
            amount: run.totalNet,
            child: Text(
              rupees(run.totalNet),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              stat('Earned', rupees(run.totalGross), exact: run.totalGross),
              stat('Additions', rupees(adds), exact: adds),
              stat('Deductions', rupees(deds), exact: deds),
              stat('Working days', '${run.workingDays}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? 0.5 : 1,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: AppColors.accentGradient(color)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: AppColors.accentGradient(color))
              : null,
          color: selected ? null : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: selected ? Colors.white : color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
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

/// A payslip in a list: who, their salary type, what they worked and net
/// pay; an envelope once emailed.
class PayslipTile extends StatelessWidget {
  final Payslip slip;
  final VoidCallback onTap;

  /// The employee's own list: show the month instead of the name.
  final bool showMonth;
  const PayslipTile({
    super.key,
    required this.slip,
    required this.onTap,
    this.showMonth = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = salaryTypeColor(slip.salaryType);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.28)),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.07), AppColors.surface],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.accentGradient(color),
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: showMonth
                    ? Icon(
                        salaryTypeIcon(slip.salaryType),
                        color: Colors.white,
                        size: 20,
                      )
                    : Text(
                        slip.employeeName.isEmpty
                            ? '?'
                            : slip.employeeName[0].toUpperCase(),
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
                      showMonth ? monthLabel(slip.month) : slip.employeeName,
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
                        if (!showMonth) slip.employeeCode,
                        SalaryType.label(slip.salaryType),
                        slip.workLabel,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ExactAmount(
                    amount: slip.net,
                    child: Text(
                      rupees(slip.net),
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!showMonth &&
                      (slip.emailedAt != null || slip.emailError != null))
                    Icon(
                      slip.emailError == null
                          ? Icons.mark_email_read_rounded
                          : Icons.mark_email_unread_outlined,
                      size: 15,
                      color: slip.emailError == null
                          ? AppColors.positiveDeep
                          : AppColors.textHint,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An employee login's payslips, newest first.
class MyPayslipsPage extends ConsumerWidget {
  const MyPayslipsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myPayslipsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My payslips')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myPayslipsProvider.future),
        child: async.when(
          skipError: true,
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Shimmer(
              child: SkeletonBox(width: double.infinity, height: 160),
            ),
          ),
          error: (e, _) => ErrorCard(
            error: e,
            onRetry: () => ref.invalidate(myPayslipsProvider),
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No payslips yet. They show here once your company '
                    'finalizes a month\'s salary.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              for (final p in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PayslipTile(
                    slip: p,
                    showMonth: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PayslipPage(payslip: p),
                      ),
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
