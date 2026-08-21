import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/coming_soon_view.dart';

class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({super.key});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  int _tabIndex = 0;

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning!';
    if (h < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  static String _dateStr() {
    final n = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[n.weekday - 1]}\n${n.day} ${months[n.month - 1]} ${n.year}';
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon'), backgroundColor: AppColors.ink),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNav(activeIndex: _tabIndex, onTap: (i) => setState(() => _tabIndex = i)),
      body: SafeArea(
        child: switch (_tabIndex) {
          2 => const ComingSoonView(icon: Icons.bar_chart_rounded, title: 'Reports', subtitle: 'Your personal activity reports are on the way.'),
          3 => const ComingSoonView(icon: Icons.person_rounded, title: 'More', subtitle: 'Profile, settings and more will live here soon.'),
          _ => ListView(
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
                        boxShadow: [
                          BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.menu_rounded, size: 18, color: AppColors.ink),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(_greeting(), style: const TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        const SizedBox(width: 6),
                        const Text('👋', style: TextStyle(fontSize: 20)),
                      ]),
                      const SizedBox(height: 4),
                      const Text("Here's what's happening today.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                _IconBadge(icon: Icons.notifications_none_rounded, hasDot: true, onTap: () => _comingSoon(context, 'Notifications')),
              ],
            ),
            const SizedBox(height: 16),

            // ── Today Overview hero card ─────────────────────────────
            _TodayOverviewCard(dateStr: _dateStr()),
            const SizedBox(height: 20),

            // ── Quick Actions ─────────────────────────────────────────
            _SectionHeader(title: 'Quick Actions', onViewAll: () => _comingSoon(context, 'Quick actions')),
            const SizedBox(height: 12),
            SizedBox(
              height: 84,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _QuickAction(icon: Icons.play_circle_fill_rounded, label: 'Start Timer', color: AppColors.brand, onTap: () => _comingSoon(context, 'Timer')),
                  _QuickAction(icon: Icons.fact_check_rounded, label: 'My Tasks', color: AppColors.positive, onTap: () => _comingSoon(context, 'Tasks')),
                  _QuickAction(icon: Icons.event_available_rounded, label: 'Attendance', color: AppColors.brand, onTap: () => _comingSoon(context, 'Attendance')),
                  _QuickAction(icon: Icons.bar_chart_rounded, label: 'Reports', color: AppColors.positive, onTap: () => _comingSoon(context, 'Reports')),
                  _QuickAction(icon: Icons.person_add_alt_1_rounded, label: 'Request', color: AppColors.brand, onTap: () => _comingSoon(context, 'Requests')),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── My Tasks + Attendance / Upcoming meeting ──────────────
            _SectionHeader(title: 'My Tasks', onViewAll: () => _comingSoon(context, 'Tasks')),
            const SizedBox(height: 10),
            const _MyTasksCard(),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _AttendanceCard(onView: () => _comingSoon(context, 'Attendance'))),
                const SizedBox(width: 12),
                Expanded(child: _UpcomingMeetingCard(onView: () => _comingSoon(context, 'Meetings'))),
              ],
            ),
            const SizedBox(height: 16),

            // ── Announcement banner ──────────────────────────────────
            _AnnouncementBanner(onReadMore: () => _comingSoon(context, 'Announcements')),
          ],
        ),
        },
      ),
    );
  }
}

// ── Small shared pieces ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w800))),
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
              boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
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

// ── Today Overview hero card ────────────────────────────────────────────

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
        boxShadow: [BoxShadow(color: AppColors.brand.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
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

// ── Quick actions ────────────────────────────────────────────────────────

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
          boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6))],
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
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: AppColors.ink, fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

// ── My Tasks card ────────────────────────────────────────────────────────

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
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _tasks.length; i++) ...[
            _TaskRow(title: _tasks[i].title, sub: _tasks[i].sub, status: _tasks[i].status),
            if (i < _tasks.length - 1) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: AppColors.border)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text('$completed of ${_tasks.length} tasks completed', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              Text('${(pct * 100).round()}%', style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w700)),
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
              Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w600)),
              Text(sub, style: const TextStyle(color: AppColors.textHint, fontSize: 11.5)),
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

// ── Attendance mini card ────────────────────────────────────────────────

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
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(child: Text('Attendance', style: TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w800))),
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
          const Center(child: Text('Checked In', style: TextStyle(color: AppColors.textHint, fontSize: 11.5))),
          const Center(child: Text('09:02 AM', style: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w800))),
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

// ── Upcoming meeting mini card ──────────────────────────────────────────

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
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(child: Text('Upcoming', style: TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w800))),
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
          const Text('Product Review', style: TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w700)),
          const Text('Meeting Room 2', style: TextStyle(color: AppColors.textHint, fontSize: 11.5)),
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

// ── Announcement banner ─────────────────────────────────────────────────

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
                  const Text('Company Announcement', style: TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.positive, borderRadius: BorderRadius.circular(20)),
                    child: const Text('New', style: TextStyle(color: AppColors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 4),
                const Text('Team Outing on 30th Aug 2026.\nGet ready for a fun and memorable day!',
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
