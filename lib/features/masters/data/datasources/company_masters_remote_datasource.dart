import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart'
    show mapDioError, CompanyScopeInterceptor;
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/retry_interceptor.dart';
import '../../../../core/network/token_refresh_interceptor.dart';
import '../../../../core/services/token_service.dart';
import '../../domain/entities/master_item.dart';
import 'remote_master_datasource.dart';

final _dio = () {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  return dio
    ..interceptors.add(_AuthInterceptor())
    ..interceptors.add(TokenRefreshInterceptor())
    ..interceptors.add(CompanyScopeInterceptor())
    ..interceptors.add(RetryInterceptor(dio))
    ..interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
}();

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

/// A company's own staff lists — Departments and Work Types — which share
/// one API shape (`/departments`, `/work-types`): name, description,
/// ACTIVE/INACTIVE, and for work types a rate per piece. Ids are made by the
/// server.
class CompanyMasterRemoteDatasource implements RemoteMasterDatasource {
  final String typeKey;
  final String path;
  final String Function(String id) pathById;

  /// Work types carry a required rate.
  final bool hasRate;

  const CompanyMasterRemoteDatasource({
    required this.typeKey,
    required this.path,
    required this.pathById,
    this.hasRate = false,
  });

  @override
  Future<MasterItem> getById(String id) async {
    try {
      final resp = await _dio.get(pathById(id));
      return _fromJson(
        (resp.data['data'] ?? resp.data) as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<MasterItem>> getAll({
    int page = 1,
    int limit = 100,
    String? search,
  }) async {
    try {
      final resp = await _dio.get(
        path,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final data = resp.data['data'] ?? resp.data;
      final list = data is List ? data : (data['items'] ?? const []);
      return [
        for (final e in list as List) _fromJson(e as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MasterItem> create({
    required String name,
    String? description,
    String? fullForm,
    double? rate,
    bool isActive = true,
    String? companyId,
  }) async {
    try {
      final resp = await _dio.post(
        path,
        data: {
          'company_id': int.parse(companyId!),
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (hasRate) 'rate': rate,
          'status': isActive ? 'ACTIVE' : 'INACTIVE',
        },
      );
      return _fromJson(
        (resp.data['data'] ?? resp.data) as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MasterItem> update(
    String id, {
    String? name,
    String? description,
    String? fullForm,
    double? rate,
    bool? isActive,
  }) async {
    try {
      final resp = await _dio.put(
        pathById(id),
        data: {
          'name': ?name,
          // Sent even when empty, so a description can be cleared.
          'description': description ?? '',
          if (hasRate && rate != null) 'rate': rate,
          if (isActive != null) 'status': isActive ? 'ACTIVE' : 'INACTIVE',
        },
      );
      return _fromJson(
        (resp.data['data'] ?? resp.data) as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete(pathById(id));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  MasterItem _fromJson(Map<String, dynamic> json) => MasterItem(
    id: json['id'].toString(),
    typeKey: typeKey,
    name: (json['name'] ?? '').toString(),
    description: json['description'] as String?,
    isActive:
        (json['status']?.toString().toUpperCase() ?? 'ACTIVE') == 'ACTIVE',
    rate: json['rate'] == null
        ? null
        : double.tryParse(json['rate'].toString()),
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
  );
}

const departmentsRemoteDatasource = CompanyMasterRemoteDatasource(
  typeKey: 'department',
  path: ApiEndpoints.departments,
  pathById: ApiEndpoints.departmentById,
);

const workTypesRemoteDatasource = CompanyMasterRemoteDatasource(
  typeKey: 'workType',
  path: ApiEndpoints.workTypes,
  pathById: ApiEndpoints.workTypeById,
  hasRate: true,
);
