import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/token_service.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));
  dio.interceptors.add(_AuthInterceptor());
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (o) => debugPrint(o.toString()),
  ));
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
