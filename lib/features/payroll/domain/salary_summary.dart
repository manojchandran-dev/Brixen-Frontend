/// One employee's work in a month or week, and their pay so far: what
/// attendance earns (salary types), or the piece pay entered (piece rate).
class EmployeeWork {
  final String id, code, name;
  final String? department;
  final String salaryType;
  final double? rate;
  final double daysPresent, shifts, hours;
  final int absent, pieces, pieceEntries, pieceUnconfirmed;
  final double amount;

  /// Net on this period's payslip, once salary is made.
  final double? payslipNet;

  const EmployeeWork({
    required this.id,
    required this.code,
    required this.name,
    this.department,
    required this.salaryType,
    this.rate,
    this.daysPresent = 0,
    this.shifts = 0,
    this.hours = 0,
    this.absent = 0,
    this.pieces = 0,
    this.pieceEntries = 0,
    this.pieceUnconfirmed = 0,
    this.amount = 0,
    this.payslipNet,
  });

  static double _d(Object? v) => v is num ? v.toDouble() : 0;

  factory EmployeeWork.fromJson(Map<String, dynamic> j) => EmployeeWork(
    id: j['id'].toString(),
    code: (j['employee_code'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    department: j['department']?.toString(),
    salaryType: (j['salary_type'] ?? '').toString(),
    rate: (j['rate'] as num?)?.toDouble(),
    daysPresent: _d(j['days_present']),
    shifts: _d(j['shifts']),
    hours: _d(j['hours']),
    absent: (j['absent'] as num?)?.toInt() ?? 0,
    pieces: (j['pieces'] as num?)?.toInt() ?? 0,
    pieceEntries: (j['piece_entries'] as num?)?.toInt() ?? 0,
    pieceUnconfirmed: (j['piece_unconfirmed'] as num?)?.toInt() ?? 0,
    amount: _d(j['amount']),
    payslipNet: (j['payslip_net'] as num?)?.toDouble(),
  );
}

/// Every employee's work for a period ([key]: "2026-10" or a week's Monday).
class SalarySummary {
  final String key, label;
  final int workingDays;
  final List<EmployeeWork> items;
  final double total;
  const SalarySummary({
    required this.key,
    required this.label,
    required this.workingDays,
    required this.items,
    required this.total,
  });

  factory SalarySummary.fromJson(Map<String, dynamic> j) => SalarySummary(
    key: (j['key'] ?? '').toString(),
    label: (j['label'] ?? '').toString(),
    workingDays: (j['working_days'] as num?)?.toInt() ?? 0,
    items: [
      for (final e in (j['items'] as List? ?? const []))
        EmployeeWork.fromJson((e as Map).cast<String, dynamic>()),
    ],
    total: ((j['totals'] as Map?)?['amount'] as num?)?.toDouble() ?? 0,
  );
}

/// One product sold on one day: quantity sold, and pieces (× its combo
/// size when it's sold in combos).
class SoldLine {
  /// "2026-10-29".
  final String date;
  final String productId, productName;
  final int? comboSize;
  final int quantity, pieces, bills;
  const SoldLine({
    required this.date,
    required this.productId,
    required this.productName,
    this.comboSize,
    required this.quantity,
    required this.pieces,
    required this.bills,
  });

  bool get isCombo => (comboSize ?? 0) > 0;

  factory SoldLine.fromJson(Map<String, dynamic> j) => SoldLine(
    date: (j['date'] ?? '').toString(),
    productId: (j['product_id'] ?? '').toString(),
    productName: (j['product_name'] ?? '').toString(),
    comboSize: (j['combo_size'] as num?)?.toInt(),
    quantity: (j['quantity'] as num?)?.toInt() ?? 0,
    pieces: (j['pieces'] as num?)?.toInt() ?? 0,
    bills: (j['bills'] as num?)?.toInt() ?? 0,
  );
}
