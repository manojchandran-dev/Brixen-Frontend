import 'package:brixen/features/attendance/domain/attendance.dart';
import 'package:brixen/features/attendance/presentation/pages/lots_pages.dart';
import 'package:brixen/features/employees/domain/entities/employee.dart';
import 'package:brixen/features/employees/presentation/providers/employees_provider.dart';
import 'package:brixen/features/permissions/presentation/providers/module_access_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Employees extends EmployeesNotifier {
  @override
  Future<List<Employee>> build() async => const [];
}

void main() {
  test('a lot in dozens is paid per piece', () {
    final l = PieceLot.fromJson({
      'id': 'PLOT1',
      'employee_id': 3,
      'employee': {'id': 3, 'employee_code': 'EMP3', 'name': 'Anand'},
      'work_type_id': 'WT1',
      'work_type_name': 'Hand',
      'lot_date': '2026-10-28',
      'unit': 'DOZEN',
      'quantity': 800,
      'pieces': 9600,
      'rate': 0.4,
      'amount': 3840,
    });
    expect(l.isDozen, isTrue);
    expect(l.quantityLabel, '800 dozen (9600 pieces)');
    expect(l.amount, 3840);
  });

  testWidgets('the lot form shows dozens × 12 as pieces', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1500 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeesProvider.overrideWith(_Employees.new),
          moduleAccessProvider.overrideWith(
            (ref, _) => const ModuleAccess(
              view: true,
              create: true,
              edit: true,
              delete: true,
            ),
          ),
        ],
        child: const MaterialApp(home: LotFormPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. 800'),
      '800',
    );
    await tester.pump();
    expect(find.textContaining('800 dozen × 12 = 9600 pieces'), findsOneWidget);

    await tester.tap(find.text('Pieces'));
    await tester.pump();
    expect(find.textContaining('800 pieces'), findsOneWidget);
  });
}
