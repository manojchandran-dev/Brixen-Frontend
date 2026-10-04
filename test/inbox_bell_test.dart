import 'package:brixen/features/notifications/presentation/providers/inbox_provider.dart';
import 'package:brixen/features/notifications/presentation/widgets/inbox_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

InboxItem _item(String id, String title, {bool read = false}) => InboxItem(
  id: id,
  title: title,
  message: 'Details for $title',
  priority: id == '1' ? 'urgent' : 'normal',
  sentAt: DateTime.now().subtract(const Duration(hours: 1)),
  read: read,
  target: const {'open_on_tap': 'dashboard'},
);

Future<void> _pump(WidgetTester tester, Inbox inbox) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [inboxProvider.overrideWith((ref) async => inbox)],
      child: const MaterialApp(
        home: Scaffold(body: Center(child: InboxBell())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Bell shows the unread count and opens the inbox sheet', (
    tester,
  ) async {
    await _pump(
      tester,
      Inbox([
        _item('1', 'Maintenance tonight'),
        _item('2', 'New feature', read: true),
      ], 19),
    );
    expect(find.text('19'), findsOneWidget); // meta.unread, not page count

    await tester.tap(find.byType(InboxBell));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('19 unread'), findsOneWidget);
    expect(find.text('Mark all as read'), findsOneWidget);
    expect(find.text('Maintenance tonight'), findsOneWidget);
    expect(find.text('New feature'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget); // day heading

    // Tapping a card keeps the sheet open (marks read + expands).
    await tester.tap(find.text('Maintenance tonight'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Maintenance tonight'), findsOneWidget);

    // Unread tab hides the read one.
    await tester.tap(find.text('Unread · 19'));
    await tester.pumpAndSettle();
    expect(find.text('Maintenance tonight'), findsOneWidget);
    expect(find.text('New feature'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('No badge and no "Mark all" when everything is read', (
    tester,
  ) async {
    await _pump(tester, Inbox([_item('2', 'Old news', read: true)], 0));
    expect(find.text('0'), findsNothing);
    await tester.tap(find.byType(InboxBell));
    await tester.pumpAndSettle();
    expect(find.text('All caught up'), findsOneWidget);
    expect(find.text('Mark all as read'), findsNothing);
  });
}
