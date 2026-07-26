import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/presentation/cubit/attendance_cubit.dart';
import '../../../attendance/presentation/cubit/attendance_state.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/presentation/providers/companies_provider.dart';
import '../../../employees/presentation/providers/employees_provider.dart';

class ReportsBody extends ConsumerWidget {
  const ReportsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);
    final companies = companiesAsync.valueOrNull ?? <Company>[];
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      bloc: attendanceCubit,
      builder: (_, attState) {
        final records = attState is AttendanceLoaded ? attState.records : <AttendanceRecord>[];
        final employees = ref.watch(employeesProvider).valueOrNull ?? [];
        return _ReportsContent(
          companies: companies,
          records: records,
          employeeCount: employees.length,
        );
      },
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _ReportsContent extends StatelessWidget {
  final List<Company> companies;
  final List<AttendanceRecord> records;
  final int employeeCount;

  const _ReportsContent({
    required this.companies,
    required this.records,
    required this.employeeCount,
  });

  // ── Data helpers ─────────────────────────────────────────────────

  List<_Bar> _growthBars() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i);
      final count = companies
          .where((c) => c.createdAt.year == m.year && c.createdAt.month == m.month)
          .length;
      return _Bar(DateFormat('MMM').format(m), count.toDouble(), _monthColor(i));
    });
  }

  List<_Bar> _planBars() {
    const plans = ['Basic', 'Standard', 'Professional', 'Enterprise'];
    const colors = [
      AppColors.accentSlate, AppColors.accentTeal,
      AppColors.accentIndigo, AppColors.accentViolet,
    ];
    return plans.asMap().entries.map((e) {
      final count = companies.where((c) => c.subscriptionPlan == e.value).length;
      return _Bar(e.value, count.toDouble(), colors[e.key]);
    }).toList();
  }

  List<_Bar> _attendanceBars() {
    final now = DateTime.now();
    final month = records.where((r) => r.date.year == now.year && r.date.month == now.month).toList();
    return [
      _Bar('Present',  month.where((r) => r.status == AttendanceStatus.present).length.toDouble(),  AttendanceStatus.present.color),
      _Bar('Absent',   month.where((r) => r.status == AttendanceStatus.absent).length.toDouble(),   AttendanceStatus.absent.color),
      _Bar('Leave',    month.where((r) => r.status == AttendanceStatus.leave).length.toDouble(),    AttendanceStatus.leave.color),
      _Bar('Half Day', month.where((r) => r.status == AttendanceStatus.halfDay).length.toDouble(),  AttendanceStatus.halfDay.color),
    ];
  }

  Color _monthColor(int i) {
    const palette = [
      AppColors.accentTeal,
      AppColors.accentEmerald,
      AppColors.accentIndigo,
      AppColors.accentViolet,
      AppColors.accentGold,
      AppColors.accentSlate,
    ];
    return palette[i % palette.length];
  }

  double _attendanceRate() {
    if (records.isEmpty) return 0;
    final present = records.where((r) => r.status == AttendanceStatus.present).length;
    return (present / records.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final active   = companies.where((c) => c.isActive).length;
    final inactive = companies.length - active;
    final rate     = _attendanceRate();
    final attBars  = _attendanceBars();
    final hasAtt   = attBars.any((b) => b.value > 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI strip ────────────────────────────────────────────
          Row(children: [
            _KpiCard(value: '${companies.length}', label: 'Companies',  icon: Icons.business_rounded,     color: AppColors.accentIndigo),
            const SizedBox(width: 10),
            _KpiCard(value: '$active',              label: 'Active',     icon: Icons.check_circle_outline, color: AppColors.accentEmerald),
            const SizedBox(width: 10),
            _KpiCard(value: '$employeeCount',       label: 'Employees',  icon: Icons.badge_rounded,        color: AppColors.accentTeal),
            const SizedBox(width: 10),
            _KpiCard(value: '${rate.toStringAsFixed(0)}%', label: 'Attendance', icon: Icons.access_time_rounded, color: AppColors.accentGold),
          ]),
          const SizedBox(height: 20),

          // ── Company Growth ────────────────────────────────────────
          _ChartCard(
            title: 'Company Growth',
            subtitle: 'New companies per month (last 6 months)',
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.accentIndigo,
            child: _BarChartWidget(bars: _growthBars(), height: 140),
          ),
          const SizedBox(height: 14),

          // ── Status + Plans ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ChartCard(
                  title: 'Status',
                  subtitle: 'Active vs Inactive',
                  icon: Icons.donut_small_rounded,
                  iconColor: AppColors.accentEmerald,
                  child: _DonutWidget(
                    values: [active.toDouble(), inactive.toDouble()],
                    colors: const [AppColors.accentEmerald, AppColors.accentRose],
                    labels: const ['Active', 'Inactive'],
                    total: companies.length,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChartCard(
                  title: 'Plans',
                  subtitle: 'By subscription',
                  icon: Icons.workspace_premium_rounded,
                  iconColor: AppColors.accentViolet,
                  child: _HBarChartWidget(bars: _planBars()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Attendance ────────────────────────────────────────────
          _ChartCard(
            title: 'Attendance This Month',
            subtitle: DateFormat('MMMM yyyy').format(DateTime.now()),
            icon: Icons.calendar_month_rounded,
            iconColor: AppColors.accentTeal,
            child: hasAtt
                ? _BarChartWidget(bars: attBars, height: 140)
                : const _EmptyChartState(message: 'No attendance records this month'),
          ),
          const SizedBox(height: 14),

          // ── Top employees by attendance ───────────────────────────
          if (records.isNotEmpty) ...[
            _ChartCard(
              title: 'Employee Attendance',
              subtitle: 'All-time record summary',
              icon: Icons.people_alt_rounded,
              iconColor: AppColors.accentViolet,
              child: _EmployeeAttendanceList(records: records),
            ),
          ],
        ],
      ),
    );
  }
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chart Card ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 10, color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Vertical Bar Chart ────────────────────────────────────────────────────────

class _Bar {
  final String label;
  final double value;
  final Color color;
  const _Bar(this.label, this.value, this.color);
}

class _BarChartWidget extends StatelessWidget {
  final List<_Bar> bars;
  final double height;

  const _BarChartWidget({required this.bars, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxVal = bars.map((b) => b.value).fold(0.0, max);

    return TweenAnimationBuilder<double>(
      key: ValueKey(bars.map((b) => b.value).join()),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, progress, _) {
        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.map((bar) {
              final frac = maxVal > 0 ? bar.value / maxVal : 0.0;
              final barH = (frac * (height - 36) * progress).clamp(0.0, height - 36);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (bar.value > 0)
                        AnimatedOpacity(
                          opacity: progress > 0.6 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            '${bar.value.round()}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      const SizedBox(height: 3),
                      Container(
                        height: barH,
                        decoration: BoxDecoration(
                          color: bar.color,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5)),
                          boxShadow: barH > 4
                              ? [
                                  BoxShadow(
                                    color: bar.color.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bar.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: bar.color.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ── Horizontal Bar Chart ──────────────────────────────────────────────────────

class _HBarChartWidget extends StatelessWidget {
  final List<_Bar> bars;
  const _HBarChartWidget({required this.bars});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxVal = bars.map((b) => b.value).fold(0.0, max);

    return TweenAnimationBuilder<double>(
      key: ValueKey(bars.map((b) => b.value).join()),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, progress, _) {
        return Column(
          children: bars.map((bar) {
            final frac = maxVal > 0 ? (bar.value / maxVal) * progress : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(bar.label,
                            style: TextStyle(
                                fontSize: 10, color: cs.onSurfaceVariant)),
                      ),
                      Text(
                        '${bar.value.round()}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(builder: (_, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: bar.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Container(
                          height: 6,
                          width: constraints.maxWidth * frac,
                          decoration: BoxDecoration(
                            color: bar.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Donut Chart ───────────────────────────────────────────────────────────────

class _DonutWidget extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final List<String> labels;
  final int total;

  const _DonutWidget({
    required this.values,
    required this.colors,
    required this.labels,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, progress, _) {
        return Column(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: _DonutPainter(
                        values: values, colors: colors, progress: progress),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1,
                        ),
                      ),
                      Text('Total',
                          style: TextStyle(
                              fontSize: 9, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 6,
              children: List.generate(values.length, (i) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: colors[i], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${labels[i]} ${values[i].round()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double progress;

  _DonutPainter(
      {required this.values, required this.colors, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    const gap = 0.05;
    double startAngle = -pi / 2;

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = ((values[i] / total) * 2 * pi * progress) - gap;
      if (sweep <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
      startAngle += (values[i] / total) * 2 * pi * progress + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ── Employee Attendance List ──────────────────────────────────────────────────

class _EmployeeAttendanceList extends StatelessWidget {
  final List<AttendanceRecord> records;
  const _EmployeeAttendanceList({required this.records});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group by employee
    final Map<String, Map<String, int>> summary = {};
    for (final r in records) {
      summary.putIfAbsent(r.employeeName, () => {
        'present': 0, 'absent': 0, 'leave': 0, 'halfDay': 0,
      });
      switch (r.status) {
        case AttendanceStatus.present:  summary[r.employeeName]!['present']  = (summary[r.employeeName]!['present']!  + 1); break;
        case AttendanceStatus.absent:   summary[r.employeeName]!['absent']   = (summary[r.employeeName]!['absent']!   + 1); break;
        case AttendanceStatus.leave:    summary[r.employeeName]!['leave']    = (summary[r.employeeName]!['leave']!    + 1); break;
        case AttendanceStatus.halfDay:  summary[r.employeeName]!['halfDay']  = (summary[r.employeeName]!['halfDay']!  + 1); break;
      }
    }

    final entries = summary.entries.toList();

    return Column(
      children: entries.map((e) {
        final total  = e.value.values.fold(0, (a, b) => a + b);
        final present = e.value['present']! + e.value['halfDay']!;
        final rate = total > 0 ? (present / total * 100).round() : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surface.withValues(alpha: 0.5)
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accentViolet.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    e.key.isNotEmpty ? e.key[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentViolet),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        _SmallBadge('P: ${e.value['present']}', AttendanceStatus.present.color),
                        _SmallBadge('A: ${e.value['absent']}', AttendanceStatus.absent.color),
                        _SmallBadge('L: ${e.value['leave']}', AttendanceStatus.leave.color),
                        _SmallBadge('H: ${e.value['halfDay']}', AttendanceStatus.halfDay.color),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$rate%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: rate >= 80
                          ? AttendanceStatus.present.color
                          : rate >= 50
                              ? AttendanceStatus.halfDay.color
                              : AttendanceStatus.absent.color,
                    ),
                  ),
                  Text('rate',
                      style: TextStyle(
                          fontSize: 9, color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyChartState extends StatelessWidget {
  final String message;
  const _EmptyChartState({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 32, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
