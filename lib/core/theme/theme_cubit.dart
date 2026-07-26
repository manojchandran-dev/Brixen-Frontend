import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Global singleton — safe to access from anywhere without context
final themeCubit = ThemeCubit();

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark);

  void toggle() => emit(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );

  void setMode(ThemeMode mode) => emit(mode);

  bool get isDark => state == ThemeMode.dark;
}
