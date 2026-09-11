import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

// Global singleton — safe to access from anywhere without context
final themeCubit = ThemeCubit();

class ThemeCubit extends Cubit<ThemeMode> {
  static const _kDarkMode = StorageKeys.darkModeEnabled;

  // User-toggleable light/dark, set from the "More" page. Defaults to light.
  ThemeCubit() : super(ThemeMode.light);

  /// Call once in main() before runApp — loads the saved preference from disk.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kDarkMode) == true) emit(ThemeMode.dark);
  }

  void toggle() => setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  void setMode(ThemeMode mode) {
    emit(mode);
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(_kDarkMode, mode == ThemeMode.dark));
  }

  bool get isDark => state == ThemeMode.dark;
}
