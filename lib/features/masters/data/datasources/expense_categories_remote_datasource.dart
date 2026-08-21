import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart' show mapDioError;
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/token_service.dart';
import '../../domain/entities/master_item.dart';
import 'remote_master_datasource.dart';

final _dio = Dio(BaseOptions(
  baseUrl: ApiEndpoints.baseUrl,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
))
  ..interceptors.add(_AuthInterceptor())
  ..interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (o) => debugPrint(o.toString()),
  ));

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = TokenService.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Global expense categories — not tied to any company.
class ExpenseCategoriesRemoteDatasource implements RemoteMasterDatasource {
  const ExpenseCategoriesRemoteDatasource();

  Future<MasterItem> getById(String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.expenseCategoryById(id));
      final data = resp.data['data'] ?? resp.data;
      return _fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<MasterItem>> getAll({int page = 1, int limit = 100, String? search}) async {
    try {
      final resp = await _dio.get(ApiEndpoints.expenseCategories, queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List) ? data : (data['items'] ?? data['categories'] ?? []);
      return (list as List)
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<MasterItem> create({
    required String name,
    String? description,
    String? fullForm,
    bool isActive = true,
  }) async {
    try {
      final resp = await _dio.post(ApiEndpoints.expenseCategories, data: {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        'status': isActive ? 'ACTIVE' : 'INACTIVE',
      });
      final data = resp.data['data'] ?? resp.data;
      return _fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<MasterItem> update(
    String id, {
    String? name,
    String? description,
    String? fullForm,
    bool? isActive,
  }) async {
    try {
      final resp = await _dio.put(ApiEndpoints.expenseCategoryById(id), data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (isActive != null) 'status': isActive ? 'ACTIVE' : 'INACTIVE',
      });
      final data = resp.data['data'] ?? resp.data;
      return _fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.expenseCategoryById(id));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  MasterItem _fromJson(Map<String, dynamic> json) => MasterItem(
        id: json['id'].toString(),
        typeKey: 'expenseCategory',
        name: (json['name'] ?? '').toString(),
        description: json['description'] as String?,
        isActive: (json['status']?.toString().toUpperCase() ?? 'ACTIVE') == 'ACTIVE',
        createdAt: (json['created_at'] ?? json['createdAt']) != null
            ? DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

final expenseCategoriesRemoteDatasource = ExpenseCategoriesRemoteDatasource();
