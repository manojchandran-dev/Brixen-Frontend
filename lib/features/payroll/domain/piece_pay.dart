/// Piece-rate pay entered after a sale: an employee, a work type (its rate
/// per piece) and the quantity — in pieces, or in combos of a product
/// (× its combo size). A draft can change; a confirmed one is locked, can
/// be emailed, and counts in the salary report.
class PiecePay {
  static const draft = 'DRAFT';
  static const confirmed = 'CONFIRMED';

  /// What [quantity] counts.
  static const piece = 'PIECE';
  static const combo = 'COMBO';

  final String id;
  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final String? email;
  final String workTypeId;
  final String workTypeName;
  final String? productId;
  final String? productName;

  /// "2026-10-29".
  final String payDate;
  final String unit;
  final int quantity;
  final int? comboSize;
  final int pieces;
  final double rate;
  final double amount;
  final String? notes;
  final String status;
  final DateTime? emailedAt;
  final String? emailError;

  const PiecePay({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    this.email,
    required this.workTypeId,
    required this.workTypeName,
    this.productId,
    this.productName,
    required this.payDate,
    required this.unit,
    required this.quantity,
    this.comboSize,
    required this.pieces,
    required this.rate,
    required this.amount,
    this.notes,
    required this.status,
    this.emailedAt,
    this.emailError,
  });

  bool get isConfirmed => status == confirmed;
  bool get isCombo => unit == combo;

  /// "10 combos of Billa shorts (12 each) = 120 pieces" or "250 pieces".
  String get quantityLabel => isCombo
      ? '$quantity combo${quantity == 1 ? '' : 's'}'
            '${productName == null ? '' : ' of $productName'}'
            ' ($comboSize each) = $pieces pieces'
      : '$pieces piece${pieces == 1 ? '' : 's'}';

  factory PiecePay.fromJson(Map<String, dynamic> j) {
    final e = (j['employee'] as Map?)?.cast<String, dynamic>() ?? const {};
    return PiecePay(
      id: j['id'].toString(),
      employeeId: (j['employee_id'] ?? e['id']).toString(),
      employeeCode: (e['employee_code'] ?? '').toString(),
      employeeName: (e['name'] ?? '').toString(),
      email: e['email']?.toString(),
      workTypeId: (j['work_type_id'] ?? '').toString(),
      workTypeName: (j['work_type_name'] ?? 'Work type').toString(),
      productId: j['product_id']?.toString(),
      productName: j['product_name']?.toString(),
      payDate: (j['pay_date'] ?? '').toString(),
      unit: (j['unit'] ?? piece).toString(),
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      comboSize: (j['combo_size'] as num?)?.toInt(),
      pieces: (j['pieces'] as num?)?.toInt() ?? 0,
      rate: (j['rate'] as num?)?.toDouble() ?? 0,
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      notes: j['notes']?.toString(),
      status: (j['status'] ?? draft).toString(),
      emailedAt: DateTime.tryParse((j['emailed_at'] ?? '').toString()),
      emailError: j['email_error']?.toString(),
    );
  }
}
