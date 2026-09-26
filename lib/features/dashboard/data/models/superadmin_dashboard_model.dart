import '../../../support/domain/entities/support_ticket.dart';
import '../../domain/entities/superadmin_dashboard.dart';

/// Parses `GET /dashboard/superadmin`. Tolerant: a missing or odd field
/// falls back to 0 / empty rather than failing the whole dashboard.
SuperadminDashboard superadminDashboardFromJson(Map<String, dynamic> json) {
  Map<String, dynamic> obj(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};
  List list(Object? v) => v is List ? v : const [];
  int i(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  DateTime date(Object? v) => DateTime.tryParse('$v')?.toLocal() ?? DateTime.now();
  T byName<T extends Enum>(List<T> values, Object? v, T fallback) =>
      values.where((e) => e.name == '$v').firstOrNull ?? fallback;

  final companies = obj(json['companies']);
  final tickets = obj(json['tickets']);
  final notifications = obj(json['notifications']);
  final today = obj(notifications['today']);

  return SuperadminDashboard(
    companiesTotal: i(companies['total']),
    companiesActive: i(companies['active']),
    companiesInactive: i(companies['inactive']),
    companiesNewThisMonth: i(companies['new_this_month']),
    weeklySignups: [for (final w in list(companies['weekly_signups'])) i(obj(w)['count'])],
    employeesTotal: i(obj(json['employees'])['total']),
    ticketsOpen: i(tickets['open']),
    ticketsPending: i(tickets['pending']),
    ticketsCritical: i(tickets['critical']),
    recentTickets: [
      for (final raw in list(tickets['recent']))
        () {
          final t = obj(raw);
          final created = date(t['created_at']);
          return SupportTicket(
            id: '${t['id']}',
            subject: '${t['subject'] ?? ''}',
            description: '',
            companyId: '${t['company_id'] ?? ''}',
            companyName: '${t['company_name'] ?? ''}',
            raisedBy: '',
            status: byName(TicketStatus.values, t['status'], TicketStatus.open),
            priority: byName(TicketPriority.values, t['priority'], TicketPriority.medium),
            createdAt: created,
            updatedAt: created,
          );
        }(),
    ],
    unreadNotifications: i(notifications['unread']),
    sentToday: i(today['sent']),
    deliveredToday: i(today['delivered']),
    failedToday: i(today['failed']),
    readToday: i(today['read']),
    recentActivity: [
      for (final raw in list(json['recent_activity']))
        () {
          final a = obj(raw);
          return ActivityEntry(
            type: '${a['type'] ?? ''}',
            title: '${a['title'] ?? ''}',
            detail: '${a['detail'] ?? ''}',
            at: date(a['at']),
          );
        }(),
    ],
    health: {
      for (final e in obj(json['health']).entries)
        e.key: () {
          final h = obj(e.value);
          final error = h['error']?.toString();
          final status = switch ('${h['status']}') {
            'ok' => HealthStatus.ok,
            'slow' => HealthStatus.slow,
            // A service without keys on the server isn't "broken".
            _ when (error ?? '').toLowerCase().contains('not configured') => HealthStatus.notConfigured,
            _ => HealthStatus.down,
          };
          return HealthCheck(
            status: status,
            latencyMs: h['latency_ms'] == null ? null : i(h['latency_ms']),
            error: error,
          );
        }(),
    },
  );
}
