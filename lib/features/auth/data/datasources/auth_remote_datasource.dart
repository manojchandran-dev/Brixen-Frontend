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
      final role = (user['role'] ?? user['user_type'] ?? 'employee').toString();
      final hasPin = (user['hasPin'] ?? data['hasPin']) == true;

      return {
        'token': token,
        'refreshToken': (data['refreshToken'] ?? data['refresh_token'] ?? '').toString(),
        'role': role,
        'email': (user['email'] ?? email).toString(),
        'id': (user['id'] ?? '').toString(),
        'hasPin': hasPin,
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
