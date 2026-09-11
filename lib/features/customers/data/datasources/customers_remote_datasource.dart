import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/customer_model.dart';

final customersRemoteDatasourceProvider = Provider<CustomersRemoteDatasource>((ref) {
  return CustomersRemoteDatasource(ref.read(dioProvider));
});

class CustomersRemoteDatasource {
  final Dio _dio;
  const CustomersRemoteDatasource(this._dio);

  Future<List<CustomerModel>> getCustomers({
    int page = 1,
    int limit = 200,
    String? search,
  }) async {
    try {
      final resp = await _dio.get(ApiEndpoints.customers, queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List) ? data : (data['items'] ?? []);
      return (list as List)
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.customerById(id));
      final data = resp.data['data'] ?? resp.data;
      return CustomerModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CustomerModel> createCustomer(Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post(ApiEndpoints.customers, data: body);
      final data = resp.data['data'] ?? resp.data;
      return CustomerModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CustomerModel> updateCustomer(String id, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.put(ApiEndpoints.customerById(id), data: body);
      final data = resp.data['data'] ?? resp.data;
      return CustomerModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deleteCustomer(String id, {String? companyId}) async {
    try {
      await _dio.delete(
        ApiEndpoints.customerById(id),
        queryParameters: companyId != null ? {'company_id': companyId} : null,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
