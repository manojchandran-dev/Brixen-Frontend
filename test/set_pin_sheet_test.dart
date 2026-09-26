import 'package:brixen/features/security/presentation/pages/forgot_pin_sheet.dart';
import 'package:brixen/features/security/presentation/pages/set_pin_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Set PIN opens as a bottom sheet and fits a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showSetPinSheet(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.text('New PIN'),
      findsOneWidget,
    ); // no PIN yet → straight to new
    expect(tester.takeException(), isNull);

    // Eye key (left of 0) reveals the typed digits, and hides them again.
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.text('7'));
    await tester.pump();
    expect(find.text('4'), findsOneWidget); // only the key, digits hidden
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(find.text('4'), findsNWidgets(2)); // key + revealed digit
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(find.text('4'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Back on the first step closes the sheet, leaving the page underneath.
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('Forgot PIN opens as a 4-step sheet and fits a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showForgotPinSheet(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot PIN?'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);
    for (final step in ['Email', 'Code', 'New', 'Confirm']) {
      expect(find.text(step), findsOneWidget, reason: step);
    }
    expect(tester.takeException(), isNull);
  });
}
