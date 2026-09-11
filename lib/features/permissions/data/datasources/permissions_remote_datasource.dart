import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/permission_model.dart';

final permissionsRemoteDatasourceProvider = Provider<PermissionsRemoteDatasource>((
  ref,
) {
  return PermissionsRemoteDatasource(ref.read(dioProvider));
});

class PermissionsRemoteDatasource {
  final Dio _dio;
  const PermissionsRemoteDatasource(this._dio);

  Future<List<PermissionModel>> getPermissions({
    required String companyId,
    String? moduleId,
  }) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.permissions,
        queryParameters: {'company_id': companyId, 'module_id': ?moduleId},
      );
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List) ? data : (data['items'] ?? []);
      return (list as List)
          .map((e) => PermissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<PermissionModel> create({
    required String companyId,
    required String moduleId,
    required bool view,
    required bool create,
    required bool edit,
    required bool delete,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.permissions,
        data: {
          'company_id': int.parse(companyId),
          'module_id': moduleId,
          'view': view,
          'create': create,
          'edit': edit,
          'delete': delete,
        },
      );
      final data = resp.data['data'] ?? resp.data;
      return PermissionModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<PermissionModel> update(
    String id, {
    required String companyId,
    required bool view,
    required bool create,
    required bool edit,
    required bool delete,
  }) async {
    try {
      final resp = await _dio.put(
        ApiEndpoints.permissionById(id),
        queryParameters: {'company_id': companyId},
        data: {'view': view, 'create': create, 'edit': edit, 'delete': delete},
      );
      final data = resp.data['data'] ?? resp.data;
      return PermissionModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Upserts many modules for a company in one request — matches the
  /// "New/Edit Permissions" screen's final submit. Re-submitting the same
  /// set is safe: existing (company_id, module_id) rows are updated in
  /// place, not duplicated.
  Future<List<PermissionModel>> bulkUpsert({
    required String companyId,
    required List<Map<String, dynamic>> permissions,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.permissionsBulk,
        data: {
          'company_id': int.parse(companyId),
          'permissions': permissions,
        },
      );
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List) ? data : (data['items'] ?? []);
      return (list as List)
          .map((e) => PermissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(String id, {required String companyId}) async {
    try {
      await _dio.delete(
        ApiEndpoints.permissionById(id),
        queryParameters: {'company_id': companyId},
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
