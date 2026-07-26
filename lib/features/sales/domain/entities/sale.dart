class Sale {
  final String id;
  final String? companyId;
  final String? customerId;
  final String billNo;
  final DateTime billDate;
  final String? invoiceType;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String? paymentType;
  final String paymentStatus;
  final String? notes;
  final String? billImagePath;
  final DateTime createdAt;

  const Sale({
    required this.id,
    this.companyId,
    this.customerId,
    required this.billNo,
    required this.billDate,
    this.invoiceType,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.paymentType,
    required this.paymentStatus,
    this.notes,
    this.billImagePath,
    required this.createdAt,
  });

  Sale copyWith({
    String? id,
    String? companyId,
    String? customerId,
    String? billNo,
    DateTime? billDate,
    String? invoiceType,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    String? paymentType,
    String? paymentStatus,
    String? notes,
    String? billImagePath,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      customerId: customerId ?? this.customerId,
      billNo: billNo ?? this.billNo,
      billDate: billDate ?? this.billDate,
      invoiceType: invoiceType ?? this.invoiceType,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentType: paymentType ?? this.paymentType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      billImagePath: billImagePath ?? this.billImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
