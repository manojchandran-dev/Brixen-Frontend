import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../support/domain/entities/support_ticket.dart';
import '../../../support/presentation/widgets/ticket_labels.dart';
import 'report_kit.dart';
import 'superadmin_reports_data.dart';

final _short = DateFormat('d MMM');
String _day(Object? v) => at(v) == null ? '' : _short.format(at(v)!);

typedef _Body =
    List<Widget> Function(Map<String, dynamic> data, ReportPeriod period);

/// One report tab: holds the date filter and loads
/// `GET /reports/superadmin/{tab}` for it; [body] lays out the response.
class _ReportTab extends ConsumerStatefulWidget {
  final String tab;
  final _Body body;
  const _ReportTab(this.tab, this.body);

  @override
  ConsumerState<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends ConsumerState<_ReportTab> {
  ReportPeriod period = const ReportPeriod(ReportRange.month);

  @override
  Widget build(BuildContext context) {
    final provider = superadminReportProvider((widget.tab, period));
    final async = ref.watch(provider);
    return ReportPage(
      range: period,
      onRange: (p) => setState(() => period = p),
      loading: async.isLoading,
      error: async.error,
      onRetry: () => ref.invalidate(provider),
      body: () => widget.body(async.value ?? const {}, period),
    );
  }
}

// ── 1. Company Report ───────────────────────────────────────────────────────

class CompanyReportPage extends StatelessWidget {
  const CompanyReportPage({super.key});

  @override
  Widget build(BuildContext context) => _ReportTab('company', (d, p) {
    final s = obj(d['summary']);
    final status = obj(d['status']);
    final recent = rows(d['recent']);
    return [
      ReportSummary([
        ReportStat(
          Icons.business_rounded,
          'Total companies',
          '${n(s['total'])}',
          AppColors.brand,
          allTime: true,
        ),
        ReportStat(
          Icons.add_business_rounded,
          'New',
          '${n(s['new'])}',
          AppColors.positive,
        ),
        ReportStat(
          Icons.verified_rounded,
          'Active',
          '${n(s['active'])}',
          AppColors.brandDeep,
          allTime: true,
        ),
        ReportStat(
          Icons.pause_circle_rounded,
          'Inactive',
          '${n(s['inactive'])}',
          AppColors.brandBlack,
          allTime: true,
        ),
      ]),
      ReportCard(
        title: 'Company growth',
        caption: 'New companies',
        child: ReportTrendChart(buckets: trend(d['trend'])),
      ),
      ReportCard(
        title: 'Company status',
        allTime: true,
        child: ReportBreakdown([
          BreakdownItem('Active', n(status['active']), AppColors.positive),
          BreakdownItem(
            'Inactive',
            n(status['inactive']),
            AppColors.brandBlack,
          ),
          BreakdownItem(
            'Setup pending',
            n(status['setup_pending']),
            AppColors.brandLight,
          ),
        ]),
      ),
      ReportCard(
        title: 'New companies',
        child: recent.isEmpty
            ? const ReportEmpty('No new companies in this period')
            : Column(
                children: [
                  for (final c in recent)
                    ReportRow(
                      icon: Icons.business_rounded,
                      color: c['is_active'] == true
                          ? AppColors.positive
                          : AppColors.brandBlack,
                      title: str(c['name']),
                      subtitle:
                          '${str(c['owner_name']).isEmpty ? '—' : str(c['owner_name'])} · ${c['is_active'] == true ? 'Active' : 'Inactive'}',
                      trailing: _day(c['created_at']),
                    ),
                ],
              ),
      ),
    ];
  });
}

// ── 2. User & Employee Report ───────────────────────────────────────────────

class UsersReportPage extends StatelessWidget {
  const UsersReportPage({super.key});

  static const _palette = [
    AppColors.brand,
    AppColors.positive,
    AppColors.brandDeep,
    AppColors.brandLight,
    AppColors.brandBlack,
  ];

  @override
  Widget build(BuildContext context) => _ReportTab('users', (d, p) {
    final s = obj(d['summary']);
    final byCompany = rows(d['by_company']);
    return [
      ReportSummary([
        ReportStat(
          Icons.badge_rounded,
          'Total employees',
          '${n(s['total'])}',
          AppColors.brand,
          allTime: true,
        ),
        ReportStat(
          Icons.person_add_alt_1_rounded,
          'New',
          '${n(s['new'])}',
          AppColors.positive,
        ),
        ReportStat(
          Icons.check_circle_rounded,
          'Active',
          '${n(s['active'])}',
          AppColors.brandDeep,
          allTime: true,
        ),
        ReportStat(
          Icons.person_off_rounded,
          'Inactive / on leave',
          '${n(s['inactive'])}',
          AppColors.brandBlack,
          allTime: true,
        ),
      ]),
      ReportCard(
        title: 'Employee growth',
        caption: 'New employees',
        child: ReportTrendChart(buckets: trend(d['trend'])),
      ),
      if (d.containsKey('active_users'))
        ReportCard(
          title: 'Active users',
          caption: 'Signed in',
          child: ReportRow(
            icon: Icons.login_rounded,
            color: AppColors.positive,
            title: '${n(d['active_users'])} users signed in',
            subtitle: 'Distinct users with a login in this period',
          ),
        ),
      ReportCard(
        title: 'Company-wise employees',
        caption: 'Employees by company',
        allTime: true,
        child: ReportBreakdown([
          for (final (i, c) in byCompany.indexed)
            BreakdownItem(
              str(c['company_name']).isEmpty
                  ? 'Unknown company'
                  : str(c['company_name']),
              n(c['count']),
              _palette[i % _palette.length],
            ),
        ]),
      ),
    ];
  });
}

// ── 3. Notification Report ──────────────────────────────────────────────────

class NotificationReportPage extends StatelessWidget {
  const NotificationReportPage({super.key});

  @override
  Widget build(BuildContext context) => _ReportTab('notifications', (d, p) {
    final s = obj(d['summary']);
    final rvu = obj(d['read_vs_unread']);
    final recent = rows(d['recent']);
    return [
      ReportSummary([
        ReportStat(
          Icons.send_rounded,
          'Sent',
          '${n(s['sent'])}',
          AppColors.brand,
        ),
        ReportStat(
          Icons.done_all_rounded,
          'Delivered',
          '${n(s['delivered'])}',
          AppColors.positive,
        ),
        ReportStat(
          Icons.error_outline_rounded,
          'Failed',
          '${n(s['failed'])}',
          AppColors.brandBlack,
        ),
        ReportStat(
          Icons.visibility_rounded,
          'Read',
          '${n(s['read'])}',
          AppColors.brandDeep,
        ),
      ]),
      ReportCard(
        title: 'Notification trend',
        caption: 'Sent',
        child: ReportTrendChart(buckets: trend(d['trend'])),
      ),
      ReportCard(
        title: 'Read vs unread',
        caption: 'Of delivered notifications',
        child: ReportBreakdown([
          BreakdownItem('Read', n(rvu['read']), AppColors.positive),
          BreakdownItem('Unread', n(rvu['unread']), AppColors.brandLight),
        ]),
      ),
      ReportCard(
        title: 'Recent notifications',
        child: recent.isEmpty
            ? const ReportEmpty('Nothing sent in this period')
            : Column(
                children: [
                  for (final r in recent)
                    ReportRow(
                      icon: Icons.notifications_active_rounded,
                      color: n(r['failed']) > 0
                          ? AppColors.brandBlack
                          : AppColors.brand,
                      title: str(r['title']),
                      subtitle:
                          '${n(r['delivered'])}/${n(r['recipients'])} delivered · ${n(r['opened'])} read',
                      trailing: _day(r['sent_at']),
                    ),
                ],
              ),
      ),
    ];
  });
}

// ── 4. Support Ticket Report ────────────────────────────────────────────────

class SupportReportPage extends StatelessWidget {
  const SupportReportPage({super.key});

  @override
  Widget build(BuildContext context) => _ReportTab('support', (d, p) {
    final s = obj(d['summary']);
    final pr = obj(d['by_priority']);
    final st = obj(d['by_status']);
    // The API says "critical" for what the app stores as urgent.
    const priorities = {
      'critical': TicketPriority.urgent,
      'high': TicketPriority.high,
      'medium': TicketPriority.medium,
      'low': TicketPriority.low,
    };
    return [
      ReportSummary([
        ReportStat(
          Icons.confirmation_number_rounded,
          'Tickets raised',
          '${n(s['raised'])}',
          AppColors.brand,
        ),
        ReportStat(
          Icons.hourglass_top_rounded,
          'Open',
          '${n(s['open'])}',
          AppColors.brandDeep,
        ),
        ReportStat(
          Icons.pending_actions_rounded,
          'Pending',
          '${n(s['pending'])}',
          AppColors.brandBlack,
        ),
        ReportStat(
          Icons.task_alt_rounded,
          'Resolved',
          '${n(s['resolved'])}',
          AppColors.positive,
        ),
      ]),
      ReportCard(
        title: 'Resolution trend',
        caption: 'Tickets resolved',
        child: ReportTrendChart(buckets: trend(d['trend'])),
      ),
      ReportCard(
        title: 'By priority',
        caption: 'Tickets raised',
        child: ReportBreakdown([
          for (final MapEntry(:key, :value) in priorities.entries)
            BreakdownItem(
              key == 'critical' ? 'Critical' : priorityLabel(value),
              n(pr[key]),
              priorityColor(value),
            ),
        ]),
      ),
      ReportCard(
        title: 'By status',
        child: ReportBreakdown([
          BreakdownItem('Open', n(st['open']), AppColors.accentGold),
          BreakdownItem('In progress', n(st['in_progress']), AppColors.brand),
          BreakdownItem('Pending', n(st['pending']), AppColors.brandDeep),
          BreakdownItem('Resolved', n(st['resolved']), AppColors.positive),
          BreakdownItem('Closed', n(st['closed']), AppColors.brandBlack),
        ]),
      ),
    ];
  });
}

// ── 5. Chatbot Report ───────────────────────────────────────────────────────

class ChatbotReportPage extends StatelessWidget {
  const ChatbotReportPage({super.key});

  @override
  Widget build(BuildContext context) => _ReportTab('chatbot', (d, p) {
    final s = obj(d['summary']);
    final awaiting = rows(d['awaiting_list']);
    return [
      ReportSummary([
        ReportStat(
          Icons.forum_rounded,
          'Conversations',
          '${n(s['total'])}',
          AppColors.brand,
          allTime: true,
        ),
        ReportStat(
          Icons.bolt_rounded,
          'Active',
          '${n(s['active'])}',
          AppColors.positive,
        ),
        ReportStat(
          Icons.mark_chat_read_rounded,
          'Replied',
          '${n(s['replied'])}',
          AppColors.brandDeep,
        ),
        ReportStat(
          Icons.mark_chat_unread_rounded,
          'Awaiting reply',
          '${n(s['awaiting'])}',
          AppColors.brandBlack,
        ),
      ]),
      ReportCard(
        title: 'Conversation activity',
        caption: 'Last message',
        child: ReportTrendChart(buckets: trend(d['trend'])),
      ),
      ReportCard(
        title: 'Awaiting a reply',
        child: awaiting.isEmpty
            ? const ReportEmpty('Every conversation has a reply')
            : Column(
                children: [
                  for (final c in awaiting)
                    ReportRow(
                      icon: Icons.chat_bubble_rounded,
                      color: AppColors.brandBlack,
                      title: str(c['company_name']),
                      subtitle: str(c['preview']),
                      trailing: _day(c['sent_at']),
                    ),
                ],
              ),
      ),
    ];
  });
}

// ── 6. Activity / Audit Report ──────────────────────────────────────────────

class ActivityReportPage extends StatelessWidget {
  const ActivityReportPage({super.key});

  // Event type → icon + colour. Both spellings: this tab sends
  // employee_added / ticket_raised, the dashboard *_created.
  static (IconData, Color) _look(String type) => switch (type) {
    'company_created' => (Icons.business_rounded, AppColors.brand),
    'employee_added' ||
    'employee_created' => (Icons.badge_rounded, AppColors.positive),
    'ticket_raised' ||
    'ticket_created' => (Icons.support_agent_rounded, AppColors.brandDeep),
    'notification_sent' => (
      Icons.notifications_active_rounded,
      AppColors.brandBlack,
    ),
    'admin_login' => (Icons.login_rounded, AppColors.brandLight),
    'company_suspended' => (Icons.block_rounded, AppColors.brandBlack),
    _ => (Icons.bolt_rounded, AppColors.brand),
  };

  @override
  Widget build(BuildContext context) => _ReportTab('activity', (d, p) {
    final s = obj(d['summary']);
    final recent = rows(d['recent']);
    return [
      ReportSummary([
        ReportStat(
          Icons.bolt_rounded,
          'Total events',
          '${n(s['total'])}',
          AppColors.brand,
        ),
        ReportStat(
          Icons.business_rounded,
          'Companies created',
          '${n(s['companies_created'])}',
          AppColors.positive,
        ),
        ReportStat(
          Icons.badge_rounded,
          'Employees added',
          '${n(s['employees_added'])}',
          AppColors.brandDeep,
        ),
        ReportStat(
          Icons.support_agent_rounded,
          'Tickets raised',
          '${n(s['tickets_raised'])}',
          AppColors.brandBlack,
        ),
      ]),
      ReportCard(
        title: 'Activity trend',
        caption: 'All events',
        child: ReportTrendChart(buckets: trend(d['trend'])),
      ),
      ReportCard(
        title: 'Recent activity',
        child: recent.isEmpty
            ? const ReportEmpty('No activity in this period')
            : Column(
                children: [
                  for (final e in recent)
                    () {
                      final (icon, color) = _look(str(e['type']));
                      final actor = str(e['actor']);
                      return ReportRow(
                        icon: icon,
                        color: color,
                        title: str(e['title']),
                        subtitle: actor.isEmpty
                            ? str(e['detail'])
                            : '${str(e['detail'])} · $actor',
                        trailing: _day(e['at']),
                      );
                    }(),
                ],
              ),
      ),
    ];
  });
}
