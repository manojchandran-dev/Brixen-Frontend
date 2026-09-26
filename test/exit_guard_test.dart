import 'dart:async';
import 'package:brixen/shared/widgets/exit_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('root screen: back asks to exit instead of closing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExitGuard(child: Text('Root'))));

    unawaited(tester.binding.handlePopRoute());
    await tester.pumpAndSettle();
    expect(find.text('Exit Brixen?'), findsOneWidget);
    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('pushed screen (e.g. Sign-in from Add account): back just goes back', (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(navigatorKey: nav, home: const Text('Below')));
    nav.currentState!.push(MaterialPageRoute(builder: (_) => const ExitGuard(child: Text('Pushed'))));
    await tester.pumpAndSettle();

    unawaited(tester.binding.handlePopRoute());
    await tester.pumpAndSettle();
    expect(find.text('Exit Brixen?'), findsNothing);
    expect(find.text('Below'), findsOneWidget);
    expect(find.text('Pushed'), findsNothing);
  });
}
