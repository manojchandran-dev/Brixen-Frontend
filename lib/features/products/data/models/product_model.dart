import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    super.companyId,
    required super.productCode,
    required super.productName,
    super.categoryId,
    required super.category,
    required super.gender,
    super.designPattern,
    super.unitId,
    super.unit,
    super.color,
    super.size,
    required super.costPrice,
    required super.retailPrice,
    required super.wholesalePrice,
    super.galleryPaths,
    super.status,
    super.onboardingStatus,
    required super.createdAt,
  });

  /// `category`/`unit` (display names) aren't returned by the API — they're
  /// resolved client-side afterward from the already-loaded Masters data.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'].toString(),
      companyId: json['company_id']?.toString(),
      productCode: (json['product_code'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      categoryId: json['category_id']?.toString(),
      category: '',
      gender: (json['gender'] ?? '').toString(),
      designPattern: json['design_pattern'],
      unitId: json['unit_id']?.toString(),
      unit: null,
      color: json['color'],
      size: json['size'],
      costPrice: double.tryParse(json['cost_price'].toString()) ?? 0,
      retailPrice: double.tryParse(json['retail_price'].toString()) ?? 0,
      wholesalePrice: double.tryParse(json['wholesale_price'].toString()) ?? 0,
      status: (json['status'] ?? 'Active').toString(),
      galleryPaths: json['gallery_urls'] is List
          ? (json['gallery_urls'] as List).map((e) => e.toString()).toList()
          : const [],
      onboardingStatus: json['onboarding_status']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Step 1 (Basic) — POST /products. Only `product_name`/`gender` are
  /// required; `category_id`/`design_pattern` are optional. `companyId` is
  /// required — see `Session.companyId`.
  static Map<String, dynamic> toStep1Body(Product p, {required String companyId}) => {
    'company_id': int.parse(companyId),
    'product_name': p.productName,
    'gender': p.gender,
    if (p.categoryId != null) 'category_id': p.categoryId,
    if (p.designPattern != null && p.designPattern!.isNotEmpty)
      'design_pattern': p.designPattern,
  };

  /// Step 2 (Attributes) — PUT /products/:id/step2. All fields optional.
  static Map<String, dynamic> toStep2Body(Product p) => {
    if (p.unitId != null) 'unit_id': p.unitId,
    if (p.color != null && p.color!.isNotEmpty) 'color': p.color,
    if (p.size != null && p.size!.isNotEmpty) 'size': p.size,
  };

  /// Step 3 (Pricing) — PUT /products/:id/step3. All three prices required
  /// — this is the server's onboarding-completion gate.
  static Map<String, dynamic> toStep3Body(Product p) => {
    'cost_price': p.costPrice,
    'retail_price': p.retailPrice,
    'wholesale_price': p.wholesalePrice,
  };

  /// Step 4 (Gallery & Status) — PUT /products/:id/step4. Each entry in
  /// `galleryPaths` is a hosted URL already returned by `POST /uploads`
  /// (the wizard uploads each picked photo as soon as it's added, before
  /// this step ever fires) — never a local file path.
  static Map<String, dynamic> toStep4Body(Product p) => {
        'status': p.status,
        if (p.galleryPaths.isNotEmpty) 'gallery_urls': p.galleryPaths,
      };

  /// Generic full update (PUT /products/:id) — used for editing an existing
  /// product's basic info and for one-off changes like a status toggle.
  static Map<String, dynamic> toBody(Product p) => {
    'product_name': p.productName,
    'category_id': p.categoryId,
    'gender': p.gender,
    'unit_id': p.unitId,
    'cost_price': p.costPrice,
    'retail_price': p.retailPrice,
    'wholesale_price': p.wholesalePrice,
    'status': p.status,
    if (p.designPattern != null && p.designPattern!.isNotEmpty)
      'design_pattern': p.designPattern,
    if (p.color != null && p.color!.isNotEmpty) 'color': p.color,
    if (p.size != null && p.size!.isNotEmpty) 'size': p.size,
  };
}
