import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/token_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/entities/user_role.dart';
import 'auth_state.dart';

final authCubit = AuthCubit();

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final result = await authRemoteDatasource.login(
        email: email,
        password: password,
      );
      await TokenService.save(
        token: result['token']!,
        role: result['role']!,
        refreshToken: result['refreshToken'],
      );
      final role = UserRoleX.fromString(result['role']);
      emit(AuthAuthenticated(role: role, hasPin: result['hasPin'] == true));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    await TokenService.clear();
    emit(const AuthUnauthenticated());
  }

  /// Called by splash to auto-login from stored token.
  void checkAuthStatus() {
    if (TokenService.isLoggedIn) {
      final role = UserRoleX.fromString(TokenService.role);
      emit(AuthAuthenticated(role: role));
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
