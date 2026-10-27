import 'package:brixen/features/attendance/domain/attendance.dart';
import 'package:brixen/features/attendance/presentation/attendance_providers.dart';
import 'package:brixen/features/attendance/presentation/pages/attendance_page.dart';
import 'package:brixen/features/employees/domain/entities/employee.dart';
import 'package:brixen/features/permissions/presentation/providers/module_access_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

AttendanceRecord _rec(String day, String name, String kind) => AttendanceRecord(
  id: '$day$name',
  employeeId: name,
  employeeCode: 'EMP',
  employeeName: name,
  kind: kind,
  workDate: day,
  recordedLocal: '',
  timezone: 'Asia/Kolkata',
  shifts: kind == SalaryType.shift ? const [1] : const [],
  totalShifts: kind == SalaryType.shift ? 1 : 0,
);

void main() {
  testWidgets('month calendar: today picked, tap a day for its records', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    // The 1st of this month (today itself on the 1st: then just today).
    final first = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(now.year, now.month));
    final items = [
      _rec(today, 'Ravi', SalaryType.shift),
      if (first != today) _rec(first, 'Meena', SalaryType.piece),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moduleAccessReadyProvider.overrideWithValue(true),
          moduleAccessProvider.overrideWith((ref, _) => ModuleAccess.full),
          attendanceMonthProvider.overrideWith(
            (ref, q) async => AttendanceList(
              items: items,
              timezone: 'Asia/Kolkata',
              today: today,
            ),
          ),
        ],
        child: const MaterialApp(home: AttendancePage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    expect(find.text(DateFormat('MMMM yyyy').format(now)), findsOneWidget);
    expect(
      find.text(
        '${items.length} record${items.length == 1 ? '' : 's'} this month',
      ),
      findsOneWidget,
    );
    // Today is picked: its record shows.
    expect(find.text('Ravi'), findsOneWidget);

    if (first != today) {
      await tester.tap(find.text('1').first);
      await tester.pump();
      expect(find.text('Meena'), findsOneWidget);
      expect(find.text('Ravi'), findsNothing);
    }
  });
}
