import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../shared/providers/super_admin_company_filter_provider.dart';
import '../services/session_service.dart';
import '../services/token_service.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'token_refresh_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
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
  dio.interceptors.add(_AuthInterceptor());
  dio.interceptors.add(TokenRefreshInterceptor());
  dio.interceptors.add(CompanyScopeInterceptor(ref));
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugPrint(o.toString()),
    ),
  );
  return dio;
});

/// Attaches Bearer token from TokenService to every request (if available).
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

/// Every business-record endpoint (list/get/update/delete — not just
/// create) requires `company_id`, and every endpoint benefits from knowing
/// which of superadmin/company/employee is calling — so both are attached
/// here automatically rather than making every datasource method thread
/// them through by hand.
///
/// companyAdmin/employee sessions always send their own single company
/// (`Session.companyId`). superAdmin has no single company by default, but
/// can pick one to browse as via [superAdminCompanyFilterProvider] (the
/// dropdown on the Employees/Customers/Products/Sales/Expenses list
/// screens) — when unset, `company_id` is simply omitted, matching the
/// previous "all companies" behaviour. Never overrides a value a caller
/// already set explicitly.
///
/// [ref] is optional: the Masters datasources build their own standalone
/// `Dio` outside the Riverpod graph (module-level singletons, not
/// providers), so they can't supply one — those instances just don't get
/// the superAdmin filter applied, everything else here still works.
class CompanyScopeInterceptor extends Interceptor {
  final Ref? ref;
  CompanyScopeInterceptor([this.ref]);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.queryParameters.containsKey('company_id')) {
      if (Session.isSuperAdmin) {
        final companyId = ref?.read(superAdminCompanyFilterProvider)?.id;
        // GET (list/summary) endpoints always send company_id — the selected
        // company's id, or the literal string 'null' when browsing "All
        // Companies" — so the backend can distinguish "no filter" from a
        // missing param. Writes (create/update/delete) only send it when a
        // real id is known: callers that act on a specific record (e.g. the
        // product edit wizard) pass their own explicit company_id instead,
        // since the record's owning company may differ from whatever the
        // list filter currently happens to be browsing.
        if (companyId != null) {
          options.queryParameters['company_id'] = companyId;
        } else if (options.method == 'GET') {
          options.queryParameters['company_id'] = 'null';
        }
      } else if (Session.companyId != null) {
        options.queryParameters['company_id'] = Session.companyId;
      }
    }
    if (!options.queryParameters.containsKey('user_type')) {
      options.queryParameters['user_type'] = Session.role.apiValue;
    }
    handler.next(options);
  }
}

/// Helper to map DioException to ApiException.
ApiException mapDioError(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return const ApiException('Connection timed out. Check your network.');
  }
  if (e.type == DioExceptionType.connectionError) {
    return const ApiException('Cannot reach server. Check your network.');
  }
  final status = e.response?.statusCode;
  final msg = e.response?.data?['message'] ?? e.message ?? 'Unknown error';
  return ApiException(msg.toString(), statusCode: status);
}
