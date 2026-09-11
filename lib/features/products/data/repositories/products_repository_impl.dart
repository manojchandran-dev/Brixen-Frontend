import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_remote_datasource.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepositoryImpl(ref.read(productsRemoteDatasourceProvider));
});

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDatasource _ds;
  const ProductsRepositoryImpl(this._ds);

  @override
  Future<List<Product>> getProducts({
    int page = 1,
    int limit = 200,
    String? search,
    String? category,
    String? unitId,
  }) =>
      _ds.getProducts(page: page, limit: limit, search: search, category: category, unitId: unitId);

  @override
  Future<Product> getProductById(String id, {String? companyId}) =>
      _ds.getProductById(id, companyId: companyId);

  @override
  Future<Product> createProduct(Map<String, dynamic> body) => _ds.createProduct(body);

  @override
  Future<Product> updateProduct(String id, Map<String, dynamic> body, {String? companyId}) =>
      _ds.updateProduct(id, body, companyId: companyId);

  @override
  Future<Product> updateStep2(String id, Map<String, dynamic> body, {String? companyId}) =>
      _ds.updateStep2(id, body, companyId: companyId);

  @override
  Future<Product> updateStep3(String id, Map<String, dynamic> body, {String? companyId}) =>
      _ds.updateStep3(id, body, companyId: companyId);

  @override
  Future<Product> updateStep4(String id, Map<String, dynamic> body, {String? companyId}) =>
      _ds.updateStep4(id, body, companyId: companyId);

  @override
  Future<void> deleteProduct(String id, {String? companyId}) =>
      _ds.deleteProduct(id, companyId: companyId);
}
