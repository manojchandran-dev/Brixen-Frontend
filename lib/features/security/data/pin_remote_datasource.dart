import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/token_service.dart';

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

class PinRemoteDatasource {
  const PinRemoteDatasource();

  /// Sets or updates the server-side PIN hash.
  /// [currentPin] is required when the user already has a PIN set.
  Future<void> savePin({required String pin, String? currentPin}) async {
    final token = TokenService.token;
    if (token == null || token.isEmpty) {
      throw const ApiException('Not authenticated.');
    }
    final body = <String, dynamic>{'pin': pin};
    if (currentPin != null) body['currentPin'] = currentPin;
    try {
      await _dio.post(
        ApiEndpoints.authPin,
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = e.response?.data?['message'] ??
          e.message ??
          'Failed to save PIN';
      throw ApiException(msg.toString(), statusCode: status);
    }
  }

  /// Verifies the PIN against the server using the stored refresh token.
  /// On success, returns fresh `{ token, refreshToken, role }`.
  /// Throws [ApiException] with statusCode 401 if the session has expired.
  Future<Map<String, String>> verifyPin({required String pin}) async {
    final refreshToken = TokenService.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }
    try {
      final resp = await _dio.post(
        ApiEndpoints.authPinVerify,
        data: {'refreshToken': refreshToken, 'pin': pin},
      );
      final body = resp.data;
      final data = body['data'] ?? body;
      final token =
          (data['accessToken'] ?? data['access_token'] ?? '').toString();
      if (token.isEmpty) {
        throw const ApiException('PIN verification returned no token.');
      }
      final newRefresh =
          (data['refreshToken'] ?? data['refresh_token'] ?? '').toString();
      final user = (data['user'] ?? data) as Map<String, dynamic>;
      final role =
          (user['role'] ?? TokenService.role ?? 'employee').toString();
      return {
        'token': token,
        'refreshToken': newRefresh,
        'role': role,
      };
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = e.response?.data?['message'] ??
          e.message ??
          'PIN verification failed';
      throw ApiException(msg.toString(), statusCode: status);
    }
  }
}

final pinRemoteDatasource = PinRemoteDatasource();
