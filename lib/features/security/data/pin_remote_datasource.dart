import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_refresh_interceptor.dart';
import '../../../core/services/token_service.dart';

final _dio =
    Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      )
      ..interceptors.add(TokenRefreshInterceptor())
      ..interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );

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
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg =
          e.response?.data?['message'] ?? e.message ?? 'Failed to save PIN';
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
      return _tokens(resp.data, 'PIN verification returned no token.');
    } on DioException catch (e) {
      throw _error(e, 'PIN verification failed');
    }
  }

  // ── Forgot PIN ──────────────────────────────────────────────────────────

  String get _refresh {
    final t = TokenService.refreshToken;
    if (t == null || t.isEmpty) {
      throw const ApiException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }
    return t;
  }

  /// Emails a 6-digit OTP to the account's address. Returns the (masked)
  /// address it went to, for "Code sent to m***@gmail.com".
  Future<String> forgotPin() async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.authPinForgot,
        data: {'refreshToken': _refresh},
      );
      final data = resp.data['data'] ?? resp.data;
      return data is Map ? (data['email'] ?? '').toString() : '';
    } on DioException catch (e) {
      throw _error(e, 'Could not send the code');
    }
  }

  /// Checks the emailed OTP; returns a short-lived reset token.
  Future<String> verifyForgotPinOtp(String otp) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.authPinForgotVerify,
        data: {'refreshToken': _refresh, 'otp': otp},
      );
      final data = resp.data['data'] ?? resp.data;
      final token = (data is Map ? data['resetToken'] ?? '' : '').toString();
      if (token.isEmpty) throw const ApiException('No reset token returned.');
      return token;
    } on DioException catch (e) {
      throw _error(e, 'Could not verify the code');
    }
  }

  /// Sets the new PIN with the reset token; returns fresh tokens (like
  /// [verifyPin]) so the user goes straight in.
  Future<Map<String, String>> resetPin({
    required String resetToken,
    required String pin,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.authPinReset,
        data: {'resetToken': resetToken, 'pin': pin},
      );
      return _tokens(resp.data, 'PIN reset returned no token.');
    } on DioException catch (e) {
      throw _error(e, 'Could not reset the PIN');
    }
  }

  static Map<String, String> _tokens(dynamic body, String missing) {
    final data = body['data'] ?? body;
    final token = (data['accessToken'] ?? data['access_token'] ?? '')
        .toString();
    if (token.isEmpty) throw ApiException(missing);
    final newRefresh = (data['refreshToken'] ?? data['refresh_token'] ?? '')
        .toString();
    final user = (data['user'] ?? data) as Map<String, dynamic>;
    final role = (user['role'] ?? TokenService.role ?? 'employee').toString();
    return {'token': token, 'refreshToken': newRefresh, 'role': role};
  }

  static ApiException _error(DioException e, String fallback) {
    final body = e.response?.data;
    final msg = (body is Map ? body['message'] : null) ?? e.message ?? fallback;
    return ApiException(msg.toString(), statusCode: e.response?.statusCode);
  }
}

final pinRemoteDatasource = PinRemoteDatasource();
