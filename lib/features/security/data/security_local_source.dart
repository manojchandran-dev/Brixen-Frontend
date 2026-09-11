import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';

class SecurityLocalSource {
  static const _pinKey        = StorageKeys.securityPin;
  static const _pinEnabledKey = StorageKeys.securityPinEnabled;
  static const _bioEnabledKey = StorageKeys.securityBioEnabled;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> savePin(String pin) async {
    final p = await _prefs;
    await p.setString(_pinKey, pin);
    await p.setBool(_pinEnabledKey, true);
  }

  Future<String?> getPin() async => (await _prefs).getString(_pinKey);

  Future<void> setPinEnabled(bool value) async =>
      (await _prefs).setBool(_pinEnabledKey, value);

  Future<bool> isPinEnabled() async =>
      (await _prefs).getBool(_pinEnabledKey) ?? false;

  Future<void> disablePin() async {
    final p = await _prefs;
    await p.remove(_pinKey);
    await p.setBool(_pinEnabledKey, false);
    await p.setBool(_bioEnabledKey, false);
  }

  Future<bool> isBiometricEnabled() async =>
      (await _prefs).getBool(_bioEnabledKey) ?? false;

  Future<void> setBiometricEnabled(bool value) async =>
      (await _prefs).setBool(_bioEnabledKey, value);
}
