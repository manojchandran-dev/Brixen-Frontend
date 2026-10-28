import 'package:brixen/features/attendance/domain/attendance.dart';
import 'package:brixen/features/employees/data/models/employee_model.dart';
import 'package:brixen/features/employees/domain/entities/employee.dart';
import 'package:brixen/features/payroll/domain/payroll.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shift labels and day totals', () {
    expect(
      [for (final u in kShiftUnits) shiftUnitLabel(u)],
      ['¼', '½', '¾', '1', '1¼', '1½', '1¾', '2', '2¼', '2½', '2¾', '3'],
    );
    expect(shiftTotalLabel(1.75), '1¾');
    expect(shiftTotalLabel(0.5), '½');
    expect(shiftTotalLabel(2), '2');
    expect(shiftTotalLabel(3.25), '3¼');
    expect(kMaxShifts, 3);
  });

  test('a piece-rate record parses with its lines and totals', () {
    final r = AttendanceRecord.fromJson({
      'id': 'ATTN000000000001',
      'employee_id': 7,
      'employee': {
        'id': 7,
        'employee_code': 'EMP0007',
        'name': 'Ravi Kumar',
        'department': 'Stitching',
        'salary_type': 'PIECE_RATE',
        'salary_period': 'PER_PIECE',
        'salary': null,
      },
      'work_date': '2026-10-27',
      'kind': 'PIECE_RATE',
      'timezone': 'Asia/Kolkata',
      'recorded_local': '27 Oct 2026, 9:05 am',
      'shifts': [],
      'pieces': [
        {
          'work_type_id': 'WTYP000000000001',
          'work_type_name': 'T-shirt hand stitching',
          'quantity': 10,
          'rate': 200,
          'amount': 2000,
        },
        {
          'work_type_id': 'WTYP000000000002',
          'work_type_name': 'T-shirt neck stitching',
          'quantity': 5,
          'rate': 300,
          'amount': 1500,
        },
      ],
      'total_shifts': 0,
      'total_pieces': 15,
      'total_amount': 3500,
    });
    expect(r.isShift, isFalse);
    expect(r.employeeName, 'Ravi Kumar');
    expect(r.pieces.map((p) => p.amount), [2000, 1500]);
    expect(r.totalPieces, 15);
    expect(r.totalAmount, 3500);
  });

  test('a shift record keeps each shift; no amount unless paid daily', () {
    final r = AttendanceRecord.fromJson({
      'id': 'ATTN000000000002',
      'employee': {'id': 8, 'name': 'Meena', 'salary_period': 'MONTHLY'},
      'work_date': '2026-10-27',
      'kind': 'SHIFT_RATE',
      'shifts': [
        {'shift_no': 1, 'units': 1},
        {'shift_no': 2, 'units': 0.75},
      ],
      'total_shifts': 1.75,
      'total_amount': null,
    });
    expect(r.isShift, isTrue);
    expect(r.shifts, [1.0, 0.75]);
    expect(shiftTotalLabel(r.totalShifts), '1¾');
    expect(r.totalAmount, isNull);
  });

  test('salary types: five types, amounts and summaries', () {
    expect(SalaryType.all, [
      'SHIFT_RATE',
      'PIECE_RATE',
      'HOURLY',
      'WEEKLY',
      'MONTHLY',
    ]);
    expect(SalaryType.all.where(SalaryType.hasAmount), [
      'SHIFT_RATE',
      'HOURLY',
      'WEEKLY',
      'MONTHLY',
    ]);
    expect(SalaryType.periodOf(SalaryType.shift), 'PER_SHIFT');
    expect(SalaryType.periodOf(SalaryType.monthly), 'MONTHLY');
    // Older Shift Rate paid weekly is the Weekly type now; daily stays Shift.
    expect(SalaryType.normalize('SHIFT_RATE', 'WEEKLY'), SalaryType.weekly);
    expect(SalaryType.normalize('SHIFT_RATE', 'DAILY'), SalaryType.shift);
    final base = Employee(
      id: '1',
      employeeCode: 'EMP0001',
      firstName: 'A',
      createdAt: DateTime(2026),
    );
    expect(
      base.copyWith(salaryType: SalaryType.shift, salary: 600).salarySummary,
      'Shift · ₹600 per shift',
    );
    expect(
      base
          .copyWith(salaryType: SalaryType.monthly, salary: 26000)
          .salarySummary,
      'Monthly · ₹26000 per month',
    );
    expect(
      base.copyWith(salaryType: SalaryType.piece).salarySummary,
      'Piece Rate · paid after sales',
    );
    // Older employees without a type: just the amount.
    expect(base.copyWith(salary: 20000).salarySummary, '₹20000');
  });

  test('employee JSON: department master, salary terms and login', () {
    final e = EmployeeModel.fromJson({
      'id': 3,
      'employee_code': 'EMP0003',
      'first_name': 'Sita',
      'department': 'old text',
      'department_id': 'DEPT000000000001',
      'departments': {'id': 'DEPT000000000001', 'name': 'Stitching'},
      'salary_type': 'SHIFT_RATE',
      'salary_period': 'WEEKLY',
      'salary': '3500.00',
      'users': {'email': 'sita@shop.in', 'deleted_at': null},
    });
    expect(e.department, 'Stitching');
    expect(e.departmentId, 'DEPT000000000001');
    // Saved as Shift Rate paid weekly, before the five types.
    expect(e.salaryType, SalaryType.weekly);
    expect(e.salary, 3500);
    expect(e.loginEmail, 'sita@shop.in');
    expect(e.loginActive, isTrue);

    final removed = EmployeeModel.fromJson({
      'id': 4,
      'first_name': 'B',
      'users': {'email': 'b@shop.in', 'deleted_at': '2026-10-01T00:00:00Z'},
    });
    expect(removed.loginActive, isFalse);
    expect(
      EmployeeModel.fromJson({'id': 5, 'first_name': 'C'}).loginEmail,
      isNull,
    );

    // Step 2 sends the department and salary terms; piece rate clears the
    // amount.
    final body = EmployeeModel.toStep2Body(
      e.copyWith(salaryType: SalaryType.piece, salaryPeriod: 'PER_PIECE'),
    );
    expect(body['department_id'], 'DEPT000000000001');
    expect(body['salary_type'], SalaryType.piece);
    expect(body['salary_period'], 'PER_PIECE');
    expect(body.containsKey('salary'), isTrue);
    expect(body['salary'], isNull);
    expect(EmployeeModel.toStep2Body(e)['salary'], 3500);
  });

  test('hours and day records', () {
    AttendanceRecord rec(Map<String, dynamic> extra) =>
        AttendanceRecord.fromJson({
          'id': 'ATTN1',
          'employee_id': 1,
          'employee': {'name': 'Ravi', 'employee_code': 'EMP1'},
          'work_date': '2026-10-27',
          ...extra,
        });
    final hourly = rec({'kind': 'HOURLY', 'hours': 7.5, 'total_amount': 750});
    expect(hourly.workSummary, '7.5 hours');
    expect(hourly.totalAmount, 750);
    expect(rec({'kind': 'MONTHLY', 'day_units': 0.5}).workSummary, 'Half day');
    expect(rec({'kind': 'WEEKLY', 'day_units': 1}).workSummary, 'Full day');
    expect(hoursLabel(8), '8');
    expect(hoursLabel(7.25), '7.25');
    expect(daysLabel(22.5), '22½');
  });

  test('payslip JSON', () {
    final p = Payslip.fromJson({
      'id': 'PSLP1',
      'run_id': 'PRUN1',
      'month': '2026-10',
      'period_to': '2026-10-31',
      'working_days': 27,
      'status': 'FINALIZED',
      'employee': {'id': 3, 'employee_code': 'EMP3', 'name': 'Sita'},
      'salary_type': 'MONTHLY',
      'rate': 27000,
      'units': 20.5,
      'days_present': 20.5,
      'gross': 20500,
      'additions': 500,
      'deductions': 1000,
      'net': 20000,
      'breakdown': null,
    });
    expect(p.isFinalized, isTrue);
    expect(p.workLabel, '20½ of 27 days');
    expect(p.net, 20000);
    expect(monthLabel(p.month), 'October 2026');

    final piece = Payslip.fromJson({
      'id': 'PSLP2',
      'month': '2026-10',
      'salary_type': 'PIECE_RATE',
      'units': 210,
      'gross': 105,
      'net': 105,
      'breakdown': [
        {'name': 'Hand', 'quantity': 210, 'rate': 0.5, 'amount': 105},
      ],
    });
    expect(piece.workLabel, '210 pieces');
    expect(piece.pieces.single.name, 'Hand');
    expect(piece.rateLabel((v) => '₹$v'), '—');
  });

  test('absent days', () {
    final r = AttendanceRecord.fromJson({
      'id': 'ATTN9',
      'employee_id': 9,
      'employee': {'name': 'Ravi'},
      'kind': 'SHIFT_RATE',
      'status': 'ABSENT',
      'work_date': '2026-10-27',
      'total_amount': null,
    });
    expect(r.isAbsent, isTrue);
    expect(r.workSummary, 'Absent');
    final m = MyAttendance.fromJson({
      'items': [],
      'totals': {'days': 20, 'absent': 2, 'shifts': 20, 'amount': 10000},
    });
    expect(m.absent, 2);
    expect(m.days, 20);
  });
}
