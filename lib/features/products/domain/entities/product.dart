/// One size/colour of a product ("M / Blue") with its own code, prices and
/// stock. A price left empty uses the product's.
class ProductVariant {
  /// Null for a row added in the form and not saved yet.
  final String? id;
  final String? size;
  final String? color;
  final String? sku;
  final double? costPrice;
  final double? retailPrice;
  final double? wholesalePrice;
  final int stockQuantity;

  /// Opening stock for a new (unsaved) variant; ignored once saved — later
  /// changes go through Inventory.
  final int openingStock;

  const ProductVariant({
    this.id,
    this.size,
    this.color,
    this.sku,
    this.costPrice,
    this.retailPrice,
    this.wholesalePrice,
    this.stockQuantity = 0,
    this.openingStock = 0,
  });

  /// "M / Blue", "XL", "Blue".
  String get label =>
      [size, color].where((s) => s != null && s.trim().isNotEmpty).join(' / ');
}

class Product {
  final String id;
  final String? companyId;
  final String productCode;
  final String productName;
  final String? categoryId;
  final String category; // display name, resolved client-side from Masters
  final String gender;
  final String? designPattern;
  final String? unitId;
  final String? unit; // display name, resolved client-side from Masters
  final String? color;
  final String? size;
  final double costPrice;
  final double retailPrice;
  final double wholesalePrice;
  final List<String> galleryPaths;
  final String status;
  final String? onboardingStatus;

  /// Units in stock (can go below 0 when more is sold than recorded).
  final int stockQuantity;

  /// At or below this counts as low stock.
  final int lowStockThreshold;

  /// Sold as a combo of this many pieces (1–100); null = per piece. Piece
  /// pay can be entered in combos of it.
  final int? comboSize;
  final DateTime createdAt;

  /// Sizes/colours; empty for a product sold as one item. With variants,
  /// [stockQuantity] is their total.
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    this.companyId,
    required this.productCode,
    required this.productName,
    this.categoryId,
    required this.category,
    required this.gender,
    this.designPattern,
    this.unitId,
    this.unit,
    this.color,
    this.size,
    required this.costPrice,
    required this.retailPrice,
    required this.wholesalePrice,
    this.galleryPaths = const [],
    this.status = 'Active',
    this.onboardingStatus,
    this.stockQuantity = 0,
    this.lowStockThreshold = 5,
    this.comboSize,
    required this.createdAt,
    this.variants = const [],
  });

  bool get hasVariants => variants.isNotEmpty;

  /// A variant's prices, falling back to the product's.
  double retailFor(ProductVariant? v) => v?.retailPrice ?? retailPrice;
  double wholesaleFor(ProductVariant? v) => v?.wholesalePrice ?? wholesalePrice;
  double costFor(ProductVariant? v) => v?.costPrice ?? costPrice;

  bool get isOutOfStock => stockQuantity <= 0;
  bool get isLowStock => !isOutOfStock && stockQuantity <= lowStockThreshold;

  Product copyWith({
    String? id,
    String? companyId,
    String? productCode,
    String? productName,
    String? categoryId,
    String? category,
    String? gender,
    String? designPattern,
    String? unitId,
    String? unit,
    String? color,
    String? size,
    double? costPrice,
    double? retailPrice,
    double? wholesalePrice,
    List<String>? galleryPaths,
    String? status,
    String? onboardingStatus,
    DateTime? createdAt,
    int? stockQuantity,
    int? lowStockThreshold,
    int? comboSize,
    List<ProductVariant>? variants,
  }) {
    return Product(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      gender: gender ?? this.gender,
      designPattern: designPattern ?? this.designPattern,
      unitId: unitId ?? this.unitId,
      unit: unit ?? this.unit,
      color: color ?? this.color,
      size: size ?? this.size,
      costPrice: costPrice ?? this.costPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      galleryPaths: galleryPaths ?? this.galleryPaths,
      status: status ?? this.status,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      comboSize: comboSize ?? this.comboSize,
      createdAt: createdAt ?? this.createdAt,
      variants: variants ?? this.variants,
    );
  }
}
