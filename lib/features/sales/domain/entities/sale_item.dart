/// One line item on a sale's bill (`sale_items` table) — persisted by the
/// backend via `PUT /sales/:id/step2`, which computes the sale's aggregate
/// subtotal/tax/total from these rows server-side.
class SaleItem {
  final String productId;
  final String productName;

  /// The size/colour sold, when the product has them.
  final String? variantId;

  /// "M / Blue" as it was when the line was saved.
  final String? variantLabel;
  final String priceType; // 'retail' | 'wholesale'
  final double price;
  final int quantity;

  /// The product's cost when this line was saved (server-set; null on old
  /// data or unsaved lines) — for profit.
  final double? costPrice;

  const SaleItem({
    required this.productId,
    required this.productName,
    this.variantId,
    this.variantLabel,
    required this.priceType,
    required this.price,
    required this.quantity,
    this.costPrice,
  });

  double get amount => price * quantity;

  /// "Polo T-Shirt (M / Blue)", or just the name without a size.
  String get displayName => variantLabel == null || variantLabel!.isEmpty
      ? productName
      : '$productName ($variantLabel)';

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
    productId: (json['product_id'] ?? '').toString(),
    productName: (json['product_name'] ?? '').toString(),
    variantId: json['variant_id']?.toString(),
    variantLabel: json['variant_label']?.toString(),
    priceType: (json['price_type'] ?? 'retail').toString(),
    price: double.tryParse(json['price'].toString()) ?? 0,
    quantity: int.tryParse(json['quantity'].toString()) ?? 0,
    costPrice: json['cost_price'] == null
        ? null
        : double.tryParse(json['cost_price'].toString()),
  );

  Map<String, dynamic> toBody() => {
    'product_id': productId,
    'product_name': productName,
    'variant_id': ?variantId,
    'price_type': priceType,
    'price': price,
    'quantity': quantity,
  };
}
