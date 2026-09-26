import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/support/domain/entities/support_ticket.dart';
import '../../features/support/presentation/widgets/ticket_labels.dart';
import '../../features/support/presentation/widgets/ticket_status_badge.dart';
import '../../features/dashboard/domain/entities/superadmin_dashboard.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import 'error_state.dart';
import 'session_icon.dart';
import 'skeleton.dart';

/// The main "Dashboard" tab — backed by a single aggregate call,
/// `GET /api/v1/dashboard/summary`, instead of pulling the full
/// companies/employees/sales lists and aggregating client-side.
class WelcomeDashboardView extends ConsumerWidget {
  // `/dashboard` (via AppShell) has no AppBar of its own, so this view needs
  // to show its own hamburger to open the drawer. `companies_page.dart`
  // embeds this same view inside ITS OWN Scaffold, which already has an
  // AppBar + hamburger — pass false there to avoid a duplicate.
  final bool showMenuButton;
  const WelcomeDashboardView({super.key, this.showMenuButton = true});

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // One consistent brand gradient — blue→green in light mode, deep
  // blue→black in dark mode — regardless of time of day. The session icon
  // alone (sunrise/sun/sunset/moon) carries the "time of day" meaning, so
  // the header itself stays within the app's own four colours.
  static List<Color> _sessionGradient() {
    return AppColors.isDark
        ? [AppColors.brandDeep, AppColors.brandBlack]
        : [AppColors.brand, AppColors.positive];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(superadminDashboardProvider);

    return summaryAsync.when(
      loading: () => _DashboardSkeleton(showMenuButton: showMenuButton),
      error: (e, _) => ErrorCard(
        error: e,
        onRetry: () => ref.invalidate(superadminDashboardProvider),
      ),
      data: (summary) =>
          _DashboardContent(data: summary, showMenuButton: showMenuButton),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final SuperadminDashboard data;
  final bool showMenuButton;
  const _DashboardContent({required this.data, required this.showMenuButton});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = data;
    final total = d.companiesTotal;
    final active = d.companiesActive;
    final inactive = d.companiesInactive;
    final newThisMonth = d.companiesNewThisMonth;
    final weekly = d.weeklySignups;
    final activity = [for (final a in d.recentActivity) _Activity.from(a)];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(superadminDashboardProvider);
        await ref.read(superadminDashboardProvider.future);
      },
      // A plain Column in a scroll view (no nested grid) — every section is
      // laid out up front, so nothing is left unbuilt below the fold.
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showMenuButton) ...[
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
                              color: AppColors.shadowDark.withValues(
                                alpha: 0.08,
                              ),
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
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // ── Greeting (unchanged) ──
            const _GreetingCard(),
            const SizedBox(height: 18),

            // ── Companies hero ──
            _CompaniesHero(
              total: total,
              active: active,
              inactive: inactive,
              newThisMonth: newThisMonth,
              weekly: weekly,
              onTap: () => context.go(
                AppRouter.companies,
                extra: AppRouter.companiesSection('companies'),
              ),
            ),
            const SizedBox(height: 18),

            // ── KPI tiles ──
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _KpiTile(
                      icon: Icons.badge_rounded,
                      value: '${d.employeesTotal}',
                      label: 'Employees',
                      color: AppColors.positive,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _KpiTile(
                      icon: Icons.support_agent_rounded,
                      value: '${d.ticketsOpen + d.ticketsPending}',
                      label: 'Open Tickets',
                      color: AppColors.brand,
                      onTap: () => context.push(AppRouter.support),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _KpiTile(
              icon: Icons.notifications_rounded,
              value: '${d.unreadNotifications}',
              label: 'Unread Notifications',
              color: AppColors.brandBlack,
            ),
            const SizedBox(height: 18),

            // ── Support Overview ──
            _Section(
              title: 'Support',
              icon: Icons.support_agent_rounded,
              action: 'Open',
              onAction: () => context.push(AppRouter.support),
              child: Column(
                children: [
                  Row(
                    children: [
                      _SolidStat(
                        label: 'Open',
                        value: '${d.ticketsOpen}',
                        color: AppColors.brand,
                      ),
                      _SolidStat(
                        label: 'Pending',
                        value: '${d.ticketsPending}',
                        color: AppColors.positive,
                      ),
                      _SolidStat(
                        label: 'Critical',
                        value: '${d.ticketsCritical}',
                        color: AppColors.brandBlack,
                      ),
                    ],
                  ),
                  if (d.recentTickets.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final t in d.recentTickets.take(3))
                      _TicketRow(
                        ticket: t,
                        onTap: () =>
                            context.push(AppRouter.ticketDetail, extra: t),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Notifications today (dark card) ──
            _NotificationsCard(
              failedToLoad: false,
              sent: '${d.sentToday}',
              delivered: '${d.deliveredToday}',
              failed: '${d.failedToday}',
              read: '${d.readToday}',
              onTap: () => context.push(AppRouter.pushNotifications),
            ),
            const SizedBox(height: 18),

            // ── Recent Activity ──
            _Section(
              title: 'Recent Activity',
              icon: Icons.bolt_rounded,
              child: activity.isEmpty
                  ? const _Unavailable('No activity yet')
                  : Column(
                      children: [
                        for (final (i, a) in activity.take(5).indexed)
                          _ActivityRow(
                            activity: a,
                            isLast: i == activity.take(5).length - 1,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 18),

            // ── System Health ──
            _Section(
              title: 'System Health',
              icon: Icons.monitor_heart_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      _HealthTile.of(
                        d.health['api'],
                        Icons.cloud_done_rounded,
                        'API',
                      ),
                      const SizedBox(width: 10),
                      _HealthTile.of(
                        d.health['database'],
                        Icons.storage_rounded,
                        'Database',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _HealthTile.of(
                        d.health['fcm'],
                        Icons.notifications_active_outlined,
                        'Firebase / FCM',
                      ),
                      const SizedBox(width: 10),
                      _HealthTile.of(
                        d.health['storage'],
                        Icons.folder_rounded,
                        'Storage',
                      ),
                    ],
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

// ── Pieces ─────────────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.white;
    final fgMuted = AppColors.white.withValues(alpha: 0.75);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: WelcomeDashboardView._sessionGradient(),
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ]),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${WelcomeDashboardView._greeting()} 👋',
                  style: TextStyle(
                    color: fg,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: FittedBox(child: SessionIcon(session: currentSession())),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome to your Brixen workspace',
            style: TextStyle(color: fgMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Blue gradient hero: total companies, active/inactive split, this month's
/// signups and the weekly growth bars — all in white.
class _CompaniesHero extends StatelessWidget {
  final int total, active, inactive, newThisMonth;
  final List<int> weekly;
  final VoidCallback onTap;
  const _CompaniesHero({
    required this.total,
    required this.active,
    required this.inactive,
    required this.newThisMonth,
    required this.weekly,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final max = weekly.fold<int>(1, (a, b) => b > a ? b : a);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brand, AppColors.brandDeep],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: AppColors.brandDeep.withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.business_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Companies',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _HeroPill(
                        label: '$active active',
                        background: AppColors.positive,
                      ),
                      _HeroPill(
                        label: '+$newThisMonth this month',
                        background: Colors.white.withValues(alpha: 0.18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 7,
                child: total == 0
                    ? Container(color: Colors.white.withValues(alpha: 0.2))
                    : Row(
                        children: [
                          if (active > 0)
                            Expanded(
                              flex: active,
                              child: Container(color: AppColors.positive),
                            ),
                          if (inactive > 0)
                            Expanded(
                              flex: inactive,
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$active active · $inactive inactive',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11.5,
              ),
            ),
            if (weekly.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < weekly.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                          child: Container(
                            height: 6 + (weekly[i] / max) * 36,
                            decoration: BoxDecoration(
                              color: i == weekly.length - 1
                                  ? AppColors.positive
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'New companies per week · last ${weekly.length} weeks',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 10.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final Color background;
  const _HeroPill({required this.label, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A filled colour tile — the old dashboard's KPI style.
class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _KpiTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.accentGradient(color),
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: Color.lerp(
                color,
                Colors.black,
                0.3,
              )!.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
            BoxShadow(
              color: Color.lerp(
                color,
                Colors.white,
                0.4,
              )!.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(-4, -4),
            ),
          ]),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: AppColors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
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

/// White rounded section card: coloured icon badge, title, action link.
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;
  const _Section({
    required this.title,
    required this.icon,
    this.action,
    this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadows([
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.highlightShadow(0.9),
            blurRadius: 10,
            offset: const Offset(-5, -5),
          ),
        ]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.accentGradient(AppColors.brand),
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (action != null)
                GestureDetector(
                  onTap: onAction,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action!,
                        style: const TextStyle(
                          color: AppColors.brand,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.brand,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// A solid coloured stat block (white number on the colour).
class _SolidStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SolidStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.accentGradient(color),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark card: today's push figures in white.
class _NotificationsCard extends StatelessWidget {
  final bool failedToLoad;
  final String sent, delivered, failed, read;
  final VoidCallback onTap;
  const _NotificationsCard({
    required this.failedToLoad,
    required this.sent,
    required this.delivered,
    required this.failed,
    required this.read,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value, Color dot) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Black → deep blue → brand blue: dark but with depth.
            colors: [
              AppColors.brandBlack,
              AppColors.brandDeep,
              AppColors.brand,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.shadows([
            BoxShadow(
              color: AppColors.brandBlack.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Notifications today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (failedToLoad)
              Text(
                'Couldn\'t load notifications',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
              )
            else
              Row(
                children: [
                  stat('Sent', sent, AppColors.brandLight),
                  stat('Delivered', delivered, AppColors.positive),
                  stat('Failed', failed, const Color(0xFFFF6B6B)),
                  stat('Read', read, Colors.white),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;
  const _TicketRow({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.accentGradient(
                    priorityColor(ticket.priority),
                  ),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.confirmation_number_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ticket.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            TicketStatusBadge(status: ticket.status),
          ],
        ),
      ),
    );
  }
}

class _Activity {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final DateTime at;
  const _Activity(this.icon, this.color, this.title, this.detail, this.at);

  /// Icon and colour per backend activity type.
  factory _Activity.from(ActivityEntry a) {
    final (icon, color) = switch (a.type) {
      'company_created' => (Icons.business_rounded, AppColors.brand),
      'company_suspended' => (Icons.pause_circle_rounded, AppColors.brandBlack),
      'employee_created' => (Icons.badge_rounded, AppColors.positive),
      'admin_login' => (Icons.login_rounded, AppColors.brandDeep),
      'ticket_created' => (Icons.support_agent_rounded, AppColors.brandLight),
      'notification_sent' => (
        Icons.notifications_active_rounded,
        AppColors.positive,
      ),
      _ => (Icons.bolt_rounded, AppColors.brand),
    };
    return _Activity(icon, color, a.title, a.detail, a.at);
  }
}

class _ActivityRow extends StatelessWidget {
  final _Activity activity;
  final bool isLast;
  const _ActivityRow({required this.activity, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final a = activity;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.accentGradient(a.color),
              ),
              shape: BoxShape.circle,
              boxShadow: AppColors.shadows([
                BoxShadow(
                  color: a.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]),
            ),
            child: Icon(a.icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  a.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textHint, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _ago(a.at),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return DateFormat('d MMM').format(t);
  }
}

enum _Health { ok, slow, down, checking, unknown }

extension on HealthStatus {
  _Health get view => switch (this) {
    HealthStatus.ok => _Health.ok,
    HealthStatus.slow => _Health.slow,
    HealthStatus.down => _Health.down,
    HealthStatus.notConfigured => _Health.unknown,
  };
}

/// One service in the health grid, tinted by its status.
class _HealthTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final _Health status;
  final String? detail;
  const _HealthTile({
    required this.icon,
    required this.label,
    required this.status,
    this.detail,
  });

  /// A tile for one server health check; missing = not reported.
  factory _HealthTile.of(HealthCheck? check, IconData icon, String label) =>
      _HealthTile(
        icon: icon,
        label: label,
        status: check?.status.view ?? _Health.unknown,
        detail:
            check?.latencyMs == null ||
                check!.status == HealthStatus.notConfigured
            ? null
            : '${check.latencyMs} ms',
      );

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (status) {
      _Health.ok => (AppColors.positive, 'Operational'),
      _Health.slow => (AppColors.accentGold, 'Slow'),
      _Health.down => (AppColors.accentRose, 'Down'),
      _Health.checking => (AppColors.brandLight, 'Checking…'),
      _Health.unknown => (AppColors.textHint, 'Not configured'),
    };
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    detail == null ? text : '$text · $detail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
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

class _Unavailable extends StatelessWidget {
  final String text;
  const _Unavailable(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      text,
      style: TextStyle(color: AppColors.textHint, fontSize: 12.5),
    ),
  );
}

class _DashboardSkeleton extends StatelessWidget {
  final bool showMenuButton;
  const _DashboardSkeleton({required this.showMenuButton});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (showMenuButton) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              const SkeletonBox(width: 170, height: 24, radius: 6),
              const Spacer(),
              const SkeletonBox(width: 24, height: 24, radius: 12),
            ],
          ),
          const SizedBox(height: 8),
          const SkeletonBox(width: 210, height: 13, radius: 4),
          const SizedBox(height: 20),

          // Hero card
          Container(
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
                  children: [
                    const SkeletonBox(width: 64, height: 42, radius: 8),
                    const SizedBox(width: 10),
                    const SkeletonBox(width: 84, height: 26, radius: 20),
                    const Spacer(),
                    const SkeletonBox(width: 44, height: 44, radius: 22),
                  ],
                ),
                const SizedBox(height: 12),
                const SkeletonBox(width: 130, height: 12, radius: 4),
                const SizedBox(height: 22),
                const SkeletonBox(height: 40, radius: 8),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Split card
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _skeletonCard(height: 128)),
                const SizedBox(width: 12),
                Expanded(child: _skeletonCard(height: 128)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _skeletonCard(height: 200),
          const SizedBox(height: 20),
          _skeletonCard(height: 190),
        ],
      ),
    );
  }

  Widget _skeletonCard({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 110, height: 14, radius: 4),
          const Spacer(),
          const SkeletonBox(height: 10, radius: 4),
          const SizedBox(height: 8),
          const SkeletonBox(width: 130, height: 10, radius: 4),
        ],
      ),
    );
  }
}
