import 'package:dio/dio.dart';

/// Retries a failed GET up to twice (after 1s, then 2s) when the failure is
/// passing: a dropped connection, a timeout, or the server answering 502/
/// 503/504 while it (or its database) wakes from sleep. Writes are never
/// retried, so a sale can't be saved twice.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  RetryInterceptor(this.dio);

  static const _delays = [Duration(seconds: 1), Duration(seconds: 2)];

  static bool _passing(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.unknown => true,
    DioExceptionType.badResponse => const {
      502,
      503,
      504,
    }.contains(e.response?.statusCode),
    _ => false,
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final tries = options.extra['retries'] as int? ?? 0;
    if (options.method != 'GET' || tries >= _delays.length || !_passing(err)) {
      return handler.next(err);
    }
    await Future<void>.delayed(_delays[tries]);
    try {
      options.extra['retries'] = tries + 1;
      handler.resolve(await dio.fetch(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
