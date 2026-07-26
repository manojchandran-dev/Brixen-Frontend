import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import '../../data/security_local_source.dart';
import 'security_state.dart';

// Global singleton — same pattern as themeCubit
final securityCubit = SecurityCubit();

class SecurityCubit extends Cubit<SecurityState> {
  final _src = SecurityLocalSource();
  final _localAuth = LocalAuthentication();

  SecurityCubit() : super(const SecurityState());

  Future<void> load() async {
    emit(state.copyWith(status: SecurityStatus.loading));
    final pinEnabled = await _src.isPinEnabled();
    final bioEnabled = await _src.isBiometricEnabled();
    bool bioAvailable = false;
    try {
      bioAvailable = await _localAuth.canCheckBiometrics;
    } catch (_) {}
    emit(state.copyWith(
      isPinEnabled: pinEnabled,
      isBiometricEnabled: bioEnabled,
      isBiometricAvailable: bioAvailable,
      status: SecurityStatus.ready,
    ));
  }

  Future<void> enablePin(String pin) async {
    await _src.savePin(pin);
    emit(state.copyWith(isPinEnabled: true));
  }

  Future<void> disablePin() async {
    await _src.disablePin();
    emit(state.copyWith(isPinEnabled: false, isBiometricEnabled: false));
  }

  Future<void> setBiometric(bool value) async {
    await _src.setBiometricEnabled(value);
    emit(state.copyWith(isBiometricEnabled: value));
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _src.getPin();
    return stored != null && stored == pin;
  }

  Future<bool> isLockActive() => _src.isPinEnabled();

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Verify your identity to access Brixen',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
