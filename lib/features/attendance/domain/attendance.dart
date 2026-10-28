import '../../employees/domain/entities/employee.dart';

/// Shift sizes a shift-rate day can hold, and how many shifts at most.
/// Mirrors the server (attendance/service.js).
/// ¼, ½, ¾, 1, 1¼ … 2¾, 3.
const kShiftUnits = [
  0.25,
  0.5,
  0.75,
  1.0,
  1.25,
  1.5,
  1.75,
  2.0,
  2.25,
  2.5,
  2.75,
  3.0,
];
const kMaxShifts = 3;

/// The most hours an hourly day can hold.
const kMaxHours = 24;

/// "¼", "½", "1", "1¼", "2¾", "3".
String shiftUnitLabel(double u) => shiftTotalLabel(u);

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

/// "7.5", "8" — hours without trailing zeros.
String hoursLabel(double h) => h % 1 == 0
    ? h.toStringAsFixed(0)
    : h.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');

/// "1", "½", "2½" — days present (half days count ½).
String daysLabel(double d) => shiftTotalLabel(d);

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

  /// The employee's [SalaryType] when it was recorded.
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

  /// Absent that day: nothing recorded, and the day isn't paid.
  final bool isAbsent;

  /// Hourly: hours worked.
  final double? hours;

  /// Weekly / monthly: 1 (full day) or 0.5 (half day).
  final double? dayUnits;

  /// Pieces: Σ quantity × rate. Shifts / hours: × the salary. Weekly and
  /// monthly: null (salary generation works the pay out).
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
    this.isAbsent = false,
    this.hours,
    this.dayUnits,
    this.totalAmount,
  });

  bool get isShift => kind == SalaryType.shift;
  bool get isPiece => kind == SalaryType.piece;

  /// "1¾ shifts", "230 pieces", "7.5 hours", "Full day", "Half day",
  /// "Absent".
  String get workSummary => isAbsent
      ? 'Absent'
      : switch (kind) {
          SalaryType.shift =>
            '${shiftTotalLabel(totalShifts)} shift${totalShifts == 1 ? '' : 's'}',
          SalaryType.piece =>
            '$totalPieces piece${totalPieces == 1 ? '' : 's'}',
          SalaryType.hourly =>
            '${hoursLabel(hours ?? 0)} hour${hours == 1 ? '' : 's'}',
          _ => (dayUnits ?? 1) < 1 ? 'Half day' : 'Full day',
        };

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
      isAbsent: j['status'] == 'ABSENT',
      hours: (j['hours'] as num?)?.toDouble(),
      dayUnits: (j['day_units'] as num?)?.toDouble(),
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

  /// Lots delivered in the range ([amount] includes them).
  final List<PieceLot> lots;
  final int days;
  final double shifts;
  final int pieces;
  final double hours;

  /// Days marked absent ([days] are the days worked).
  final int absent;

  /// Weekly / monthly days, half days counting ½.
  final double dayUnits;
  final double amount;
  final String from, to;
  const MyAttendance({
    required this.list,
    this.lots = const [],
    required this.days,
    required this.shifts,
    required this.pieces,
    this.hours = 0,
    this.absent = 0,
    this.dayUnits = 0,
    required this.amount,
    required this.from,
    required this.to,
  });

  factory MyAttendance.fromJson(Map<String, dynamic> j) {
    final t = (j['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    final meta = (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    return MyAttendance(
      list: AttendanceList.fromJson(j),
      lots: [
        for (final l in (j['lots'] as List? ?? const []))
          PieceLot.fromJson((l as Map).cast<String, dynamic>()),
      ],
      days: (t['days'] as num?)?.toInt() ?? 0,
      shifts: (t['shifts'] as num?)?.toDouble() ?? 0,
      pieces: (t['pieces'] as num?)?.toInt() ?? 0,
      hours: (t['hours'] as num?)?.toDouble() ?? 0,
      absent: (t['absent'] as num?)?.toInt() ?? 0,
      dayUnits: (t['day_units'] as num?)?.toDouble() ?? 0,
      amount: (t['amount'] as num?)?.toDouble() ?? 0,
      from: (meta['from'] ?? '').toString(),
      to: (meta['to'] ?? '').toString(),
    );
  }
}

/// Piece work counted once a lot is delivered, not day by day: e.g. 800
/// dozen of a work type = 9,600 pieces × its rate.
class PieceLot {
  /// What [PieceLot.quantity] counts.
  static const piece = 'PIECE';
  static const dozen = 'DOZEN';

  final String id;
  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final String workTypeId;
  final String workTypeName;

  /// The delivery date, "2026-10-28".
  final String lotDate;
  final String unit;
  final int quantity;
  final int pieces;
  final double rate;
  final double amount;
  final String? notes;

  const PieceLot({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.workTypeId,
    required this.workTypeName,
    required this.lotDate,
    required this.unit,
    required this.quantity,
    required this.pieces,
    required this.rate,
    required this.amount,
    this.notes,
  });

  bool get isDozen => unit == dozen;

  /// "800 dozen (9,600 pieces)" or "250 pieces".
  String get quantityLabel => isDozen
      ? '$quantity dozen ($pieces pieces)'
      : '$pieces piece${pieces == 1 ? '' : 's'}';

  factory PieceLot.fromJson(Map<String, dynamic> j) {
    final e = (j['employee'] as Map?)?.cast<String, dynamic>() ?? const {};
    return PieceLot(
      id: j['id'].toString(),
      employeeId: (j['employee_id'] ?? e['id']).toString(),
      employeeCode: (e['employee_code'] ?? '').toString(),
      employeeName: (e['name'] ?? '').toString(),
      workTypeId: (j['work_type_id'] ?? '').toString(),
      workTypeName: (j['work_type_name'] ?? 'Work type').toString(),
      lotDate: (j['lot_date'] ?? '').toString(),
      unit: (j['unit'] ?? piece).toString(),
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      pieces: (j['pieces'] as num?)?.toInt() ?? 0,
      rate: (j['rate'] as num?)?.toDouble() ?? 0,
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      notes: j['notes']?.toString(),
    );
  }
}
