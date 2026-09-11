import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/token_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/entities/user_role.dart';
import 'auth_state.dart';

/// [ApiException.toString] carries a `ApiException(401): ` prefix meant
/// for logs, not the SnackBar the user sees — extract the clean message,
/// and rephrase the backend's "Invalid email or password" into a more
/// actionable prompt rather than just restating what went wrong.
String _friendlyAuthError(Object e) {
  final message = e is ApiException ? e.message : e.toString();
  final lower = message.toLowerCase();
  final looksLikeBadCredentials = lower.contains('invalid') &&
      (lower.contains('email') || lower.contains('password') || lower.contains('credential'));
  return looksLikeBadCredentials ? 'Please check your email and password and try again.' : message;
}

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
        userType: result['userType'],
        userId: (result['id'] as String?)?.isNotEmpty == true ? result['id'] : null,
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
      final role = UserRoleX.fromString(result['userType'] ?? result['role']);
      emit(AuthAuthenticated(role: role, hasPin: result['hasPin'] == true));
    } catch (e) {
      emit(AuthError(_friendlyAuthError(e)));
    }
  }

  Future<void> signOut() async {
    await TokenService.clear();
    emit(const AuthUnauthenticated());
  }

  /// Called by splash to auto-login from stored token.
  void checkAuthStatus() {
    if (TokenService.isLoggedIn) {
      final role = UserRoleX.fromString(TokenService.userType ?? TokenService.role);
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
