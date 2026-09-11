import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';

/// Standalone Dio for auth — no Bearer token needed for login itself.
final _dio = Dio(BaseOptions(
  baseUrl: ApiEndpoints.baseUrl,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
))..interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (o) => debugPrint(o.toString()),
  ));

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

      final token = (data['accessToken'] ?? data['access_token'] ?? data['token'] ?? '').toString();
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
      final rawCompanyId = user['company_id'] ?? user['companyId'] ?? company?['id'];
      final companyId = rawCompanyId?.toString();
      final companyName = (company?['company_name'] ?? company?['name'])?.toString();
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
      final rawEmployeeId = user['employee_id'] ??
          user['employeeId'] ??
          employee?['id'] ??
          (userType == 'employee' ? user['id'] : null);
      final employeeId = rawEmployeeId?.toString();

      return {
        'token': token,
        'refreshToken': (data['refreshToken'] ?? data['refresh_token'] ?? '').toString(),
        'role': role,
        'email': userEmail,
        'id': (user['id'] ?? '').toString(),
        'hasPin': hasPin,
        if (userType != null && userType.isNotEmpty) 'userType': userType,
        if (employeeId != null && employeeId.isNotEmpty) 'employeeId': employeeId,
        if (companyId != null && companyId.isNotEmpty) 'companyId': companyId,
        if (companyName != null && companyName.isNotEmpty) 'companyName': companyName,
        if (companyCode != null && companyCode.isNotEmpty) 'companyCode': companyCode,
        if (ownerName != null && ownerName.isNotEmpty) 'ownerName': ownerName,
        if (subscriptionPlan != null && subscriptionPlan.isNotEmpty) 'subscriptionPlan': subscriptionPlan,
        if (onboardingStatus != null && onboardingStatus.isNotEmpty) 'onboardingStatus': onboardingStatus,
        if (companyStatus != null && companyStatus.isNotEmpty) 'companyStatus': companyStatus,
      };
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Login failed';
      throw ApiException(msg.toString(), statusCode: status);
    }
  }
}

final authRemoteDatasource = AuthRemoteDatasource();
