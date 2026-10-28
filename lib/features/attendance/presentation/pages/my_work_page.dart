import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/account_store.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/exact_amount.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../payroll/presentation/pages/salary_generation_pages.dart';
import '../../domain/attendance.dart';
import '../attendance_providers.dart';
import '../salary_type_visuals.dart';
import '../widgets/attendance_card.dart';

/// An employee login's home: who they are (code, department, salary terms),
/// their payslips, and their attendance month by month with the month's
/// totals. Read-only; everything comes from /me, scoped to this employee by
/// the server.
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
    // A session saved before names were kept learns the employee's name
    // here, for the More tab and the account switcher.
    ref.listen(myEmployeeProvider, (_, next) {
      final name = next.valueOrNull?.employee.fullName;
      final token = TokenService.token;
      if (name == null || name.isEmpty || name == TokenService.userName) {
        return;
      }
      if (token == null) return;
      TokenService.save(
        token: token,
        role: TokenService.role ?? '',
        userName: name,
      ).then((_) => AccountStore.upsertCurrent());
    });
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
          // The page's name on top, like the company dashboard; the greeting
          // is in the card below.
          Row(
            children: [
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.shadows([
                        BoxShadow(
                          color: AppColors.shadowDark.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      weekdayDateLabel(DateTime.now()),
                      style: TextStyle(color: AppColors.textHint, fontSize: 12),
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
          const SizedBox(height: 12),
          _PayslipsLink(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MyPayslipsPage())),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'My attendance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
              final (label, value) = switch (type) {
                SalaryType.piece => ('Pieces', '${w.pieces}'),
                SalaryType.hourly => ('Hours', hoursLabel(w.hours)),
                SalaryType.weekly ||
                SalaryType.monthly => ('Days worked', daysLabel(w.dayUnits)),
                _ => ('Shifts', shiftTotalLabel(w.shifts)),
              };
              return Column(
                children: [
                  Row(
                    children: [
                      _Total('Days', '${w.days}', AppColors.brand),
                      const SizedBox(width: 8),
                      _Total(label, value, salaryTypeColor(type)),
                      const SizedBox(width: 8),
                      _Total(
                        'Earned',
                        w.amount > 0 ? rupees(w.amount) : '—',
                        AppColors.positiveDeep,
                        amount: w.amount > 0 ? w.amount : null,
                      ),
                    ],
                  ),
                  if (SalaryType.isDayBased(type))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Your pay is ${me.valueOrNull?.employee.salarySummary ?? ''}; '
                        'it\'s worked out at salary generation — see your payslips.',
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
          // Greeting small, name large.
          Text(
            greetingPrefix(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            e.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
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

class _PayslipsLink extends StatelessWidget {
  final VoidCallback onTap;
  const _PayslipsLink({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.positiveDeep.withValues(alpha: 0.3),
          ),
          gradient: LinearGradient(
            colors: [
              AppColors.positive.withValues(alpha: 0.12),
              AppColors.surface,
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.accentGradient(AppColors.positiveDeep),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My payslips',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Weekly or monthly salary from your company',
                    style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    ),
  );
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
