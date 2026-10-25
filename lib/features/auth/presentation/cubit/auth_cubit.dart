import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/token_refresh_interceptor.dart';
import '../../../../core/services/account_store.dart';
import '../../../../core/services/push_token_service.dart';
import '../../../../core/services/token_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/entities/user_role.dart';
import 'auth_state.dart';

/// [ApiException.toString] carries an `ApiException(401): ` prefix meant for
/// logs — show the backend's own message (e.g. "Invalid email or password")
/// exactly as it came back.
String _friendlyAuthError(Object e) =>
    e is ApiException ? e.message : e.toString();

final authCubit = AuthCubit();

/// Outcome of [AuthCubit.switchAccount].
enum SwitchResult {
  switched,

  /// The account's session has ended; it was removed from the saved
  /// accounts and must be signed into again. The previous account stays
  /// active.
  expired,

  /// No saved account with that email.
  notFound,
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      final result = await authRemoteDatasource.login(
        email: email,
        password: password,
      );
      // Clear first — a fresh sign-in is always a new identity, not a
      // token refresh, so nothing from whatever account was active before
      // (e.g. mid "Add account") should merge onto this one.
      await TokenService.clear();
      await TokenService.save(
        token: result['token']!,
        role: result['role']!,
        refreshToken: result['refreshToken'],
        userType: result['userType'],
        userId: (result['id'] as String?)?.isNotEmpty == true
            ? result['id']
            : null,
        employeeId: result['employeeId'],
        email: result['email'],
        companyId: result['companyId'],
        companyName: result['companyName'],
        companyCode: result['companyCode'],
        ownerName: result['ownerName'],
        subscriptionPlan: result['subscriptionPlan'],
        onboardingStatus: result['onboardingStatus'],
        companyStatus: result['companyStatus'],
      );
      await AccountStore.upsertCurrent();
      final role = UserRoleX.fromString(result['userType'] ?? result['role']);
      emit(AuthAuthenticated(role: role, hasPin: result['hasPin'] == true));
      unawaited(PushTokenService.register());
    } catch (e) {
      emit(AuthError(_friendlyAuthError(e)));
    }
  }

  /// Signs the active account out: revokes its refresh token on the server
  /// and forgets it in the account switcher (other saved accounts stay, and
  /// the sign-in page offers them).
  Future<void> signOut() async {
    await PushTokenService.unregister();
    final email = TokenService.email;
    final refreshToken = TokenService.refreshToken;
    if (refreshToken != null) {
      unawaited(authRemoteDatasource.logout(refreshToken));
    }
    if (email != null) await AccountStore.remove(email);
    await TokenService.clear();
    emit(const AuthUnauthenticated());
  }

  UserRole get _activeRole =>
      UserRoleX.fromString(TokenService.userType ?? TokenService.role);

  /// Switches the active session to an already-signed-in saved account
  /// (see [AccountStore]) — e.g. tapping another entry in the "More" tab's
  /// account switcher. Emitting [AuthLoading] first (even though the final
  /// role may equal the outgoing one) is what makes `authStateProvider`
  /// fire a fresh value — Cubit skips an emit that equals the *immediately
  /// preceding* one, not the whole history, so this guarantees every
  /// session-scoped Riverpod provider (dashboard/reports/modules) refetches
  /// for the new account instead of showing the previous one's cached data.
  ///
  /// A saved account's access token has usually expired (they last ~15
  /// minutes), so it's renewed with that account's refresh token. Only when
  /// that fails too is the account really signed out: then the previous
  /// account is put back — switching never logs anyone out — and
  /// [SwitchResult.expired] tells the caller to offer signing in again.
  Future<SwitchResult> switchAccount(String email) async {
    final target = AccountStore.find(email);
    if (target == null) return SwitchResult.notFound;
    // A refresh for the current account must finish before its tokens are
    // swapped out, or it would land on the account being switched to.
    await TokenRefreshInterceptor.settle();
    await AccountStore.upsertCurrent();
    final active = TokenService.email;
    final previous = active == null ? null : AccountStore.find(active);

    emit(const AuthLoading());
    await target.restoreToTokenService();
    if (!await _sessionAlive()) {
      // Dead for good (signed out, password changed, account deleted): drop
      // it so it doesn't linger in the switcher. Signing in adds it back.
      await AccountStore.remove(email);
      if (previous != null) {
        await previous.restoreToTokenService();
        emit(AuthAuthenticated(role: _activeRole));
      } else {
        await TokenService.clear();
        emit(const AuthUnauthenticated());
      }
      return SwitchResult.expired;
    }
    await AccountStore.upsertCurrent();
    emit(AuthAuthenticated(role: _activeRole));
    unawaited(PushTokenService.register());
    return SwitchResult.switched;
  }

  /// Whether the session now in [TokenService] works, renewing an expired
  /// access token first. Offline or a server hiccup counts as alive — the
  /// tokens may well be fine, and the app's own refresh handles it later.
  Future<bool> _sessionAlive() async {
    try {
      await authRemoteDatasource.validateSession();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode != 401) return true;
    } catch (_) {
      return true;
    }
    return TokenRefreshInterceptor.refreshNow(signOutOnFailure: false);
  }

  /// Called by splash to auto-login from stored token.
  void checkAuthStatus() {
    if (TokenService.isLoggedIn) {
      final role = UserRoleX.fromString(
        TokenService.userType ?? TokenService.role,
      );
      emit(AuthAuthenticated(role: role));
      unawaited(PushTokenService.register());
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required String companyCode,
  }) async {
    emit(const AuthLoading());
    try {
      // TODO: integrate sign-up API when available
      await Future.delayed(const Duration(seconds: 2));
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
