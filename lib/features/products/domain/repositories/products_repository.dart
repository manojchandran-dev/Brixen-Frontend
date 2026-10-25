import '../entities/product.dart';

abstract class ProductsRepository {
  Future<List<Product>> getProducts({
    Map<String, String> filters = const {},
    String? search,
    String? category,
    String? unitId,
  });
  Future<Product> getProductById(String id, {String? companyId});
  Future<Product> createProduct(Map<String, dynamic> body);
  Future<Product> updateProduct(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  });
  Future<Product> updateStep2(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  });
  Future<Product> updateStep3(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  });
  Future<Product> updateStep4(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  });

  /// PUT /:id/variants — the product's sizes/colours (full list).
  Future<Product> updateVariants(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  });
  Future<void> deleteProduct(String id, {String? companyId});
}
