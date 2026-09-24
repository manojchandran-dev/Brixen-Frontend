import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
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

  Future<void> signOut() async {
    await PushTokenService.unregister();
    await TokenService.clear();
    emit(const AuthUnauthenticated());
  }

  /// Switches the active session to an already-signed-in saved account
  /// (see [AccountStore]) — e.g. tapping another entry in the "More" tab's
  /// account switcher. Emitting [AuthLoading] first (even though the final
  /// role may equal the outgoing one) is what makes `authStateProvider`
  /// fire a fresh value — Cubit skips an emit that equals the *immediately
  /// preceding* one, not the whole history, so this guarantees every
  /// session-scoped Riverpod provider (dashboard/reports/modules) refetches
  /// for the new account instead of showing the previous one's cached data.
  ///
  /// Returns `false` when the saved snapshot's token has since expired —
  /// its whole point is catching that *before* switching in, since a saved
  /// token can easily be stale (it's whatever was last active for that
  /// account, with no refresh flow to keep it current). The dead snapshot
  /// is dropped and the active session cleared so the caller can send the
  /// user to sign back into that account, rather than landing them on a
  /// dashboard where every request then fails with a confusing 401.
  Future<bool> switchAccount(String email) async {
    final snapshot = AccountStore.find(email);
    if (snapshot == null) return false;
    await AccountStore.upsertCurrent();
    emit(const AuthLoading());
    await snapshot.restoreToTokenService();
    try {
      await authRemoteDatasource.validateSession();
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await AccountStore.remove(email);
        await TokenService.clear();
        emit(const AuthUnauthenticated());
        return false;
      }
      // Any other failure (offline, timeout, server hiccup) shouldn't block
      // the switch — the token itself may still be fine.
    }
    final role = UserRoleX.fromString(
      TokenService.userType ?? TokenService.role,
    );
    emit(AuthAuthenticated(role: role));
    unawaited(PushTokenService.register());
    return true;
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
