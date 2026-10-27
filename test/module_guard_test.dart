import 'package:brixen/features/employees/data/models/employee_model.dart';
import 'package:brixen/features/permissions/presentation/providers/module_access_provider.dart';
import 'package:brixen/shared/widgets/module_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({required bool ready, required ModuleAccess access}) =>
    ProviderScope(
      overrides: [
        moduleAccessReadyProvider.overrideWithValue(ready),
        moduleAccessProvider.overrideWith((ref, _) => access),
      ],
      child: const MaterialApp(
        home: ModuleGuard(module: 'Sales', child: Text('Sales screen')),
      ),
    );

void main() {
  testWidgets('a granted module shows its screen', (tester) async {
    await tester.pumpWidget(_app(ready: true, access: ModuleAccess.full));
    expect(find.text('Sales screen'), findsOneWidget);
  });

  testWidgets('a module not granted shows no access, not the screen', (
    tester,
  ) async {
    await tester.pumpWidget(_app(ready: true, access: ModuleAccess.none));
    expect(find.text('Sales screen'), findsNothing);
    expect(find.text('No access to Sales'), findsOneWidget);
  });

  testWidgets('waits for permissions instead of flashing no access', (
    tester,
  ) async {
    await tester.pumpWidget(_app(ready: false, access: ModuleAccess.none));
    expect(find.text('Sales screen'), findsNothing);
    expect(find.text('No access to Sales'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  test('employee login: setup email status and first sign-in pending', () {
    final pending = EmployeeModel.fromJson({
      'id': 1,
      'first_name': 'Ravi',
      'email': 'ravi@shop.in',
      'users': {
        'email': 'ravi@shop.in',
        'deleted_at': null,
        'must_change_password': true,
        'setup_email_sent_at': '2026-10-27T03:35:00Z',
        'setup_email_error': null,
      },
    });
    expect(pending.loginActive, isTrue);
    expect(pending.loginPending, isTrue);
    expect(pending.setupEmailSentAt, DateTime.utc(2026, 10, 27, 3, 35));
    expect(pending.setupEmailError, isNull);

    final failed = EmployeeModel.fromJson({
      'id': 2,
      'first_name': 'Meena',
      'users': {
        'email': 'meena@shop.in',
        'deleted_at': null,
        'must_change_password': true,
        'setup_email_error': 'Invalid to address',
      },
    });
    expect(failed.setupEmailError, 'Invalid to address');

    final done = EmployeeModel.fromJson({
      'id': 3,
      'first_name': 'Sita',
      'users': {'email': 's@shop.in', 'deleted_at': null},
    });
    expect(done.loginPending, isFalse);
    expect(done.copyWith(firstName: 'Sita R').loginActive, isTrue);
  });
}
