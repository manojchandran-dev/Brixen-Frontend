import '../../../core/utils/date_utils.dart';
import '../domain/entities/purchase.dart';

double _num(Object? v) => double.tryParse('${v ?? ''}') ?? 0;

/// `/purchases` JSON ↔ [Purchase].
Purchase purchaseFromJson(Map<String, dynamic> j) {
  DateTime date(Object? v) => DateTime.tryParse('${v ?? ''}') ?? DateTime.now();
  final items = j['purchase_items'] ?? j['items'];
  return Purchase(
    id: '${j['id']}',
    companyId: j['company_id']?.toString(),
    supplierName: '${j['supplier_name'] ?? ''}',
    billNo: '${j['bill_no'] ?? ''}',
    billDate: date(j['bill_date']),
    invoiceType: j['invoice_type']?.toString(),
    subtotal: _num(j['subtotal']),
    taxPercentage: _num(j['tax_percentage']),
    taxAmount: _num(j['tax_amount']),
    totalAmount: _num(j['total_amount']),
    amountPaid: j['amount_paid'] == null ? null : _num(j['amount_paid']),
    paymentType: j['payment_type']?.toString(),
    paymentStatus: '${j['payment_status'] ?? 'Pending'}',
    notes: j['notes']?.toString(),
    billImagePath: j['bill_image_url']?.toString(),
    items: items is List
        ? [
            for (final raw in items)
              if (raw is Map)
                PurchaseItem(
                  productId: '${raw['product_id'] ?? ''}',
                  productName: '${raw['product_name'] ?? ''}',
                  quantity: int.tryParse('${raw['quantity'] ?? 0}') ?? 0,
                  unitCost: _num(raw['unit_cost']),
                ),
          ]
        : const [],
    createdAt: date(j['created_at']),
  );
}

/// Body for `POST /purchases` (with [companyId]) and `PUT /purchases/:id`.
/// [items] replace the bill's lines; the server works out the totals and
/// moves stock.
Map<String, dynamic> purchaseToBody(Purchase p, {String? companyId}) => {
  if (companyId != null) 'company_id': int.tryParse(companyId) ?? companyId,
  'supplier_name': p.supplierName,
  if (p.billNo.isNotEmpty) 'bill_no': p.billNo,
  'bill_date': toIsoDateOnly(p.billDate),
  if (p.invoiceType?.isNotEmpty == true) 'invoice_type': p.invoiceType,
  if (p.paymentType?.isNotEmpty == true) 'payment_type': p.paymentType,
  'payment_status': p.paymentStatus,
  if (p.amountPaid != null) 'amount_paid': p.amountPaid,
  'tax_percentage': p.taxPercentage,
  if (p.notes?.isNotEmpty == true) 'notes': p.notes,
  'bill_image_url': p.billImagePath,
  'items': [
    for (final it in p.items)
      {
        'product_id': int.tryParse(it.productId) ?? it.productId,
        'quantity': it.quantity,
        'unit_cost': it.unitCost,
      },
  ],
};
