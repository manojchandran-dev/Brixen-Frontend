import 'sale_item.dart';

/// Which series a sale belongs to: a GST tax invoice or a secondary bill
/// (no GST). Set when the sale is created and fixed after that.
abstract final class BillType {
  static const gst = 'GST';
  static const secondary = 'SECONDARY';
}

class Sale {
  final String id;
  final String? companyId;
  final String? customerId;
  final String?
  customerName; // display name, resolved client-side from Customers
  final DateTime billDate;
  final String? invoiceType;
  final double subtotal;
  final double taxAmount;
  final double? taxPercentage;
  final double totalAmount;
  final String? paymentType;
  final String paymentStatus;
  final String? notes;
  final String? billImagePath;
  final List<SaleItem> items;

  /// [BillType.gst] or [BillType.secondary].
  final String billType;

  /// A GST bill that can also be printed as a secondary bill (no GST).
  /// Always false on a secondary bill.
  final bool hasSecondaryBill;

  /// Server-set running number, e.g. "C7G2627/0001" (company 7, GST,
  /// 2026-27); unique across companies. Null on old sales.
  final String? billNo;

  /// Received so far (null on old data). See [balance].
  final double? amountPaid;
  final DateTime createdAt;

  const Sale({
    required this.id,
    this.companyId,
    this.customerId,
    this.customerName,
    required this.billDate,
    this.invoiceType,
    required this.subtotal,
    required this.taxAmount,
    this.taxPercentage,
    required this.totalAmount,
    this.paymentType,
    required this.paymentStatus,
    this.notes,
    this.billImagePath,
    this.items = const [],
    this.billType = BillType.gst,
    this.hasSecondaryBill = false,
    this.billNo,
    this.amountPaid,
    required this.createdAt,
  });

  bool get isGst => billType != BillType.secondary;

  /// A GST bill with a secondary bill is left out of sales totals.
  bool get countsInSales => !(isGst && hasSecondaryBill);

  /// Still owed: total − amount paid. Without [amountPaid] (old data), a
  /// Paid sale owes nothing and any other owes the full total.
  double get balance {
    final paid =
        amountPaid ?? (paymentStatus.toLowerCase() == 'paid' ? totalAmount : 0);
    return (totalAmount - paid).clamp(0, double.infinity).toDouble();
  }

  Sale copyWith({
    String? id,
    String? companyId,
    String? customerId,
    String? customerName,
    DateTime? billDate,
    String? invoiceType,
    double? subtotal,
    double? taxAmount,
    double? taxPercentage,
    double? totalAmount,
    String? paymentType,
    String? paymentStatus,
    String? notes,
    String? billImagePath,
    List<SaleItem>? items,
    String? billType,
    bool? hasSecondaryBill,
    String? billNo,
    DateTime? createdAt,
    double? amountPaid,
  }) {
    return Sale(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      billDate: billDate ?? this.billDate,
      invoiceType: invoiceType ?? this.invoiceType,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentType: paymentType ?? this.paymentType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      billImagePath: billImagePath ?? this.billImagePath,
      items: items ?? this.items,
      billType: billType ?? this.billType,
      hasSecondaryBill: hasSecondaryBill ?? this.hasSecondaryBill,
      billNo: billNo ?? this.billNo,
      amountPaid: amountPaid ?? this.amountPaid,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
