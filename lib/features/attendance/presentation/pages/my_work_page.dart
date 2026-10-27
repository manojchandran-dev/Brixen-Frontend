import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/exact_amount.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../domain/attendance.dart';
import '../attendance_providers.dart';
import '../widgets/attendance_card.dart';

/// An employee login's home: who they are (code, department, salary terms)
/// and their attendance month by month, with the month's totals. Read-only;
/// everything comes from /me, scoped to this employee by the server.
class MyWorkPage extends ConsumerStatefulWidget {
  const MyWorkPage({super.key});

  @override
  ConsumerState<MyWorkPage> createState() => _MyWorkPageState();
}

class _MyWorkPageState extends ConsumerState<MyWorkPage> {
  /// "YYYY-MM"; null = this month (in the company's zone).
  String? _month;

  String _shift(String month, int by) {
    final d = DateTime(
      int.parse(month.substring(0, 4)),
      int.parse(month.substring(5, 7)) + by,
    );
    return DateFormat('yyyy-MM').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(myEmployeeProvider);
    final work = ref.watch(myAttendanceProvider(_month));
    final thisMonth = work.valueOrNull?.list.today.substring(0, 7);
    final month = _month ?? thisMonth;

    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(myEmployeeProvider);
        return ref.refresh(myAttendanceProvider(_month).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          Row(
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greetingPrefix(),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      me.valueOrNull?.employee.fullName ?? ' ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          me.when(
            skipError: true,
            loading: () => const Shimmer(
              child: SkeletonBox(width: double.infinity, height: 130),
            ),
            error: (e, _) => ErrorCard(
              error: e,
              onRetry: () => ref.invalidate(myEmployeeProvider),
            ),
            data: (m) =>
                _ProfileCard(employee: m.employee, company: m.companyName),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'My attendance',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (month != null) ...[
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: () => setState(() => _month = _shift(month, -1)),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  DateFormat('MMM yyyy').format(DateTime.parse('$month-01')),
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: month == thisMonth || thisMonth == null
                      ? null
                      : () => setState(() {
                          final next = _shift(month, 1);
                          _month = next == thisMonth ? null : next;
                        }),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          work.when(
            skipError: true,
            loading: () => const Shimmer(
              child: SkeletonBox(width: double.infinity, height: 200),
            ),
            error: (e, _) => ErrorCard(
              error: e,
              onRetry: () => ref.invalidate(myAttendanceProvider(_month)),
            ),
            data: (w) {
              final type = me.valueOrNull?.employee.salaryType;
              return Column(
                children: [
                  Row(
                    children: [
                      _Total('Days', '${w.days}', AppColors.brand),
                      const SizedBox(width: 8),
                      if (type == SalaryType.piece)
                        _Total('Pieces', '${w.pieces}', AppColors.positive)
                      else
                        _Total(
                          'Shifts',
                          shiftTotalLabel(w.shifts),
                          AppColors.positive,
                        ),
                      const SizedBox(width: 8),
                      _Total(
                        'Earned',
                        w.amount > 0 ? rupees(w.amount) : '—',
                        AppColors.brandDeep,
                        amount: w.amount > 0 ? w.amount : null,
                      ),
                    ],
                  ),
                  if (type == SalaryType.shift &&
                      me.valueOrNull?.employee.salaryPeriod != 'DAILY')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Your pay is ${me.valueOrNull?.employee.salarySummary ?? ''}; '
                        'earnings are worked out by your company.',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (w.list.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        'No attendance recorded this month',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    for (final r in w.list.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AttendanceCard(record: r, showEmployee: false),
                      ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Employee employee;
  final String? company;
  const _ProfileCard({required this.employee, required this.company});

  @override
  Widget build(BuildContext context) {
    final e = employee;
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.isDark
              ? [AppColors.brandDeep, AppColors.brandBlack]
              : [AppColors.brand, AppColors.positive],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  e.employeeCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (company != null)
                Flexible(
                  child: Text(
                    company!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          line(Icons.apartment_rounded, e.department ?? 'No department'),
          if (e.designation != null) line(Icons.badge_outlined, e.designation!),
          line(Icons.payments_outlined, e.salarySummary),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String label, value;
  final Color color;
  final double? amount;
  const _Total(this.label, this.value, this.color, {this.amount});

  @override
  Widget build(BuildContext context) => Expanded(
    child: ExactAmount(
      amount: amount,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
            ),
          ],
        ),
      ),
    ),
  );
}
