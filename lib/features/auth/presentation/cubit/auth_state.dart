import 'package:equatable/equatable.dart';
import '../../domain/entities/user_role.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserRole role;

  /// Whether this account already has a PIN set server-side.
  /// Drives sign-in routing: false → create-PIN screen, true → enter-PIN screen.
  final bool hasPin;
  const AuthAuthenticated({this.role = UserRole.employee, this.hasPin = false});

  @override
  List<Object?> get props => [role, hasPin];
}

/// Signed in with a temporary password (an employee's first sign-in): a new
/// password must be set before anything else. Nothing is saved yet — [token]
/// is kept in memory only to set it, then the user signs in again.
class AuthPasswordChangeRequired extends AuthState {
  final String email;
  final String token;
  final String temporaryPassword;
  const AuthPasswordChangeRequired({
    required this.email,
    required this.token,
    required this.temporaryPassword,
  });

  @override
  List<Object?> get props => [email, token];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
