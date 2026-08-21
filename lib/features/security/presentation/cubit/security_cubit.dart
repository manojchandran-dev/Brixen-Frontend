import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/token_service.dart';
import '../../data/pin_remote_datasource.dart';
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

  /// Saves PIN locally first (lock screen works immediately), then syncs the
  /// hash to the server. Pure connectivity failures (no status code) are
  /// ignored so a network hiccup never blocks PIN setup — the sync is
  /// effectively best-effort in that case. A 400 (bad format or wrong
  /// `currentPin`) means the local PIN must not diverge from the server's,
  /// so it's reverted. A 401 (missing/invalid access token) is an unrelated
  /// auth problem — the PIN itself was never actually checked, so the local
  /// value is left alone; the caller is expected to treat it as session
  /// expiry. Either way the error is rethrown for the caller to show.
  Future<void> enablePin(String pin, {String? currentPin}) async {
    final previousPin = await _src.getPin();
    await _src.savePin(pin);
    emit(state.copyWith(isPinEnabled: true));
    try {
      await pinRemoteDatasource.savePin(pin: pin, currentPin: currentPin);
    } on ApiException catch (e) {
      if (e.statusCode == null) return; // offline/network — keep local change
      if (e.statusCode == 401) rethrow; // session problem, not a PIN rejection
      if (previousPin != null) {
        await _src.savePin(previousPin);
      } else {
        await _src.disablePin();
      }
      emit(state.copyWith(isPinEnabled: previousPin != null));
      rethrow;
    }
  }

  Future<void> disablePin() async {
    await _src.disablePin();
    emit(state.copyWith(isPinEnabled: false, isBiometricEnabled: false));
  }

  Future<void> setBiometric(bool value) async {
    await _src.setBiometricEnabled(value);
    emit(state.copyWith(isBiometricEnabled: value));
  }

  /// Verifies the PIN locally first (works offline). On success, also calls
  /// the server to rotate the refresh + access token pair (best-effort: network
  /// errors are silently swallowed). Only a genuine 401 (expired/revoked session)
  /// is re-thrown — the caller must then clear tokens and navigate to sign-in.
  Future<bool> verifyPin(String pin) async {
    final stored = await _src.getPin();
    if (stored != null) {
      if (stored != pin) return false;
      // Best-effort token rotation via server — all errors silently ignored.
      // The lock screen is an app lock, not a session validator. If the server
      // is unreachable or the PIN hash isn't synced yet, the user still gets in.
      // Session expiry is caught later when a real API call returns 401.
      try {
        final result = await pinRemoteDatasource.verifyPin(pin: pin);
        await TokenService.save(
          token: result['token']!,
          role: result['role'] ?? TokenService.role ?? 'employee',
          refreshToken: result['refreshToken'],
        );
      } catch (_) {}
      return true;
    }

    // No PIN cached on this device yet — e.g. a new device, or a reinstall,
    // where the account (per login's `hasPin: true`) already has one set on
    // the server. Validate against the server instead of failing outright,
    // and cache it locally on success so future unlocks work offline.
    try {
      final result = await pinRemoteDatasource.verifyPin(pin: pin);
      await TokenService.save(
        token: result['token']!,
        role: result['role'] ?? TokenService.role ?? 'employee',
        refreshToken: result['refreshToken'],
      );
      await _src.savePin(pin);
      emit(state.copyWith(isPinEnabled: true));
      return true;
    } catch (_) {
      return false;
    }
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
