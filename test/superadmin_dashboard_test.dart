import 'package:brixen/features/dashboard/data/models/superadmin_dashboard_model.dart';
import 'package:brixen/features/dashboard/domain/entities/superadmin_dashboard.dart';
import 'package:brixen/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:brixen/features/support/domain/entities/support_ticket.dart';
import 'package:brixen/shared/widgets/welcome_dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shape of GET /dashboard/superadmin, as the backend returns it.
final _json = <String, dynamic>{
  'companies': {
    'total': 3, 'active': 1, 'inactive': 2, 'new_this_month': 2,
    'weekly_signups': [
      for (var i = 0; i < 11; i++) {'week_start': '2026-07-13', 'count': i == 10 ? 2 : 0},
    ],
  },
  'employees': {'total': 3},
  'tickets': {
    'open': 3, 'pending': 0, 'critical': 1,
    'recent': [
      {'id': 'T1', 'subject': 'Invoice PDF not downloading', 'company_name': 'MJP tex',
        'status': 'inProgress', 'priority': 'urgent', 'created_at': '2026-09-24T09:15:00Z'},
    ],
  },
  'notifications': {'unread': 6, 'today': {'sent': 1, 'delivered': 3, 'failed': 0, 'read': 1}},
  'recent_activity': [
    {'type': 'company_created', 'title': 'Company created', 'detail': 'Kaveri Textiles', 'ref_id': '42', 'at': '2026-09-24T09:14:52Z'},
    {'type': 'admin_login', 'title': 'Admin login', 'detail': 'admin@brixen.in', 'at': '2026-09-24T08:00:00Z'},
    {'type': 'something_new', 'title': 'Future event', 'detail': 'x', 'at': '2026-09-23T08:00:00Z'},
  ],
  'health': {
    'api': {'status': 'ok', 'latency_ms': 42},
    'database': {'status': 'ok', 'latency_ms': 8},
    'fcm': {'status': 'down', 'error': 'not configured'},
    'storage': {'status': 'down', 'error': 'timeout'},
  },
};

void main() {
  test('parses the superadmin dashboard response', () {
    final d = superadminDashboardFromJson(_json);
    expect(d.companiesTotal, 3);
    expect(d.companiesInactive, 2);
    expect(d.weeklySignups, hasLength(11));
    expect(d.ticketsCritical, 1);
    expect(d.recentTickets.single.status, TicketStatus.inProgress);
    expect(d.recentTickets.single.priority, TicketPriority.urgent);
    expect(d.unreadNotifications, 6);
    expect(d.deliveredToday, 3);
    expect(d.recentActivity.map((a) => a.type), ['company_created', 'admin_login', 'something_new']);
    expect(d.health['api']!.latencyMs, 42);
    // A service without keys isn't "down"; a real failure is.
    expect(d.health['fcm']!.status, HealthStatus.notConfigured);
    expect(d.health['storage']!.status, HealthStatus.down);
  });

  test('missing fields fall back instead of throwing', () {
    final d = superadminDashboardFromJson(const {});
    expect(d.companiesTotal, 0);
    expect(d.recentActivity, isEmpty);
    expect(d.health, isEmpty);
  });

  testWidgets('dashboard renders every section from the one call, at phone size', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [superadminDashboardProvider.overrideWith((ref) async => superadminDashboardFromJson(_json))],
      child: const MaterialApp(home: Scaffold(body: WelcomeDashboardView(showMenuButton: false))),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Good'), findsOneWidget); // greeting card kept
    expect(find.text('Companies'), findsOneWidget);
    expect(find.text('1 active'), findsOneWidget);
    expect(find.text('Unread Notifications'), findsOneWidget);

    final list = find.byType(Scrollable).first;
    for (final text in ['Support', 'Notifications today', 'Admin login', 'System Health', 'Not configured']) {
      await tester.scrollUntilVisible(find.text(text).first, 300, scrollable: list);
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(find.textContaining('Down'), findsOneWidget); // storage timeout
    expect(tester.takeException(), isNull);
  });
}
