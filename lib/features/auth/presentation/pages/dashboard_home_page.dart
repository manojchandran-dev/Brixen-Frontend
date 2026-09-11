import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/welcome_dashboard_view.dart';
import '../../../dashboard/domain/entities/dashboard_summary.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../domain/entities/user_role.dart';

/// The shared Dashboard tab (index 0) — same route for every role, each
/// rendering its own role-appropriate body inside the common [AppShell].
class DashboardHomePage extends ConsumerStatefulWidget {
  const DashboardHomePage({super.key});

  @override
  ConsumerState<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends ConsumerState<DashboardHomePage> {
  // AppColors' values are plain static getters, not something Flutter's
  // element tree can detect changed on its own — a widget only picks up
  // the new theme's colors if it's actually rebuilt. This page (and
  // Report/More) used to have no reason to rebuild on a theme toggle, so
  // only whichever screen you happened to toggle it FROM (e.g. More,
  // whose AppMenuBody already listens for itself) updated live; every
  // other route stayed on the old colors until next visited. Listening
  // here — and constructing every role body fresh (no `const`) so the
  // rebuild actually cascades instead of Flutter skipping an unchanged
  // const subtree — fixes that for good.
  late final StreamSubscription<ThemeMode> _themeSub;

  @override
  void initState() {
    super.initState();
    _themeSub = themeCubit.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _themeSub.cancel();
    super.dispose();
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon'), backgroundColor: AppColors.dangerFill),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      activeIndex: 0,
      body: switch (Session.role) {
        UserRole.superAdmin => WelcomeDashboardView(),
        UserRole.companyAdmin => _CompanyDashboardBody(onIconTap: (l) => _comingSoon(context, l)),
        UserRole.employee => _EmployeeDashboardBody(onIconTap: (l) => _comingSoon(context, l)),
      },
    );
  }
}

// ── companyAdmin: at-a-glance dashboard ──────────────────────────────────
// Deliberately not built from stat "cards" the way Reports is — Sales/
// Expenses/Profit totals live in the Reports tab, not here. This is just a
// snapshot strip (Employees/Customers/Products) plus two plain
// recent-activity lists, so Dashboard reads as a distinct screen instead
// of a second copy of Reports.

class _CompanyDashboardBody extends ConsumerWidget {
  final void Function(String) onIconTap;
  const _CompanyDashboardBody({required this.onIconTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Single call to GET /dashboard/summary — CompanyScopeInterceptor
    // auto-attaches this session's company_id, so the backend returns the
    // company-scoped branch (employees/customers/products totals + top-3
    // recent sales/expenses, already sorted newest-first) instead of the
    // superAdmin's platform-wide one.
    final summary = ref.watch(dashboardSummaryProvider).valueOrNull;
    final employeesCount = summary?.totalEmployees ?? 0;
    final customersCount = summary?.totalCustomers ?? 0;
    final productsCount = summary?.totalProducts ?? 0;
    final recentSales = summary?.recentSales ?? const <RecentSaleSummary>[];
    final recentExpenses = summary?.recentExpenses ?? const <RecentExpenseSummary>[];

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
                  boxShadow: AppColors.shadows([
                    BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
                  ]),
                ),
                child: Icon(Icons.menu_rounded, size: 18, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Dashboard', style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(weekdayDateLabel(DateTime.now()), style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                ],
              ),
            ),
            GestureDetector(onTap: () => onIconTap('Search'), child: Icon(Icons.search_rounded, color: AppColors.ink, size: 24)),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => onIconTap('Notifications'),
              child: Stack(clipBehavior: Clip.none, children: [
                Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 24),
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.brandBlack, shape: BoxShape.circle)),
                ),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── Gradient greeting hero ────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.isDark ? [AppColors.brandDeep, AppColors.brandBlack] : [AppColors.brand, AppColors.positive],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppColors.shadows([
              BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 10)),
            ]),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${greetingPrefix()}, ${Session.ownerName ?? 'Admin'} 👋',
                      style: const TextStyle(color: AppColors.white, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                    ),
                    if (Session.companyName != null) ...[
                      const SizedBox(height: 4),
                      Text(Session.companyName!, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                    ],
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: const Icon(Icons.dashboard_rounded, color: AppColors.white, size: 22),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Company snapshot: Employees / Customers / Products ──────
        Text('Company Snapshot', style: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _SnapshotStrip(employees: employeesCount, customers: customersCount, products: productsCount),
        const SizedBox(height: 26),

        // ── Recent Sales ─────────────────────────────────────────
        Text('Recent Sales', style: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _RecentSalesList(sales: recentSales.take(3).toList()),
        const SizedBox(height: 26),

        // ── Recent Expenses ──────────────────────────────────────
        Text('Recent Expenses', style: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _RecentExpensesList(expenses: recentExpenses.take(3).toList()),
      ],
    );
  }
}

/// A single bordered strip with internal dividers — deliberately not three
/// separate elevated cards, so this doesn't read as the same component
/// language as Reports' stat cards.
class _SnapshotStrip extends StatelessWidget {
  final int employees;
  final int customers;
  final int products;
  const _SnapshotStrip({required this.employees, required this.customers, required this.products});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SnapshotSegment(icon: Icons.badge_rounded, color: AppColors.brand, value: employees, label: 'Employees')),
        const SizedBox(width: 10),
        Expanded(child: _SnapshotSegment(icon: Icons.people_alt_rounded, color: AppColors.positive, value: customers, label: 'Customers')),
        const SizedBox(width: 10),
        Expanded(child: _SnapshotSegment(icon: Icons.checkroom_rounded, color: AppColors.brandDeep, value: products, label: 'Products')),
      ],
    );
  }
}

/// A solid colored tile per metric (like Reports' Sales/Expenses cards),
/// just three of them fused into one row instead of the elevated-card
/// treatment, so this still doesn't read as a literal copy of that layout.
class _SnapshotSegment extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  const _SnapshotSegment({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final shadowDark = Color.lerp(color, AppColors.ink, 0.3)!;
    final shadowLight = Color.lerp(color, Colors.white, 0.4)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.accentGradient(color),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadows([
          BoxShadow(color: shadowDark.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8)),
          BoxShadow(color: shadowLight.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(-4, -4)),
        ]),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: AppColors.white),
          ),
          const SizedBox(height: 10),
          Text('$value', style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5)),
        ],
      ),
    );
  }
}

/// A raised, glossy icon circle — diagonal shade (light top-left → deep
/// bottom-right) plus a soft highlight arc, on top of the usual drop
/// shadow, so it reads as a small embossed button instead of a flat
/// color-filled dot.
class _GlossIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _GlossIconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final deep = Color.lerp(color, Colors.black, 0.35)!;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.25)!, color, deep],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: AppColors.shadows([
          BoxShadow(color: deep.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(-2, -2)),
        ]),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            left: 8,
            child: Container(
              width: 14,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
          Icon(icon, size: 16, color: AppColors.white),
        ],
      ),
    );
  }
}

/// Plain divided list rows directly on the page background — no card
/// container — for the same reason as [_SnapshotStrip] above.
class _RecentSalesList extends StatelessWidget {
  final List<RecentSaleSummary> sales;
  const _RecentSalesList({required this.sales});

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return Text('No sales yet.', style: TextStyle(color: AppColors.textHint, fontSize: 12.5));
    }
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return Column(
      children: sales.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        final name = s.customerName.isNotEmpty ? s.customerName : 'Walk-in';
        return Column(
          children: [
            Row(
              children: [
                const _GlossIconBadge(icon: Icons.point_of_sale_rounded, color: AppColors.brand),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      Text(DateFormat('d MMM').format(s.date), style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                    ],
                  ),
                ),
                Text('₹${fmt.format(s.amount)}', style: TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            if (i != sales.length - 1) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: AppColors.border)),
          ],
        );
      }).toList(),
    );
  }
}

class _RecentExpensesList extends StatelessWidget {
  final List<RecentExpenseSummary> expenses;
  const _RecentExpensesList({required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Text('No expenses yet.', style: TextStyle(color: AppColors.textHint, fontSize: 12.5));
    }
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return Column(
      children: expenses.asMap().entries.map((e) {
        final i = e.key;
        final x = e.value;
        return Column(
          children: [
            Row(
              children: [
                const _GlossIconBadge(icon: Icons.receipt_long_rounded, color: AppColors.brandDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(x.title, style: TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      Text(DateFormat('d MMM').format(x.date), style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                    ],
                  ),
                ),
                Text('₹${fmt.format(x.amount)}', style: TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            if (i != expenses.length - 1) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: AppColors.border)),
          ],
        );
      }).toList(),
    );
  }
}

// ── employee: daily activity dashboard ──────────────────────────────────
// Still local/placeholder content — no per-employee activity endpoints
// (tasks, attendance, meetings) exist yet.

class _EmployeeDashboardBody extends StatelessWidget {
  final void Function(String) onIconTap;
  const _EmployeeDashboardBody({required this.onIconTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        // ── Header ──────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.shadows([
                      BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
                    ]),
                  ),
                  child: Icon(Icons.menu_rounded, size: 18, color: AppColors.ink),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('${greetingPrefix()}!', style: TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 20)),
                  ]),
                  const SizedBox(height: 4),
                  Text("Here's what's happening today.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            _IconBadge(icon: Icons.notifications_none_rounded, hasDot: true, onTap: () => onIconTap('Notifications')),
          ],
        ),
        const SizedBox(height: 16),

        // ── Today Overview hero card ─────────────────────────────
        _TodayOverviewCard(dateStr: weekdayDateLabel(DateTime.now(), separator: '\n')),
        const SizedBox(height: 20),

        // ── Quick Actions ─────────────────────────────────────────
        _SectionHeader(title: 'Quick Actions', onViewAll: () => onIconTap('Quick actions')),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _QuickAction(icon: Icons.play_circle_fill_rounded, label: 'Start Timer', color: AppColors.brand, onTap: () => onIconTap('Timer')),
              _QuickAction(icon: Icons.fact_check_rounded, label: 'My Tasks', color: AppColors.positive, onTap: () => onIconTap('Tasks')),
              _QuickAction(icon: Icons.event_available_rounded, label: 'Attendance', color: AppColors.brand, onTap: () => onIconTap('Attendance')),
              _QuickAction(icon: Icons.bar_chart_rounded, label: 'Reports', color: AppColors.positive, onTap: () => onIconTap('Reports')),
              _QuickAction(icon: Icons.person_add_alt_1_rounded, label: 'Request', color: AppColors.brand, onTap: () => onIconTap('Requests')),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── My Tasks + Attendance / Upcoming meeting ──────────────
        _SectionHeader(title: 'My Tasks', onViewAll: () => onIconTap('Tasks')),
        const SizedBox(height: 10),
        const _MyTasksCard(),
        const SizedBox(height: 14),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _AttendanceCard(onView: () => onIconTap('Attendance'))),
            const SizedBox(width: 12),
            Expanded(child: _UpcomingMeetingCard(onView: () => onIconTap('Meetings'))),
          ],
        ),
        const SizedBox(height: 16),

        // ── Announcement banner ──────────────────────────────────
        _AnnouncementBanner(onReadMore: () => onIconTap('Announcements')),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w800))),
        GestureDetector(
          onTap: onViewAll,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('View All', style: TextStyle(color: AppColors.brand, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.brand),
          ]),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final bool hasDot;
  final VoidCallback onTap;
  const _IconBadge({required this.icon, this.hasDot = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.shadows([BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
            ),
            child: Icon(icon, color: AppColors.ink, size: 20),
          ),
          if (hasDot)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: AppColors.positive, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 2)),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayOverviewCard extends StatelessWidget {
  final String dateStr;
  const _TodayOverviewCard({required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brand, AppColors.brandDeep]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.shadows([BoxShadow(color: AppColors.brand.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Today Overview', style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.positive, borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('📈', style: TextStyle(fontSize: 11)),
                  SizedBox(width: 4),
                  Text('On Track', style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _OverviewStat(icon: Icons.assignment_turned_in_rounded, iconColor: AppColors.brandLight, value: '8', label: 'Tasks', sub: '6 Completed', subColor: AppColors.positive)),
              _divider(),
              Expanded(child: _OverviewStat(icon: Icons.schedule_rounded, iconColor: AppColors.positive, value: '05h 30m', label: 'Work Time', sub: 'of 08h 00m', subColor: Colors.white70)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _OverviewStat(icon: Icons.event_note_rounded, iconColor: AppColors.brandLight, value: '2', label: 'Meetings', sub: 'Upcoming', subColor: AppColors.brandLight)),
              _divider(),
              Expanded(child: _OverviewStat(icon: Icons.track_changes_rounded, iconColor: AppColors.positive, value: '92%', label: 'Productivity', sub: 'Good', subColor: AppColors.positive)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 58, margin: const EdgeInsets.symmetric(horizontal: 10), color: Colors.white.withValues(alpha: 0.15));
}

class _OverviewStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String sub;
  final Color subColor;

  const _OverviewStat({required this.icon, required this.iconColor, required this.value, required this.label, required this.sub, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: AppColors.white, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(color: subColor, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.shadows([BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6))]),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: AppColors.ink, fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _MyTasksCard extends StatelessWidget {
  const _MyTasksCard();

  static const _tasks = [
    (title: 'UI/UX Review', sub: 'Mobile App Design', status: 'Completed'),
    (title: 'Team Standup Meeting', sub: 'Daily Scrum', status: 'Completed'),
    (title: 'Dashboard Implementation', sub: 'Brixen Web App', status: 'In Progress'),
    (title: 'Bug Fixing', sub: 'Sprint - 12', status: 'Pending'),
  ];

  @override
  Widget build(BuildContext context) {
    final completed = _tasks.where((t) => t.status == 'Completed').length;
    final pct = completed / _tasks.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadows([BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8))]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _tasks.length; i++) ...[
            _TaskRow(title: _tasks[i].title, sub: _tasks[i].sub, status: _tasks[i].status),
            if (i < _tasks.length - 1) Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: AppColors.border)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text('$completed of ${_tasks.length} tasks completed', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              Text('${(pct * 100).round()}%', style: TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: AppColors.surfaceElevated, valueColor: const AlwaysStoppedAnimation(AppColors.positive)),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final String sub;
  final String status;
  const _TaskRow({required this.title, required this.sub, required this.status});

  @override
  Widget build(BuildContext context) {
    final done = status == 'Completed';
    final inProgress = status == 'In Progress';
    final statusColor = done ? AppColors.positive : (inProgress ? AppColors.brand : AppColors.textHint);

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.positive : Colors.transparent,
            border: done ? null : Border.all(color: AppColors.border, width: 1.5),
          ),
          child: done ? const Icon(Icons.check_rounded, color: AppColors.white, size: 15) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w600)),
              Text(sub, style: TextStyle(color: AppColors.textHint, fontSize: 11.5)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final VoidCallback onView;
  const _AttendanceCard({required this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadows([BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8))]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('Attendance', style: TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w800))),
            GestureDetector(onTap: onView, child: const Text('View', style: TextStyle(color: AppColors.brand, fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 14),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: CircularProgressIndicator(
                    value: 0.72,
                    strokeWidth: 5,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: const AlwaysStoppedAnimation(AppColors.positive),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.positive, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.white, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text('Checked In', style: TextStyle(color: AppColors.textHint, fontSize: 11.5))),
          Center(child: Text('09:02 AM', style: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.positive.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: const Text('Working', style: TextStyle(color: AppColors.positive, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingMeetingCard extends StatelessWidget {
  final VoidCallback onView;
  const _UpcomingMeetingCard({required this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadows([BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8))]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('Upcoming', style: TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w800))),
            GestureDetector(onTap: onView, child: const Text('View', style: TextStyle(color: AppColors.brand, fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 14),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_month_rounded, color: AppColors.brand, size: 20),
          ),
          const SizedBox(height: 12),
          const Text('11:00 AM', style: TextStyle(color: AppColors.brand, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('Product Review', style: TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w700)),
          Text('Meeting Room 2', style: TextStyle(color: AppColors.textHint, fontSize: 11.5)),
          const SizedBox(height: 10),
          SizedBox(
            height: 26,
            child: Stack(
              children: List.generate(3, (i) {
                return Positioned(
                  left: i * 16.0,
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i.isEven ? AppColors.brand : AppColors.positive,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: Icon(Icons.person, color: AppColors.white, size: 12),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  final VoidCallback onReadMore;
  const _AnnouncementBanner({required this.onReadMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.positive.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.positive, shape: BoxShape.circle),
            child: const Icon(Icons.campaign_rounded, color: AppColors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Company Announcement', style: TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.positive, borderRadius: BorderRadius.circular(20)),
                    child: const Text('New', style: TextStyle(color: AppColors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('Team Outing on 30th Aug 2026.\nGet ready for a fun and memorable day!',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onReadMore,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.positive, borderRadius: BorderRadius.circular(20)),
                    child: const Text('Read More', style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
