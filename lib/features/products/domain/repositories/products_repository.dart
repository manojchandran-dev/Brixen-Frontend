import '../entities/product.dart';

abstract class ProductsRepository {
  Future<List<Product>> getProducts({
    int page = 1,
    int limit = 200,
    String? search,
    String? category,
    String? unitId,
  });
  Future<Product> getProductById(String id, {String? companyId});
  Future<Product> createProduct(Map<String, dynamic> body);
  Future<Product> updateProduct(String id, Map<String, dynamic> body, {String? companyId});
  Future<Product> updateStep2(String id, Map<String, dynamic> body, {String? companyId});
  Future<Product> updateStep3(String id, Map<String, dynamic> body, {String? companyId});
  Future<Product> updateStep4(String id, Map<String, dynamic> body, {String? companyId});
  Future<void> deleteProduct(String id, {String? companyId});
}
