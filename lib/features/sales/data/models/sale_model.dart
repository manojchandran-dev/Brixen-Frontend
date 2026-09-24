import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';

class SaleModel extends Sale {
  const SaleModel({
    required super.id,
    super.companyId,
    super.customerId,
    super.customerName,
    required super.billDate,
    super.invoiceType,
    required super.subtotal,
    required super.taxAmount,
    super.taxPercentage,
    required super.totalAmount,
    super.paymentType,
    required super.paymentStatus,
    super.notes,
    super.billImagePath,
    super.items,
    required super.createdAt,
  });

  static double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'].toString(),
      companyId: json['company_id']?.toString(),
      customerId: json['customer_id']?.toString(),
      billDate: json['bill_date'] != null
          ? DateTime.tryParse(json['bill_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      invoiceType: json['invoice_type'],
      subtotal: _num(json['subtotal']),
      taxAmount: _num(json['tax_amount']),
      taxPercentage: json['tax_percentage'] != null ? _num(json['tax_percentage']) : null,
      totalAmount: _num(json['total_amount']),
      paymentType: json['payment_type'],
      paymentStatus: (json['payment_status'] ?? 'Pending').toString(),
      notes: json['notes'],
      billImagePath: json['bill_image_url'],
      items: json['sale_items'] is List
          ? (json['sale_items'] as List)
              .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Header fields for create (`POST /sales`) and update (`PUT /sales/:id`)
  /// — server generates `id`, so it's never sent. `subtotal`/`tax_amount`/
  /// `total_amount` are omitted entirely: the backend now derives them from
  /// the line items posted via [toStep2Body], so sending a client-guessed
  /// value here would only ever be stale. `companyId` is only needed on
  /// create — see `Session.companyId`.
  static Map<String, dynamic> toBody(Sale s, {String? companyId}) => {
        if (companyId != null) 'company_id': int.parse(companyId),
        if (s.customerId != null && s.customerId!.isNotEmpty) 'customer_id': s.customerId,
        'bill_date': s.billDate.toIso8601String(),
        if (s.invoiceType != null && s.invoiceType!.isNotEmpty) 'invoice_type': s.invoiceType,
        if (s.paymentType != null && s.paymentType!.isNotEmpty) 'payment_type': s.paymentType,
        'payment_status': s.paymentStatus,
        if (s.notes != null && s.notes!.isNotEmpty) 'notes': s.notes,
        // Always sent (null clears it on PUT). Must be a hosted URL — the
        // page uploads a picked bill image via `POST /uploads` first.
        'bill_image_url': s.billImagePath,
      };

  /// `PUT /sales/:id/step2` — replaces the sale's entire line-item list and
  /// tax percentage; the backend computes subtotal/tax_amount/total_amount
  /// from these and returns the updated sale.
  static Map<String, dynamic> toStep2Body(List<SaleItem> items, double taxPercentage) => {
        'items': items.map((i) => i.toBody()).toList(),
        'tax_percentage': taxPercentage,
      };
}
