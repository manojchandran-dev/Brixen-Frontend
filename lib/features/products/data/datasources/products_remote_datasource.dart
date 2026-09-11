import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/product_model.dart';

final productsRemoteDatasourceProvider = Provider<ProductsRemoteDatasource>((
  ref,
) {
  return ProductsRemoteDatasource(ref.read(dioProvider));
});

class ProductsRemoteDatasource {
  final Dio _dio;
  const ProductsRemoteDatasource(this._dio);

  Future<List<ProductModel>> getProducts({
    int page = 1,
    int limit = 200,
    String? search,
    String? category,
    String? unitId,
  }) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.products,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          'category': ?category,
          'unit_id': ?unitId,
        },
      );
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List) ? data : (data['items'] ?? []);
      return (list as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ProductModel> getProductById(String id, {String? companyId}) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.productById(id),
        queryParameters: _companyIdParam(companyId),
      );
      final data = resp.data['data'] ?? resp.data;
      return ProductModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ProductModel> createProduct(Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post(ApiEndpoints.products, data: body);
      final data = resp.data['data'] ?? resp.data;
      return ProductModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ProductModel> updateProduct(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  }) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.productById(id),
        data: body,
        queryParameters: _companyIdParam(companyId),
      );
      final data = resp.data['data'] ?? resp.data;
      return ProductModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ProductModel> updateStep2(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  }) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.productStep2(id),
        data: body,
        queryParameters: _companyIdParam(companyId),
      );
      final data = resp.data['data'] ?? resp.data;
      return ProductModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ProductModel> updateStep3(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  }) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.productStep3(id),
        data: body,
        queryParameters: _companyIdParam(companyId),
      );
      final data = resp.data['data'] ?? resp.data;
      return ProductModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ProductModel> updateStep4(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  }) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.productStep4(id),
        data: body,
        queryParameters: _companyIdParam(companyId),
      );
      final data = resp.data['data'] ?? resp.data;
      return ProductModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Map<String, dynamic>? _companyIdParam(String? companyId) =>
      companyId != null ? {'company_id': companyId} : null;

  Future<void> deleteProduct(String id, {String? companyId}) async {
    try {
      await _dio.delete(
        ApiEndpoints.productById(id),
        queryParameters: _companyIdParam(companyId),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
