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

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
