import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_role.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      // TODO: replace with real API call; role comes from response payload
      await Future.delayed(const Duration(seconds: 1));
      final role = UserRoleX.fromString(_mockRole(email));
      emit(AuthAuthenticated(role: role));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Temporary mock — remove when API is integrated
  String _mockRole(String email) {
    if (email.contains('super')) return 'super_admin';
    if (email.contains('admin')) return 'company_admin';
    return 'employee';
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required String companyCode,
  }) async {
    emit(const AuthLoading());
    try {
      // TODO: inject and call AuthRepository
      await Future.delayed(const Duration(seconds: 2));
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
