import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';
import '../services/account_store.dart';
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

    // Sent with a token that's no longer current — the user switched
    // accounts, or another 401 already refreshed. Replay with the current
    // token instead of spending the (single-use) refresh token on it.
    final sentWith = options.headers['Authorization'];
    final current = 'Bearer ${TokenService.token}';
    if (sentWith != null && sentWith != current) {
      return _replay(options, handler);
    }

    final refreshed = await (_inFlight ??= refreshNow().whenComplete(
      () => _inFlight = null,
    ));
    if (!refreshed) return handler.next(err);
    return _replay(options, handler);
  }

  static Future<void> _replay(
    RequestOptions options,
    ErrorInterceptorHandler handler,
  ) async {
    options.extra['retried'] = true;
    options.headers['Authorization'] = 'Bearer ${TokenService.token}';
    try {
      handler.resolve(await _plain.fetch(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Waits for a refresh that's under way, if any — account switching calls
  /// this first so a refresh can't land in the middle of the switch.
  static Future<void> settle() async {
    try {
      await _inFlight;
    } catch (_) {}
  }

  /// Swaps the active session's refresh token for a new pair and saves it
  /// ([TokenService.save] also updates the account switcher's copy). On
  /// failure the session is over: with [signOutOnFailure] it's cleared and
  /// the user sent to sign-in; without, the caller decides (e.g. account
  /// switching).
  ///
  /// If the active account changed while the refresh was under way, the
  /// new pair belongs to the account it was started for: it goes into that
  /// account's saved copy, the active session is left alone, nobody is
  /// signed out, and this returns false.
  static Future<bool> refreshNow({bool signOutOnFailure = true}) async {
    final refreshToken = TokenService.refreshToken;
    final email = TokenService.email;
    if (refreshToken == null) return false;
    bool switchedAway() => TokenService.refreshToken != refreshToken;
    try {
      final resp = await _plain.post(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
      );
      final data = resp.data['data'] as Map<String, dynamic>;
      final token = data['accessToken'] as String;
      final newRefresh = data['refreshToken'] as String?;
      if (switchedAway()) {
        if (email != null) {
          await AccountStore.updateTokens(
            email,
            token: token,
            refreshToken: newRefresh,
          );
        }
        return false;
      }
      await TokenService.save(
        token: token,
        role: TokenService.role ?? '',
        refreshToken: newRefresh,
      );
      return true;
    } catch (e) {
      debugPrint('[TokenRefreshInterceptor] refresh failed: $e');
      if (signOutOnFailure && !switchedAway()) {
        await TokenService.clear();
        AppRouter.router.go(RouteNames.signIn);
      }
      return false;
    }
  }
}
