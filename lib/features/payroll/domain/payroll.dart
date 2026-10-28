import 'package:intl/intl.dart';
import '../../attendance/domain/attendance.dart';
import '../../employees/domain/entities/employee.dart';

/// A run's state: [draft] while it's reviewed (adjustable, can be generated
/// again), [finalized] once confirmed (payslips can be sent, and it counts
/// in the salary report).
abstract final class PayrollStatus {
  static const draft = 'DRAFT';
  static const finalized = 'FINALIZED';
}

/// A run's period as people say it: "October 2026" from "2026-10", or the
/// week "26 Oct – 1 Nov 2026" from its Monday "2026-10-26".
String monthLabel(String key) {
  if (key.length == 10) {
    final from = DateTime.tryParse(key);
    if (from == null) return key;
    final to = from.add(const Duration(days: 6));
    return '${DateFormat('d MMM').format(from)} – '
        '${DateFormat('d MMM yyyy').format(to)}';
  }
  return key.length < 7
      ? key
      : DateFormat('MMMM yyyy').format(DateTime.parse('$key-01'));
}

/// The Monday of [d]'s week.
DateTime weekStartOf(DateTime d) =>
    DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

double _d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

/// One work type's pieces over the month, at one rate.
class PieceTotal {
  final String name;
  final int quantity;
  final double rate, amount;
  const PieceTotal({
    required this.name,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  factory PieceTotal.fromJson(Map<String, dynamic> j) => PieceTotal(
    name: (j['name'] ?? 'Work type').toString(),
    quantity: _d(j['quantity']).round(),
    rate: _d(j['rate']),
    amount: _d(j['amount']),
  );
}

/// One employee's pay for a month: what attendance earned ([gross]), plus
/// [additions] less [deductions] = [net].
class Payslip {
  final String id;
  final String runId;

  /// "2026-10".
  final String month;
  final DateTime periodTo;
  final int? workingDays;
  final String status;
  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final String? email;
  final String? department;
  final String? designation;
  final String salaryType;

  /// The salary amount then (per shift / hour / week / month); null for
  /// piece rate.
  final double? rate;

  /// Shifts, pieces, hours or days, by [salaryType].
  final double units;
  final double daysPresent;
  final double gross, additions, deductions, net;
  final List<PieceTotal> pieces;
  final String? notes;
  final DateTime? emailedAt;
  final String? emailError;

  const Payslip({
    required this.id,
    required this.runId,
    required this.month,
    required this.periodTo,
    this.workingDays,
    required this.status,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    this.email,
    this.department,
    this.designation,
    required this.salaryType,
    this.rate,
    required this.units,
    required this.daysPresent,
    required this.gross,
    this.additions = 0,
    this.deductions = 0,
    required this.net,
    this.pieces = const [],
    this.notes,
    this.emailedAt,
    this.emailError,
  });

  bool get isFinalized => status == PayrollStatus.finalized;

  /// "24 shifts", "230 pieces", "7.5 hours", "22½ of 27 days".
  String get workLabel => switch (salaryType) {
    SalaryType.shift => '${shiftTotalLabel(units)} shifts',
    SalaryType.piece => '${units.round()} pieces',
    SalaryType.hourly => '${hoursLabel(units)} hours',
    SalaryType.monthly when workingDays != null =>
      '${daysLabel(units)} of $workingDays days',
    _ => '${daysLabel(units)} days',
  };

  /// How [gross] was worked out: "24 shifts × ₹600", "210 pieces × work
  /// type rates", "7.5 h × ₹100", "20½ days × ₹1,000" (a day's share of a
  /// weekly or monthly salary).
  String formula(String Function(double) money) {
    final r = rate ?? 0;
    return switch (salaryType) {
      SalaryType.shift => '${shiftTotalLabel(units)} shifts × ${money(r)}',
      SalaryType.piece => '${units.round()} pieces × work type rates',
      SalaryType.hourly => '${hoursLabel(units)} h × ${money(r)}',
      SalaryType.weekly => '${daysLabel(units)} days × ${money(r / 6)}',
      SalaryType.monthly when (workingDays ?? 0) > 0 =>
        '${daysLabel(units)} days × ${money(r / workingDays!)}',
      _ => workLabel,
    };
  }

  /// "₹600 per shift", or "Work type rates" for piece rate.
  String rateLabel(String Function(double) money) => rate == null
      ? 'Work type rates'
      : '${money(rate!)} ${SalaryType.perLabel(salaryType)}';

  factory Payslip.fromJson(Map<String, dynamic> j) {
    final e = (j['employee'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Payslip(
      id: j['id'].toString(),
      runId: (j['run_id'] ?? '').toString(),
      month: (j['month'] ?? '').toString(),
      periodTo:
          DateTime.tryParse((j['period_to'] ?? '').toString()) ??
          DateTime.now(),
      workingDays: (j['working_days'] as num?)?.toInt(),
      status: (j['status'] ?? PayrollStatus.draft).toString(),
      employeeId: (e['id'] ?? '').toString(),
      employeeCode: (e['employee_code'] ?? '').toString(),
      employeeName: (e['name'] ?? '').toString(),
      email: e['email']?.toString(),
      department: e['department']?.toString(),
      designation: e['designation']?.toString(),
      salaryType: (j['salary_type'] ?? '').toString(),
      rate: j['rate'] == null ? null : _d(j['rate']),
      units: _d(j['units']),
      daysPresent: _d(j['days_present']),
      gross: _d(j['gross']),
      additions: _d(j['additions']),
      deductions: _d(j['deductions']),
      net: _d(j['net']),
      pieces: [
        for (final p in (j['breakdown'] as List? ?? const []))
          PieceTotal.fromJson((p as Map).cast<String, dynamic>()),
      ],
      notes: j['notes']?.toString(),
      emailedAt: DateTime.tryParse((j['emailed_at'] ?? '').toString()),
      emailError: j['email_error']?.toString(),
    );
  }
}

/// A month's or week's salary generation and its payslips (empty in the run
/// list).
class PayrollRun {
  final String id;

  /// The period's key: "2026-10", or a week's Monday "2026-10-26".
  final String month;

  /// MONTH or WEEK.
  final String periodType;
  final DateTime? periodFrom;
  final int workingDays;
  final String status;
  final double totalGross, totalNet;
  final int payslipCount;
  final List<Payslip> payslips;

  const PayrollRun({
    required this.id,
    required this.month,
    required this.workingDays,
    required this.status,
    required this.totalGross,
    required this.totalNet,
    required this.payslipCount,
    this.payslips = const [],
    this.periodType = 'MONTH',
    this.periodFrom,
    this.skipped = const [],
  });

  /// After generating: "Name — paid in October 2026" for employees left out
  /// because another run already pays them for some of these days.
  final List<String> skipped;

  bool get isFinalized => status == PayrollStatus.finalized;
  bool get isWeek => periodType == 'WEEK';
  String get label => monthLabel(month);

  factory PayrollRun.fromJson(Map<String, dynamic> j) => PayrollRun(
    id: j['id'].toString(),
    month: (j['month'] ?? '').toString(),
    periodType: (j['period_type'] ?? 'MONTH').toString(),
    periodFrom: DateTime.tryParse((j['period_from'] ?? '').toString()),
    skipped: [
      for (final s in (j['skipped'] as List? ?? const []))
        '${(s as Map)['name']} — paid in ${s['paid_in']}',
    ],
    workingDays: (j['working_days'] as num?)?.toInt() ?? 0,
    status: (j['status'] ?? PayrollStatus.draft).toString(),
    totalGross: _d(j['total_gross']),
    totalNet: _d(j['total_net']),
    payslipCount: (j['payslip_count'] as num?)?.toInt() ?? 0,
    payslips: [
      for (final p in (j['payslips'] as List? ?? const []))
        Payslip.fromJson((p as Map).cast<String, dynamic>()),
    ],
  );
}

/// What emailing payslips did.
class SendResult {
  final int sent;

  /// "Name — reason" for payslips not sent (no email) or that failed.
  final List<String> skipped, failed;
  const SendResult({
    required this.sent,
    this.skipped = const [],
    this.failed = const [],
  });

  factory SendResult.fromJson(Map<String, dynamic> j) {
    List<String> rows(Object? v) => [
      for (final r in (v as List? ?? const []))
        '${(r as Map)['name']} — ${r['reason']}',
    ];
    return SendResult(
      sent: (j['sent'] as num?)?.toInt() ?? 0,
      skipped: rows(j['skipped']),
      failed: rows(j['failed']),
    );
  }
}
