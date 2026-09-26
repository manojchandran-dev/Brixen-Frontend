import 'package:brixen/features/reports/presentation/superadmin/superadmin_report_pages.dart';
import 'package:brixen/features/reports/presentation/superadmin/superadmin_reports_data.dart';
import 'package:brixen/features/reports/presentation/superadmin/superadmin_reports_hub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _at = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
final _trend = [
  for (final (i, l) in ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].indexed)
    {'label': l, 'count': i % 3},
];

/// Sample responses shaped like GET /reports/superadmin/{tab}.
final _fake = <String, Map<String, dynamic>>{
  'company': {
    'summary': {'total': 3, 'new': 3, 'active': 1, 'inactive': 2},
    'trend': _trend,
    'status': {'active': 1, 'inactive': 2, 'setup_pending': 1},
    'recent': [
      {
        'id': 2,
        'name': 'MJP tex',
        'owner_name': 'Manoj',
        'is_active': true,
        'created_at': _at,
      },
    ],
  },
  'users': {
    'summary': {'total': 3, 'new': 1, 'active': 3, 'inactive': 0},
    'trend': _trend,
    'by_company': [
      {'company_id': 2, 'company_name': 'MJP tex', 'count': 3},
    ],
    'active_users': 2,
  },
  'notifications': {
    'summary': {'sent': 19, 'delivered': 12, 'failed': 4, 'read': 0},
    'trend': _trend,
    'read_vs_unread': {'read': 0, 'unread': 12},
    'recent': [
      {
        'id': 'p1',
        'title': 'Maintenance tonight',
        'recipients': 3,
        'delivered': 3,
        'opened': 1,
        'failed': 0,
        'sent_at': _at,
      },
    ],
  },
  'support': {
    'summary': {'raised': 6, 'open': 3, 'pending': 0, 'resolved': 3},
    'trend': _trend,
    'by_priority': {'critical': 2, 'high': 2, 'medium': 1, 'low': 1},
    'by_status': {
      'open': 2,
      'in_progress': 1,
      'pending': 0,
      'resolved': 2,
      'closed': 1,
    },
  },
  'chatbot': {
    'summary': {'total': 3, 'active': 1, 'replied': 0, 'awaiting': 1},
    'trend': _trend,
    'awaiting_list': [
      {
        'conversation_id': 2,
        'company_name': 'MJP tex',
        'preview': 'Got it, thanks!',
        'sent_at': _at,
      },
    ],
  },
  'activity': {
    'summary': {
      'total': 28,
      'companies_created': 3,
      'employees_added': 3,
      'tickets_raised': 6,
    },
    'trend': _trend,
    'recent': [
      {
        'type': 'ticket_raised',
        'title': 'Ticket raised',
        'detail': 'Invoice PDF · MJP tex',
        'at': _at,
      },
      {
        'type': 'employee_created',
        'title': 'Employee added',
        'detail': 'Priya',
        'actor': 'admin',
        'at': _at,
      },
      {
        'type': 'something_new',
        'title': 'Unknown event',
        'detail': '',
        'at': null,
      },
    ],
  },
};

final _overrides = [
  superadminReportProvider.overrideWith((ref, key) async => _fake[key.$1]!),
];

void main() {
  test(
    'ReportPeriod sends range (+ from/to for custom) and compares by value',
    () {
      expect(const ReportPeriod(ReportRange.week).query, {'range': 'week'});
      final custom = ReportPeriod(
        ReportRange.custom,
        DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 20)),
      );
      expect(custom.query, {
        'range': 'custom',
        'from': '2026-09-01',
        'to': '2026-09-20',
      });
      expect(
        custom,
        ReportPeriod(
          ReportRange.custom,
          DateTimeRange(
            start: DateTime(2026, 9, 1),
            end: DateTime(2026, 9, 20),
          ),
        ),
      );
      expect(custom.label, contains('–'));
    },
  );

  test('Tolerant readers: missing or odd fields read as 0 / empty', () {
    expect(n(null), 0);
    expect(n('7'), 7);
    expect(rows('nope'), isEmpty);
    expect(
      trend([
        {'label': 'Sep', 'count': 4},
        'junk',
      ]).map((b) => b.count),
      [4, 0],
    );
  });

  Future<void> pumpPhone(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides,
        child: MaterialApp(home: page),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Reports is one page: six tabs, switching in place', (
    tester,
  ) async {
    await pumpPhone(tester, const Scaffold(body: SuperadminReportsHub()));
    expect(tester.takeException(), isNull);
    for (final tab in [
      'Company',
      'Users',
      'Notifications',
      'Support',
      'Chatbot',
      'Activity',
    ]) {
      expect(find.text(tab), findsWidgets, reason: tab);
    }
    expect(find.text('Company growth'), findsOneWidget); // first tab showing

    // The tab bar scrolls; bring the tab into view first, like a user would.
    await tester.ensureVisible(find.text('Support').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Support').first);
    await tester.pumpAndSettle();
    expect(find.text('Resolution trend'), findsOneWidget);
    expect(find.text('Company growth'), findsNothing);

    // Swipe to the next tab.
    await tester.drag(find.byType(TabBarView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Conversation activity'), findsOneWidget); // Chatbot
    expect(tester.takeException(), isNull);
  });

  testWidgets('Custom opens the date range bottom sheet (not a page)', (
    tester,
  ) async {
    await pumpPhone(tester, const Scaffold(body: CompanyReportPage()));
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(find.text('Select Date Range'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Server numbers reach the screen', (tester) async {
    await pumpPhone(tester, const Scaffold(body: SupportReportPage()));
    expect(
      find.text('Critical'),
      findsOneWidget,
    ); // API "critical" = stored urgent
    await pumpPhone(tester, const Scaffold(body: UsersReportPage()));
    expect(find.text('2 users signed in'), findsOneWidget); // active_users
    await pumpPhone(tester, const Scaffold(body: ChatbotReportPage()));
    expect(find.text('Got it, thanks!'), findsOneWidget);
  });

  final pages = <String, Widget>{
    'Company Report': const CompanyReportPage(),
    'User & Employee Report': const UsersReportPage(),
    'Notification Report': const NotificationReportPage(),
    'Support Ticket Report': const SupportReportPage(),
    'Chatbot Report': const ChatbotReportPage(),
    'Activity Report': const ActivityReportPage(),
  };
  pages.forEach((title, page) {
    testWidgets('$title renders every range without layout errors', (
      tester,
    ) async {
      await pumpPhone(tester, Scaffold(body: page));
      for (final r in [ReportRange.week, ReportRange.month, ReportRange.all]) {
        await tester.tap(find.text(ReportPeriod(r).label));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '$title · ${r.name}');
      }
      // Scroll to the end: every card below the fold lays out too.
      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: '$title scrolled');
    });
  });
}
