import 'package:brixen/features/security/presentation/cubit/security_cubit.dart';
import 'package:brixen/features/security/presentation/cubit/security_state.dart';
import 'package:brixen/features/security/presentation/pages/security_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Skips the device PIN/biometric lookups.
class _Cubit extends SecurityCubit {
  @override
  Future<void> load() async => emit(const SecurityState(
        status: SecurityStatus.ready,
        isPinEnabled: true,
        isBiometricAvailable: true,
      ));
}

void main() {
  // Also guards the bottom-nav layout: without extendBody the body is 0px tall.
  testWidgets('App Lock page shows its status and settings with the nav bar', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: BlocProvider<SecurityCubit>(
          create: (_) => _Cubit(),
          child: const SecuritySettingsPage(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('App Lock is on'), findsOneWidget);
    expect(find.text('PIN Lock'), findsOneWidget);
    expect(find.text('Change PIN'), findsOneWidget);
    expect(find.text('Fingerprint'), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
  });
}
