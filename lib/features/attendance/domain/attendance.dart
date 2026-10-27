import '../../employees/domain/entities/employee.dart';

/// Shift sizes a shift-rate day can hold, and how many shifts at most.
/// Mirrors the server (attendance/service.js).
const kShiftUnits = [0.25, 0.5, 0.75, 1.0, 2.0, 3.0];
const kMaxShifts = 3;

/// "1/4", "1/2", "3/4", "1", "2", "3".
String shiftUnitLabel(double u) => switch (u) {
  0.25 => '1/4',
  0.5 => '1/2',
  0.75 => '3/4',
  _ => u % 1 == 0 ? u.toStringAsFixed(0) : u.toString(),
};

/// A day's total shifts: "1¾", "2", "½".
String shiftTotalLabel(double total) {
  final whole = total.floor();
  final frac = total - whole;
  final f = switch ((frac * 4).round()) {
    1 => '¼',
    2 => '½',
    3 => '¾',
    _ => '',
  };
  return whole == 0 && f.isNotEmpty ? f : '$whole$f';
}

/// One work type's pieces in a day; [rate] is as it was that day.
class PieceLine {
  final String workTypeId;
  final String workTypeName;
  final int quantity;
  final double rate;
  final double amount;
  const PieceLine({
    required this.workTypeId,
    required this.workTypeName,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  factory PieceLine.fromJson(Map<String, dynamic> j) => PieceLine(
    workTypeId: j['work_type_id'].toString(),
    workTypeName: (j['work_type_name'] ?? 'Work type').toString(),
    quantity: (j['quantity'] as num).toInt(),
    rate: (j['rate'] as num).toDouble(),
    amount: (j['amount'] as num).toDouble(),
  );
}

/// One employee's attendance for one day (the company's local date).
class AttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final String? department;
  final String? salaryPeriod;
  final double? salary;

  /// [SalaryType.shift] or [SalaryType.piece].
  final String kind;

  /// "2026-10-27".
  final String workDate;

  /// When it was recorded, as the company's clock showed it.
  final String recordedLocal;
  final String timezone;
  final String? notes;
  final List<double> shifts;
  final List<PieceLine> pieces;
  final double totalShifts;
  final int totalPieces;

  /// Pieces: Σ quantity × rate. Shifts: total × daily rate when paid daily;
  /// otherwise null (not a per-day figure).
  final double? totalAmount;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    this.department,
    this.salaryPeriod,
    this.salary,
    required this.kind,
    required this.workDate,
    required this.recordedLocal,
    required this.timezone,
    this.notes,
    this.shifts = const [],
    this.pieces = const [],
    this.totalShifts = 0,
    this.totalPieces = 0,
    this.totalAmount,
  });

  bool get isShift => kind == SalaryType.shift;

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) {
    final e = (j['employee'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AttendanceRecord(
      id: j['id'].toString(),
      employeeId: (j['employee_id'] ?? e['id']).toString(),
      employeeCode: (e['employee_code'] ?? '').toString(),
      employeeName: (e['name'] ?? '').toString(),
      department: e['department']?.toString(),
      salaryPeriod: e['salary_period']?.toString(),
      salary: (e['salary'] as num?)?.toDouble(),
      kind: (j['kind'] ?? SalaryType.shift).toString(),
      workDate: (j['work_date'] ?? '').toString(),
      recordedLocal: (j['recorded_local'] ?? '').toString(),
      timezone: (j['timezone'] ?? '').toString(),
      notes: j['notes']?.toString(),
      shifts: [
        for (final s in (j['shifts'] as List? ?? const []))
          ((s as Map)['units'] as num).toDouble(),
      ],
      pieces: [
        for (final p in (j['pieces'] as List? ?? const []))
          PieceLine.fromJson((p as Map).cast<String, dynamic>()),
      ],
      totalShifts: (j['total_shifts'] as num?)?.toDouble() ?? 0,
      totalPieces: (j['total_pieces'] as num?)?.toInt() ?? 0,
      totalAmount: (j['total_amount'] as num?)?.toDouble(),
    );
  }
}

/// A day's (or range's) records with the company's zone and today's date.
class AttendanceList {
  final List<AttendanceRecord> items;
  final String timezone;

  /// Today in the company's zone, "2026-10-27".
  final String today;
  const AttendanceList({
    required this.items,
    required this.timezone,
    required this.today,
  });

  factory AttendanceList.fromJson(Map<String, dynamic> j) {
    final meta = (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AttendanceList(
      items: [
        for (final r in (j['items'] as List? ?? const []))
          AttendanceRecord.fromJson((r as Map).cast<String, dynamic>()),
      ],
      timezone: (meta['timezone'] ?? 'Asia/Kolkata').toString(),
      today: (meta['today'] ?? '').toString(),
    );
  }
}

/// What an employee login sees: their days and the totals for the range.
class MyAttendance {
  final AttendanceList list;
  final int days;
  final double shifts;
  final int pieces;
  final double amount;
  final String from, to;
  const MyAttendance({
    required this.list,
    required this.days,
    required this.shifts,
    required this.pieces,
    required this.amount,
    required this.from,
    required this.to,
  });

  factory MyAttendance.fromJson(Map<String, dynamic> j) {
    final t = (j['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    final meta = (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    return MyAttendance(
      list: AttendanceList.fromJson(j),
      days: (t['days'] as num?)?.toInt() ?? 0,
      shifts: (t['shifts'] as num?)?.toDouble() ?? 0,
      pieces: (t['pieces'] as num?)?.toInt() ?? 0,
      amount: (t['amount'] as num?)?.toDouble() ?? 0,
      from: (meta['from'] ?? '').toString(),
      to: (meta['to'] ?? '').toString(),
    );
  }
}
