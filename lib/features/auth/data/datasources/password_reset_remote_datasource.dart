import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';

/// Standalone Dio for the forgot-password flow — pre-login, no Bearer token.
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

class PasswordResetRemoteDatasource {
  const PasswordResetRemoteDatasource();

  /// Emails a 6-digit OTP. The backend always returns success for a
  /// well-formed request (never leaks whether the email exists) — a thrown
  /// [ApiException] here means a real failure, e.g. Resend misconfigured.
  Future<void> sendOtp(String email) async {
    try {
      await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to send OTP');
    }
  }

  /// Returns a short-lived reset token on success.
  Future<String> verifyOtp({required String email, required String otp}) async {
    try {
      final resp = await _dio.post(ApiEndpoints.verifyOtp, data: {'email': email, 'otp': otp});
      final body = resp.data;
      final data = body['data'] ?? body;
      final token = (data['resetToken'] ?? data['reset_token'] ?? '').toString();
      if (token.isEmpty) {
        throw const ApiException('Verification succeeded but no reset token returned.');
      }
      return token;
    } on DioException catch (e) {
      throw _mapError(e, 'Invalid or expired code');
    }
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.post(ApiEndpoints.resetPassword, data: {
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to reset password');
    }
  }

  ApiException _mapError(DioException e, String fallback) {
    final status = e.response?.statusCode;
    final msg = e.response?.data?['message'] ?? e.response?.data?['error'] ?? e.message ?? fallback;
    return ApiException(msg.toString(), statusCode: status);
  }
}

final passwordResetRemoteDatasource = PasswordResetRemoteDatasource();
