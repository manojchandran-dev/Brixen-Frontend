import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/session_service.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/nav_module.dart';

final navModulesRemoteDatasourceProvider = Provider<NavModulesRemoteDatasource>((
  ref,
) {
  return NavModulesRemoteDatasource(ref.read(dioProvider));
});

class NavModulesRemoteDatasource {
  final Dio _dio;
  const NavModulesRemoteDatasource(this._dio);

  /// Returns the menu as a nested tree — top-level modules with a
  /// `children` array already attached, exactly as the API returns it.
  ///
  /// Scoped by the logged-in session: superAdmin gets the full tree;
  /// companyAdmin gets only their company's `view: true` modules;
  /// employee gets the same, resolved server-side from their
  /// `employee_id` (employees don't have their own permission rows —
  /// they inherit whatever their company has access to).
  Future<List<NavModule>> getModules() async {
    try {
      final role = Session.role;
      final resp = await _dio.get(
        ApiEndpoints.modules,
        queryParameters: {
          'user_type': role.apiValue,
          if (role == UserRole.companyAdmin && Session.companyId != null)
            'company_id': Session.companyId,
          if (role == UserRole.employee && Session.employeeId != null)
            'employee_id': Session.employeeId,
        },
      );
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List) ? data : (data['items'] ?? data['modules'] ?? []);
      return (list as List)
          .map((e) => NavModule.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// The modules a superadmin can give a company — the Permissions screen's
  /// list. Unlike [getModules] (the caller's own menu), this excludes the
  /// superadmin-only modules and includes every company module.
  Future<List<NavModule>> getGrantableModules() async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.modules,
        queryParameters: {'for': 'permissions', 'user_type': Session.role.apiValue},
      );
      final data = resp.data['data'] ?? resp.data;
      final list = (data is List) ? data : (data['items'] ?? data['modules'] ?? []);
      return (list as List)
          .map((e) => NavModule.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
