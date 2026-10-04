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
  final DateTime createdAt;

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
    required this.createdAt,
  });

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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
