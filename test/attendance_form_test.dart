import 'package:brixen/features/attendance/domain/attendance.dart';
import 'package:brixen/features/attendance/presentation/pages/attendance_form_page.dart';
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

Widget _app(AttendanceRecord edit) => ProviderScope(
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
  child: MaterialApp(
    home: AttendanceFormPage(
      date: edit.workDate,
      today: '2026-10-27',
      edit: edit,
    ),
  ),
);

void main() {
  testWidgets('a shift day stops at three shifts and totals them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        const AttendanceRecord(
          id: 'ATTN000000000001',
          employeeId: '1',
          employeeCode: 'EMP0001',
          employeeName: 'Meena',
          kind: SalaryType.shift,
          salaryPeriod: 'DAILY',
          salary: 600,
          workDate: '2026-10-27',
          recordedLocal: '27 Oct 2026, 9:05 am',
          timezone: 'Asia/Kolkata',
          shifts: [1, 0.5],
          totalShifts: 1.5,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    expect(find.text('1½ shifts'), findsOneWidget);
    expect(find.text('₹900'), findsOneWidget); // 1.5 × ₹600 a day

    await tester.tap(find.text('Add shift 3'));
    await tester.pump();
    // Shift 3 starts at a full shift: 2.5 in all, and no fourth shift.
    expect(find.text('2½ shifts'), findsOneWidget);
    expect(find.text('₹1,500'), findsOneWidget);
    expect(find.textContaining('Add shift'), findsNothing);
  });

  testWidgets('a piece day shows each line at its rate', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        const AttendanceRecord(
          id: 'ATTN000000000002',
          employeeId: '2',
          employeeCode: 'EMP0002',
          employeeName: 'Ravi',
          kind: SalaryType.piece,
          workDate: '2026-10-26',
          recordedLocal: '26 Oct 2026, 6:00 pm',
          timezone: 'Asia/Kolkata',
          pieces: [
            PieceLine(
              workTypeId: 'WTYP000000000001',
              workTypeName: 'T-shirt neck stitching',
              quantity: 20,
              rate: 300,
              amount: 6000,
            ),
          ],
          totalPieces: 20,
          totalAmount: 6000,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('× ₹300'), findsOneWidget);
    expect(find.text('20 pieces'), findsOneWidget);
    expect(find.text('₹6,000'), findsWidgets);
  });
}
