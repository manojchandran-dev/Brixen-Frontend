import 'package:brixen/features/attendance/domain/attendance.dart';
import 'package:brixen/features/attendance/presentation/pages/attendance_form_page.dart';
import 'package:brixen/features/employees/domain/entities/employee.dart';
import 'package:brixen/features/employees/presentation/providers/employees_provider.dart';
import 'package:brixen/features/payroll/domain/payroll.dart';
import 'package:brixen/features/payroll/presentation/pages/salary_generation_pages.dart';
import 'package:brixen/features/payroll/presentation/payroll_providers.dart';
import 'package:brixen/features/permissions/presentation/providers/module_access_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Employees extends EmployeesNotifier {
  @override
  Future<List<Employee>> build() async => const [];
}

const _full = ModuleAccess(view: true, create: true, edit: true, delete: true);

Payslip _slip(String name, String type, double net, {double units = 1}) =>
    Payslip(
      id: 'PSLP$name',
      runId: 'PRUN1',
      month: '2026-10',
      periodTo: DateTime(2026, 10, 31),
      workingDays: 27,
      status: PayrollStatus.draft,
      employeeId: name,
      employeeCode: 'EMP-$name',
      employeeName: name,
      salaryType: type,
      rate: 600,
      units: units,
      daysPresent: units,
      gross: net,
      net: net,
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('a draft month: totals, actions and a payslip per employee', (
    tester,
  ) async {
    _phone(tester);
    final run = PayrollRun(
      id: 'PRUN1',
      month: '2026-10',
      workingDays: 27,
      status: PayrollStatus.draft,
      totalGross: 30600,
      totalNet: 30600,
      payslipCount: 2,
      payslips: [
        _slip('Ravi', SalaryType.shift, 14400, units: 24),
        _slip('Sita', SalaryType.monthly, 16200, units: 16.5),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moduleAccessProvider.overrideWith((ref, _) => _full),
          payrollRunProvider.overrideWith((ref, id) async => run),
        ],
        child: const MaterialApp(home: SalaryRunPage(runId: 'PRUN1')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('Count again'), findsOneWidget);
    expect(find.text('Confirm salary'), findsOneWidget);
    expect(find.text('Send payslips'), findsNothing); // not confirmed yet
    expect(find.text('Ravi'), findsOneWidget);
    // Each payslip shows how its pay was worked out.
    expect(find.textContaining('24 shifts × ₹600'), findsOneWidget);
    expect(find.textContaining('16½ days × ₹22.22'), findsOneWidget);

    // Filter to monthly staff.
    await tester.tap(find.text('Monthly'));
    await tester.pump();
    expect(find.text('Ravi'), findsNothing);
    expect(find.text('Sita'), findsOneWidget);
  });

  testWidgets('salary generation home: month picker and past months', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moduleAccessProvider.overrideWith((ref, _) => _full),
          payrollRunsProvider.overrideWith(
            (ref) async => const [
              PayrollRun(
                id: 'PRUN1',
                month: '2026-09',
                workingDays: 26,
                status: PayrollStatus.finalized,
                totalGross: 50000,
                totalNet: 48000,
                payslipCount: 4,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: SalaryGenerationPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.textContaining('salary'), findsWidgets);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
  });

  testWidgets('hourly and monthly attendance forms', (tester) async {
    _phone(tester);
    Widget app(AttendanceRecord edit) => ProviderScope(
      overrides: [
        employeesProvider.overrideWith(_Employees.new),
        moduleAccessProvider.overrideWith((ref, _) => _full),
      ],
      child: MaterialApp(
        home: AttendanceFormPage(
          date: edit.workDate,
          today: '2026-10-27',
          edit: edit,
        ),
      ),
    );
    await tester.pumpWidget(
      app(
        const AttendanceRecord(
          id: 'ATTN1',
          employeeId: '1',
          employeeCode: 'EMP1',
          employeeName: 'Kumar',
          kind: SalaryType.hourly,
          salary: 100,
          workDate: '2026-10-27',
          recordedLocal: '',
          timezone: 'Asia/Kolkata',
          hours: 7.5,
          totalAmount: 750,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('7.5 hours'), findsOneWidget);
    expect(find.text('₹750'), findsOneWidget);
    await tester.tap(find.text('10 h'));
    await tester.pump();
    expect(find.text('₹1,000'), findsOneWidget);

    await tester.pumpWidget(
      app(
        const AttendanceRecord(
          id: 'ATTN2',
          employeeId: '2',
          employeeCode: 'EMP2',
          employeeName: 'Sita',
          kind: SalaryType.monthly,
          workDate: '2026-10-27',
          recordedLocal: '',
          timezone: 'Asia/Kolkata',
          dayUnits: 0.5,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Full day'), findsOneWidget);
    expect(find.text('Half day'), findsOneWidget);
  });
}
