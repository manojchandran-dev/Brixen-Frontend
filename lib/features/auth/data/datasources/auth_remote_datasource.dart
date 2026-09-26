import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/token_service.dart';

/// Standalone Dio for auth — no Bearer token needed for login itself.
/// Timeouts are long on purpose: the backend (Render + Neon) sleeps when
/// idle, and the first login after that waits ~20–60s for it to boot. At
/// 30s that first login timed out and looked like bad credentials.
final _dio =
    Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      )
      ..interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );

class AuthRemoteDatasource {
  const AuthRemoteDatasource();

  /// Returns a map with keys: `token`, `role`, `name`, `email`, `id`, `hasPin`.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final body = resp.data;
      final data = body['data'] ?? body;

      final token =
          (data['accessToken'] ?? data['access_token'] ?? data['token'] ?? '')
              .toString();
      if (token.isEmpty) {
        throw const ApiException('Login succeeded but no token returned.');
      }

      final user = (data['user'] ?? data) as Map<String, dynamic>;
      final company = user['company'] is Map
          ? user['company'] as Map<String, dynamic>
          : null;
      final role = (user['role'] ?? 'employee').toString();
      // The server's coarse three-way split ("superadmin"/"company"/
      // "employee") — distinct from `role`, which can be finer-grained
      // (e.g. "company_admin"). Preferred for any role-based branching.
      final userType = (user['user_type'] ?? user['userType'])?.toString();
      final hasPin = (user['hasPin'] ?? data['hasPin']) == true;
      // A companyAdmin/employee account belongs to exactly one company —
      // captured here so those roles never have to pick one manually.
      // superAdmin accounts don't carry this at all.
      final rawCompanyId =
          user['company_id'] ?? user['companyId'] ?? company?['id'];
      final companyId = rawCompanyId?.toString();
      final companyName = (company?['company_name'] ?? company?['name'])
          ?.toString();
      final companyCode = company?['company_code']?.toString();
      final ownerName = company?['owner_name']?.toString();
      final subscriptionPlan = company?['subscription_plan']?.toString();
      final onboardingStatus = company?['onboarding_status']?.toString();
      final companyStatus = company?['status']?.toString();
      final userEmail = (user['email'] ?? email).toString();
      // For an `employee` login, `GET /api/v1/modules` needs the employee's
      // own row id. Mirrors the `company` nesting pattern defensively —
      // may come back as a sibling field, nested under `user.employee`, or
      // (most likely, if the employee IS the login row) just `user.id`.
      final employee = user['employee'] is Map
          ? user['employee'] as Map<String, dynamic>
          : null;
      final rawEmployeeId =
          user['employee_id'] ??
          user['employeeId'] ??
          employee?['id'] ??
          (userType == 'employee' ? user['id'] : null);
      final employeeId = rawEmployeeId?.toString();

      return {
        'token': token,
        'refreshToken': (data['refreshToken'] ?? data['refresh_token'] ?? '')
            .toString(),
        'role': role,
        'email': userEmail,
        'id': (user['id'] ?? '').toString(),
        'hasPin': hasPin,
        if (userType != null && userType.isNotEmpty) 'userType': userType,
        if (employeeId != null && employeeId.isNotEmpty)
          'employeeId': employeeId,
        if (companyId != null && companyId.isNotEmpty) 'companyId': companyId,
        if (companyName != null && companyName.isNotEmpty)
          'companyName': companyName,
        if (companyCode != null && companyCode.isNotEmpty)
          'companyCode': companyCode,
        if (ownerName != null && ownerName.isNotEmpty) 'ownerName': ownerName,
        if (subscriptionPlan != null && subscriptionPlan.isNotEmpty)
          'subscriptionPlan': subscriptionPlan,
        if (onboardingStatus != null && onboardingStatus.isNotEmpty)
          'onboardingStatus': onboardingStatus,
        if (companyStatus != null && companyStatus.isNotEmpty)
          'companyStatus': companyStatus,
      };
    } on DioException catch (e) {
      // No reply at all is never "wrong credentials" — say what happened.
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const ApiException(
          'The server is taking too long to respond. Please try again.',
        );
      }
      if (e.response == null) {
        throw const ApiException(
          'Unable to connect to server. Check your internet connection.',
        );
      }
      final status = e.response!.statusCode;
      final data = e.response!.data;
      final serverMsg = data is Map ? (data['message'] ?? data['error']) : null;
      final msg =
          serverMsg ??
          switch (status) {
            401 => 'Invalid email or password',
            403 => 'Your company account is inactive.',
            _ => 'Login failed',
          };
      throw ApiException(msg.toString(), statusCode: status);
    }
  }

  /// Wakes a sleeping backend in the background so it is warm by the time
  /// the user submits the sign-in form. Result and errors are ignored.
  static void warmUp() {
    _dio.get(ApiEndpoints.health).ignore();
  }

  /// Confirms the token currently held by [TokenService] (just restored
  /// from a saved account snapshot) is still accepted by the server. A
  /// saved snapshot's token can have expired since that account was last
  /// active — switching to it should surface that as a clear "sign in
  /// again" instead of silently landing on a dashboard where every request
  /// then fails with a confusing 401. Throws [ApiException] (statusCode
  /// 401) when the session is dead.
  Future<void> validateSession() async {
    try {
      await _dio.get(
        ApiEndpoints.me,
        options: Options(
          headers: {'Authorization': 'Bearer ${TokenService.token}'},
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg =
          e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Session check failed';
      throw ApiException(msg.toString(), statusCode: status);
    }
  }
}

final authRemoteDatasource = AuthRemoteDatasource();
