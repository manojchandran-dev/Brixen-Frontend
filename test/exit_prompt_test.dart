import 'dart:async';
import 'package:brixen/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'phone back on the first screen asks before exiting',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const ProviderScope(child: BrixenApp()));
      // Fixed pumps, not pumpAndSettle — the splash animation never settles.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));

      // System back with nothing to go back to → the exit prompt, not an exit.
      // Not awaited: the back handler waits for the prompt's answer.
      unawaited(tester.binding.handlePopRoute());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Exit Brixen?'), findsOneWidget);

      // Back again just closes the prompt.
      unawaited(tester.binding.handlePopRoute());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Exit Brixen?'), findsNothing);

      await tester.pumpWidget(const SizedBox()); // dispose the app + timers
      await tester.pump(const Duration(seconds: 1));
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
