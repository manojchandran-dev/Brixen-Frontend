import 'package:brixen/features/attendance/domain/attendance.dart';
import 'package:brixen/features/attendance/presentation/attendance_providers.dart';
import 'package:brixen/features/attendance/presentation/pages/my_work_page.dart';
import 'package:brixen/features/employees/domain/entities/employee.dart';
import 'package:brixen/features/navigation/presentation/providers/nav_modules_provider.dart';
import 'package:brixen/shared/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('an employee\'s home builds (no grey error screen)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final me = Employee(
      id: '7',
      employeeCode: 'EMP0034',
      firstName: 'Manoj',
      salaryType: SalaryType.piece,
      createdAt: DateTime(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          navModulesProvider.overrideWith((ref) async => const []),
          myEmployeeProvider.overrideWith(
            (ref) async =>
                (employee: me, companyName: 'MJP Tex', timezone: 'Asia/Kolkata'),
          ),
          myAttendanceProvider.overrideWith(
            (ref, _) async => const MyAttendance(
              list: AttendanceList(
                items: [],
                timezone: 'Asia/Kolkata',
                today: '2026-10-28',
              ),
              days: 0,
              shifts: 0,
              pieces: 0,
              amount: 0,
              from: '2026-10-01',
              to: '2026-10-28',
            ),
          ),
        ],
        child: const MaterialApp(
          home: AppShell(activeIndex: 0, body: MyWorkPage()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Manoj'), findsOneWidget);
    expect(find.text('My payslips'), findsOneWidget);
  });
}
