import 'package:equatable/equatable.dart';

enum SecurityStatus { initial, loading, ready }

class SecurityState extends Equatable {
  final bool isPinEnabled;
  final bool isBiometricEnabled;
  final bool isBiometricAvailable;
  final SecurityStatus status;

  const SecurityState({
    this.isPinEnabled = false,
    this.isBiometricEnabled = false,
    this.isBiometricAvailable = false,
    this.status = SecurityStatus.initial,
  });

  SecurityState copyWith({
    bool? isPinEnabled,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
    SecurityStatus? status,
  }) =>
      SecurityState(
        isPinEnabled: isPinEnabled ?? this.isPinEnabled,
        isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
        isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props =>
      [isPinEnabled, isBiometricEnabled, isBiometricAvailable, status];
}
