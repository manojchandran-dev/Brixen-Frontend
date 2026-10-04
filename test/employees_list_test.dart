import 'package:brixen/features/employees/domain/entities/employee.dart';
import 'package:brixen/features/employees/presentation/pages/employees_page.dart';
import 'package:brixen/features/employees/presentation/providers/employees_provider.dart';
import 'package:brixen/features/navigation/presentation/providers/nav_modules_provider.dart';
import 'package:brixen/features/permissions/presentation/providers/module_access_provider.dart';
import 'package:brixen/shared/providers/list_filter_options_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _employees = [
  Employee(id: 'm1', companyId: '2', employeeCode: 'EMP0025', firstName: 'Meena', lastName: 'Selvam with a long surname', designation: 'Tailor', department: 'Stitching', employmentType: 'Full-time', createdAt: DateTime(2026, 9, 1)),
  Employee(id: 'm2', companyId: '2', employeeCode: 'EMP0024', firstName: 'Arun', designation: 'Sales Executive', status: 'On Leave', createdAt: DateTime(2026, 9, 2)),
  Employee(id: 'm3', companyId: '2', employeeCode: 'EMP0023', firstName: 'Priya', status: 'Inactive', createdAt: DateTime(2026, 9, 3)),
];

class _Employees extends EmployeesNotifier {
  @override
  Future<List<Employee>> build() async => _employees;
}

void main() {
  testWidgets('Employee cards: role line, chips, status pill', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeesProvider.overrideWith(_Employees.new),
          navModulesProvider.overrideWith((ref) async => const []),
          listFilterOptionsProvider.overrideWith((ref, _) async => const {}),
          moduleAccessProvider.overrideWith(
            (ref, _) => const ModuleAccess(view: true, create: true, edit: true, delete: true),
          ),
        ],
        child: const MaterialApp(home: EmployeesPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Tailor · Stitching'), findsOneWidget);
    expect(find.text('EMP0025'), findsOneWidget);
    expect(find.text('Full-time'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('On leave'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
    expect(find.text('—'), findsOneWidget); // Priya has no role or department
  });
}
