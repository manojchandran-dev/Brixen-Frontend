import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/sale_item.dart';
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
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.sales,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (customerId != null && customerId.isNotEmpty)
            'customer_id': customerId,
          if (paymentStatus != null && paymentStatus.isNotEmpty)
            'payment_status': paymentStatus,
          if (from != null) 'from': toIsoDateOnly(from),
          if (to != null) 'to': toIsoDateOnly(to),
        },
      );
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List) ? data : (data['items'] ?? []);
      return (list as List)
          .map((e) => SaleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<SaleModel> getSaleById(String id, {String? companyId}) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.saleById(id),
        queryParameters: companyId != null ? {'company_id': companyId} : null,
      );
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

  Future<SaleModel> updateSaleItems(
    String id,
    Map<String, dynamic> body, {
    String? companyId,
  }) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.saleStep2(id),
        data: body,
        queryParameters: companyId != null ? {'company_id': companyId} : null,
      );
      final data = resp.data['data'] ?? resp.data;
      return SaleModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<SaleItem>> getSaleItems(String id, {String? companyId}) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.saleItems(id),
        queryParameters: companyId != null ? {'company_id': companyId} : null,
      );
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List) ? data : (data['items'] ?? []);
      return (list as List)
          .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deleteSale(String id, {String? companyId}) async {
    try {
      await _dio.delete(
        ApiEndpoints.saleById(id),
        queryParameters: companyId != null ? {'company_id': companyId} : null,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
