import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';
import '../services/token_service.dart';
import 'api_endpoints.dart';

/// Access tokens expire after ~15 minutes and every API route now requires
/// one. On a 401 this swaps the refresh token for a new pair
/// (`POST /auth/refresh`) and replays the request once. If the refresh
/// itself fails the session is over: tokens are cleared and the user is
/// sent to sign-in.
///
/// Add it to every authenticated Dio instance (after the auth interceptor).
class TokenRefreshInterceptor extends Interceptor {
  // Bare client for the refresh call and the replay. The replayed options
  // already carry every header/query param the other interceptors added.
  static final _plain = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));

  // Refresh tokens are single-use (the server rotates them), so concurrent
  // 401s must share one refresh instead of each spending the token.
  static Future<bool>? _inFlight;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    // Calls that use or hand out tokens themselves: a 401 there (wrong
    // password/PIN, dead refresh token) must not trigger a refresh.
    final isAuthCall = [
      '/auth/refresh',
      '/auth/login',
      '/auth/pin/verify',
      '/auth/pin/forgot',
      '/auth/pin/forgot/verify',
      '/auth/pin/reset',
    ].any(options.path.endsWith);
    if (err.response?.statusCode != 401 ||
        options.extra['retried'] == true ||
        isAuthCall ||
        TokenService.refreshToken == null) {
      return handler.next(err);
    }

    final refreshed = await (_inFlight ??= _refresh().whenComplete(
      () => _inFlight = null,
    ));
    if (!refreshed) return handler.next(err);

    options.extra['retried'] = true;
    options.headers['Authorization'] = 'Bearer ${TokenService.token}';
    try {
      handler.resolve(await _plain.fetch(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  static Future<bool> _refresh() async {
    try {
      final resp = await _plain.post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': TokenService.refreshToken},
      );
      final data = resp.data['data'] as Map<String, dynamic>;
      await TokenService.save(
        token: data['accessToken'] as String,
        role: TokenService.role ?? '',
        refreshToken: data['refreshToken'] as String?,
      );
      return true;
    } catch (e) {
      debugPrint('[TokenRefreshInterceptor] refresh failed, signing out: $e');
      await TokenService.clear();
      AppRouter.router.go(RouteNames.signIn);
      return false;
    }
  }
}
