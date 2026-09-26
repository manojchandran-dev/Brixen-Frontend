import '../../../support/domain/entities/support_ticket.dart';

/// `GET /api/v1/dashboard/superadmin` — everything the superadmin dashboard
/// shows, already counted by the server ("today" / "this month" in IST).
class SuperadminDashboard {
  final int companiesTotal;
  final int companiesActive;
  final int companiesInactive;
  final int companiesNewThisMonth;

  /// Last 11 weeks, oldest first, zero weeks included.
  final List<int> weeklySignups;
  final int employeesTotal;
  final int ticketsOpen;
  final int ticketsPending;
  final int ticketsCritical;
  final List<SupportTicket> recentTickets;
  final int unreadNotifications;
  final int sentToday, deliveredToday, failedToday, readToday;
  final List<ActivityEntry> recentActivity;
  final Map<String, HealthCheck> health; // api, database, fcm, storage

  const SuperadminDashboard({
    required this.companiesTotal,
    required this.companiesActive,
    required this.companiesInactive,
    required this.companiesNewThisMonth,
    required this.weeklySignups,
    required this.employeesTotal,
    required this.ticketsOpen,
    required this.ticketsPending,
    required this.ticketsCritical,
    required this.recentTickets,
    required this.unreadNotifications,
    required this.sentToday,
    required this.deliveredToday,
    required this.failedToday,
    required this.readToday,
    required this.recentActivity,
    required this.health,
  });
}

/// One `recent_activity` row from the backend activity log.
class ActivityEntry {
  /// company_created, company_suspended, employee_created, admin_login,
  /// ticket_created, notification_sent.
  final String type;
  final String title;
  final String detail;
  final DateTime at;
  const ActivityEntry({required this.type, required this.title, required this.detail, required this.at});
}

enum HealthStatus { ok, slow, down, notConfigured }

class HealthCheck {
  final HealthStatus status;
  final int? latencyMs;
  final String? error;
  const HealthCheck({required this.status, this.latencyMs, this.error});
}
