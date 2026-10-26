import 'dart:async';

import 'package:brixen/shared/widgets/brixen_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a second tap while saving does nothing', (tester) async {
    var calls = 0;
    final saving = Completer<void>();
    Future<void> save() async {
      calls++;
      await saving.future; // the API call still pending
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BrixenButton(label: 'Create Sale', onPressed: save),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Create Sale'));
    await tester.pump();
    // Label swapped for the spinner while saving.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(BrixenButton), warnIfMissed: false);
    await tester.tap(find.byType(BrixenButton), warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);

    saving.complete();
    await tester.pumpAndSettle();
    expect(find.text('Create Sale'), findsOneWidget);
    await tester.tap(find.text('Create Sale'));
    await tester.pump();
    expect(calls, 2, reason: 'usable again once the save finished');
  });
}
