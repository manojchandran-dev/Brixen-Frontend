import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../employees/presentation/providers/employees_provider.dart';

class CompanyAdminHomePage extends ConsumerStatefulWidget {
  const CompanyAdminHomePage({super.key});

  @override
  ConsumerState<CompanyAdminHomePage> createState() => _CompanyAdminHomePageState();
}

class _CompanyAdminHomePageState extends ConsumerState<CompanyAdminHomePage> {
  int _tabIndex = 0;

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  static String _dateStr() {
    final n = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[n.weekday - 1]}, ${n.day} ${months[n.month - 1]} ${n.year}';
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon'), backgroundColor: AppColors.ink),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNav(activeIndex: _tabIndex, onTap: (i) => setState(() => _tabIndex = i)),
      body: SafeArea(
        child: switch (_tabIndex) {
          2 => const ComingSoonView(icon: Icons.bar_chart_rounded, title: 'Reports', subtitle: 'Company-wide reports are on the way.'),
          3 => const ComingSoonView(icon: Icons.person_rounded, title: 'More', subtitle: 'Profile, settings and more will live here soon.'),
          _ => employeesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brand)),
          error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: AppColors.textSecondary))),
          data: (all) => _AdminDashboardBody(
            employees: all,
            greeting: _greeting(),
            dateStr: _dateStr(),
            onIconTap: (l) => _comingSoon(context, l),
          ),
        ),
        },
      ),
    );
  }
}

class _AdminDashboardBody extends StatelessWidget {
  final List<Employee> employees;
  final String greeting;
  final String dateStr;
  final void Function(String) onIconTap;

  const _AdminDashboardBody({required this.employees, required this.greeting, required this.dateStr, required this.onIconTap});

  @override
  Widget build(BuildContext context) {
    final onboarded = employees.where((e) => e.onboardingStatus == 'completed').length;
    final pending = employees.length - onboarded;

    // Month-over-month new-hire growth.
    final now = DateTime.now();
    final thisMonth = employees.where((e) => e.createdAt.year == now.year && e.createdAt.month == now.month).length;
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final lastMonth = employees.where((e) => e.createdAt.year == lastMonthDate.year && e.createdAt.month == lastMonthDate.month).length;
    final growthPct = lastMonth > 0 ? (((thisMonth - lastMonth) / lastMonth) * 100).round() : null;

    // 11 weekly buckets (oldest → newest) of how many employees joined —
    // drives the dot-column chart's bar heights (1–3 dots each).
    final weekly = List.generate(11, (i) {
      final weeksAgo = 10 - i;
      final start = now.subtract(Duration(days: (weeksAgo + 1) * 7));
      final end = now.subtract(Duration(days: weeksAgo * 7));
      return employees.where((e) => e.createdAt.isAfter(start) && e.createdAt.isBefore(end)).length;
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        // ── Header ──────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.menu_rounded, size: 18, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(dateStr, style: const TextStyle(color: AppColors.textHint, fontSize: 13))),
            GestureDetector(onTap: () => onIconTap('Search'), child: const Icon(Icons.search_rounded, color: AppColors.ink, size: 24)),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => onIconTap('Notifications'),
              child: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 24),
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle)),
                ),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('$greeting Admin', style: const TextStyle(color: AppColors.ink, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 20),

        // ── Hero stat card ───────────────────────────────────────
        _HeroStatCard(total: employees.length, weekly: weekly, growthPct: growthPct),
        const SizedBox(height: 14),

        // ── Open / Overdue tasks split card ───────────────────────
        const _SplitStatCard(),
        const SizedBox(height: 20),

        // ── Hiring status ─────────────────────────────────────────
        _HiringStatusCard(onboarded: onboarded, pending: pending, total: employees.length),
      ],
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  final int total;
  final List<int> weekly;
  final int? growthPct;

  const _HeroStatCard({required this.total, required this.weekly, required this.growthPct});

  @override
  Widget build(BuildContext context) {
    final up = (growthPct ?? 0) >= 0;
    final pct = growthPct ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(total.toString(), style: const TextStyle(color: AppColors.ink, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.positive, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('${pct.abs()}%', style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                    child: Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 11, color: AppColors.positive),
                  ),
                ]),
              ),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                child: const Center(child: Text('B', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 16))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('vs previous 3 months', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
          const SizedBox(height: 22),
          _DotColumnChart(weekly: weekly),
        ],
      ),
    );
  }
}

class _DotColumnChart extends StatelessWidget {
  final List<int> weekly;
  const _DotColumnChart({required this.weekly});

  @override
  Widget build(BuildContext context) {
    const rows = 3;
    const dot = 10.0;
    const gap = 6.0;

    return SizedBox(
      height: rows * dot + (rows - 1) * gap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(weekly.length, (i) {
          final height = weekly[i].clamp(0, rows) == 0 ? 1 : weekly[i].clamp(1, rows);
          final light = height <= 1 || i.isEven && height < rows;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(height, (r) {
              return Padding(
                padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
                child: Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: light ? AppColors.brandLight : AppColors.brand,
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

class _SplitStatCard extends StatelessWidget {
  const _SplitStatCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.brand, width: 1.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: const [
            Expanded(child: _SplitHalf(filled: true, pct: 80, label: 'Open\nTasks')),
            SizedBox(width: 8),
            Expanded(child: _SplitHalf(filled: false, pct: 20, label: 'Overdue\nTasks')),
          ],
        ),
      ),
    );
  }
}

class _SplitHalf extends StatelessWidget {
  final bool filled;
  final int pct;
  final String label;

  const _SplitHalf({required this.filled, required this.pct, required this.label});

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.white : AppColors.ink;
    final badgeBg = filled ? AppColors.white : AppColors.brand;
    final badgeFg = filled ? AppColors.brand : AppColors.white;
    final arrowBg = filled ? AppColors.white : AppColors.positive;
    final arrowFg = filled ? AppColors.ink : AppColors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: filled ? AppColors.brand : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
              child: Icon(Icons.person_outline_rounded, size: 14, color: badgeFg),
            ),
            const SizedBox(width: 8),
            Text('+2.5%', style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: arrowBg, shape: BoxShape.circle),
              child: Icon(Icons.arrow_upward_rounded, size: 11, color: arrowFg),
            ),
          ]),
          const SizedBox(height: 16),
          Text('$pct%', style: TextStyle(color: fg, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 13, height: 1.2)),
        ],
      ),
    );
  }
}

class _HiringStatusCard extends StatelessWidget {
  final int onboarded;
  final int pending;
  final int total;

  const _HiringStatusCard({required this.onboarded, required this.pending, required this.total});

  @override
  Widget build(BuildContext context) {
    final onboardedPct = total > 0 ? onboarded / total : 0.0;
    const barCount = 18;
    final filledBars = (onboardedPct * barCount).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hiring status', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                    SizedBox(height: 4),
                    Text('Talent recruitment', style: TextStyle(color: AppColors.ink, fontSize: 21, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                width: 62,
                child: Stack(
                  children: List.generate(2, (i) {
                    return Positioned(
                      left: i * 24.0,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == 0 ? AppColors.brand : AppColors.positive,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2.5),
                        ),
                        child: const Icon(Icons.person, color: AppColors.white, size: 19),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('$onboarded Onboarded', style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$pending Pending', style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: Row(
              children: List.generate(barCount, (i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i < filledBars ? AppColors.positive : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const _Legend(color: AppColors.positive, label: 'Onboarded'),
            const SizedBox(width: 20),
            const _Legend(color: AppColors.surfaceElevated, label: 'Pending', bordered: true),
          ]),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool bordered;
  const _Legend({required this.color, required this.label, this.bordered = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: bordered ? Border.all(color: AppColors.border) : null,
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ]);
  }
}
