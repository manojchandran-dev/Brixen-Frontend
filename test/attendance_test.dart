import 'package:brixen/features/attendance/domain/attendance.dart';
import 'package:brixen/features/employees/data/models/employee_model.dart';
import 'package:brixen/features/employees/domain/entities/employee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shift labels and day totals', () {
    expect(
      [for (final u in kShiftUnits) shiftUnitLabel(u)],
      ['1/4', '1/2', '3/4', '1', '2', '3'],
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

  test('salary types: allowed periods and summaries', () {
    expect(SalaryType.periodsFor(SalaryType.shift), [
      'MONTHLY',
      'WEEKLY',
      'DAILY',
      'HOURLY',
    ]);
    expect(SalaryType.periodsFor(SalaryType.piece), ['PER_PIECE']);
    final base = Employee(
      id: '1',
      employeeCode: 'EMP0001',
      firstName: 'A',
      createdAt: DateTime(2026),
    );
    expect(
      base
          .copyWith(
            salaryType: SalaryType.shift,
            salaryPeriod: 'DAILY',
            salary: 600,
          )
          .salarySummary,
      'Shift Rate · ₹600 per day',
    );
    expect(
      base.copyWith(salaryType: SalaryType.piece).salarySummary,
      'Piece Rate · per piece (work type rates)',
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
    expect(e.salaryType, SalaryType.shift);
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
}
