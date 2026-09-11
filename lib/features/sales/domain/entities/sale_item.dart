/// One line item on a sale's bill (`sale_items` table) — persisted by the
/// backend via `PUT /sales/:id/step2`, which computes the sale's aggregate
/// subtotal/tax/total from these rows server-side.
class SaleItem {
  final String productId;
  final String productName;
  final String priceType; // 'retail' | 'wholesale'
  final double price;
  final int quantity;

  const SaleItem({
    required this.productId,
    required this.productName,
    required this.priceType,
    required this.price,
    required this.quantity,
  });

  double get amount => price * quantity;

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        productId: (json['product_id'] ?? '').toString(),
        productName: (json['product_name'] ?? '').toString(),
        priceType: (json['price_type'] ?? 'retail').toString(),
        price: double.tryParse(json['price'].toString()) ?? 0,
        quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      );

  Map<String, dynamic> toBody() => {
        'product_id': productId,
        'product_name': productName,
        'price_type': priceType,
        'price': price,
        'quantity': quantity,
      };
}
