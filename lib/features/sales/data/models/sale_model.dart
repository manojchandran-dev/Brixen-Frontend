import '../../domain/entities/sale.dart';

class SaleModel extends Sale {
  const SaleModel({
    required super.id,
    super.customerId,
    super.customerName,
    required super.billDate,
    super.invoiceType,
    required super.subtotal,
    required super.taxAmount,
    required super.totalAmount,
    super.paymentType,
    required super.paymentStatus,
    super.notes,
    super.billImagePath,
    required super.createdAt,
  });

  static double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'].toString(),
      customerId: json['customer_id']?.toString(),
      billDate: json['bill_date'] != null
          ? DateTime.tryParse(json['bill_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      invoiceType: json['invoice_type'],
      subtotal: _num(json['subtotal']),
      taxAmount: _num(json['tax_amount']),
      totalAmount: _num(json['total_amount']),
      paymentType: json['payment_type'],
      paymentStatus: (json['payment_status'] ?? 'Pending').toString(),
      notes: json['notes'],
      billImagePath: json['bill_image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Request body for create/update — server generates `id`, so it's never sent.
  static Map<String, dynamic> toBody(Sale s) => {
        if (s.customerId != null && s.customerId!.isNotEmpty) 'customer_id': s.customerId,
        'bill_date': s.billDate.toIso8601String(),
        if (s.invoiceType != null && s.invoiceType!.isNotEmpty) 'invoice_type': s.invoiceType,
        'subtotal': s.subtotal,
        'tax_amount': s.taxAmount,
        'total_amount': s.totalAmount,
        if (s.paymentType != null && s.paymentType!.isNotEmpty) 'payment_type': s.paymentType,
        'payment_status': s.paymentStatus,
        if (s.notes != null && s.notes!.isNotEmpty) 'notes': s.notes,
      };
}
