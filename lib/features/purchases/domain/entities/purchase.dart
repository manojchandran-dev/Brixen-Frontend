/// One line of a purchase bill (`purchase_items`): stock that came in.
class PurchaseItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitCost;

  const PurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
  });

  double get lineTotal => quantity * unitCost;
}

/// A purchase from a supplier (`/purchases`). Saving one adds its lines'
/// quantities to stock; editing moves stock by the net change; deleting
/// takes them back out (all server-side).
class Purchase {
  final String id;
  final String? companyId;
  final String supplierName;
  final String billNo;
  final DateTime billDate;
  final String? invoiceType;
  final double subtotal;
  final double taxPercentage;
  final double taxAmount;
  final double totalAmount;
  final double? amountPaid;
  final String? paymentType;
  final String paymentStatus;
  final String? notes;
  final String? billImagePath;

  /// Lines — returned by `GET /purchases/:id` (may be empty in lists).
  final List<PurchaseItem> items;
  final DateTime createdAt;

  const Purchase({
    required this.id,
    this.companyId,
    required this.supplierName,
    required this.billNo,
    required this.billDate,
    this.invoiceType,
    required this.subtotal,
    this.taxPercentage = 0,
    required this.taxAmount,
    required this.totalAmount,
    this.amountPaid,
    this.paymentType,
    required this.paymentStatus,
    this.notes,
    this.billImagePath,
    this.items = const [],
    required this.createdAt,
  });

  /// Still owed to the supplier: total − amount paid (Paid = nothing owed
  /// when the amount isn't known).
  double get balance {
    final paid =
        amountPaid ?? (paymentStatus.toLowerCase() == 'paid' ? totalAmount : 0);
    return (totalAmount - paid).clamp(0, double.infinity).toDouble();
  }

  Purchase copyWith({
    String? id,
    String? supplierName,
    String? billNo,
    DateTime? billDate,
    String? invoiceType,
    double? subtotal,
    double? taxPercentage,
    double? taxAmount,
    double? totalAmount,
    double? amountPaid,
    String? paymentType,
    String? paymentStatus,
    String? notes,
    String? billImagePath,
    List<PurchaseItem>? items,
    DateTime? createdAt,
  }) {
    return Purchase(
      id: id ?? this.id,
      companyId: companyId,
      supplierName: supplierName ?? this.supplierName,
      billNo: billNo ?? this.billNo,
      billDate: billDate ?? this.billDate,
      invoiceType: invoiceType ?? this.invoiceType,
      subtotal: subtotal ?? this.subtotal,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentType: paymentType ?? this.paymentType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      billImagePath: billImagePath ?? this.billImagePath,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
