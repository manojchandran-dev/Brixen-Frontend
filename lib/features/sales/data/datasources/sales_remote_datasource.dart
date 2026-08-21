import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/sale_model.dart';

final salesRemoteDatasourceProvider = Provider<SalesRemoteDatasource>((ref) {
  return SalesRemoteDatasource(ref.read(dioProvider));
});

class SalesRemoteDatasource {
  final Dio _dio;
  const SalesRemoteDatasource(this._dio);

  Future<List<SaleModel>> getSales({
    int page = 1,
    int limit = 200,
    String? search,
    String? customerId,
    String? paymentStatus,
  }) async {
    try {
      final resp = await _dio.get(ApiEndpoints.sales, queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (customerId != null && customerId.isNotEmpty) 'customer_id': customerId,
        if (paymentStatus != null && paymentStatus.isNotEmpty) 'payment_status': paymentStatus,
      });
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List) ? data : (data['items'] ?? []);
      return (list as List)
          .map((e) => SaleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<SaleModel> getSaleById(String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.saleById(id));
      final data = resp.data['data'] ?? resp.data;
      return SaleModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<SaleModel> createSale(Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post(ApiEndpoints.sales, data: body);
      final data = resp.data['data'] ?? resp.data;
      return SaleModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<SaleModel> updateSale(String id, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.put(ApiEndpoints.saleById(id), data: body);
      final data = resp.data['data'] ?? resp.data;
      return SaleModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deleteSale(String id) async {
    try {
      await _dio.delete(ApiEndpoints.saleById(id));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
