import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Opening or leaving a screen shows it straight away: no slide or fade.
class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

final _instantPages = PageTransitionsTheme(
  builders: {
    for (final p in TargetPlatform.values)
      p: const _InstantPageTransitionsBuilder(),
  },
);

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    fontFamily: 'Inter',
    // Screens change in place, with no slide, on every platform.
    pageTransitionsTheme: _instantPages,
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.silverLight,
      onPrimary: AppColors.darkBackground,
      secondary: AppColors.positive,
      onSecondary: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      onSurface: Color(0xFFF2F5F6),
      onSurfaceVariant: Color(0xFFB8C2C6),
      surfaceContainerHighest: AppColors.darkSurfaceElevated,
      error: Color(0xFFF2F5F6),
    ),
    textTheme: const TextTheme(),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceElevated,
      hintStyle: const TextStyle(color: Color(0xFF8A9599), fontSize: 14),
      labelStyle: const TextStyle(color: Color(0xFFB8C2C6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF323E44)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.silverLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF2F5F6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF2F5F6), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dividerColor: const Color(0xFF323E44),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceElevated,
      contentTextStyle: TextStyle(color: Color(0xFFF2F5F6)),
    ),
  );

  static ThemeData get light => ThemeData(
    fontFamily: 'Inter',
    // Screens change in place, with no slide, on every platform.
    pageTransitionsTheme: _instantPages,
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary, // blue — elite CTA colour
      onPrimary: AppColors.white,
      secondary: AppColors.positive,
      onSecondary: AppColors.lightTextPrimary,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      surfaceContainerHighest: AppColors.lightSurfaceElevated,
      error: AppColors.lightTextPrimary,
    ),
    textTheme: const TextTheme(),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      hintStyle: const TextStyle(color: AppColors.lightTextHint, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightTextPrimary),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.lightTextPrimary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dividerColor: AppColors.lightBorder,
    // Dark bar, light text. Error snack bars pass their own near-black
    // background (AppColors.dangerFill), so the text must be light here or
    // their message is black on black.
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.lightTextPrimary,
      contentTextStyle: TextStyle(color: Color(0xFFF2F5F6)),
      actionTextColor: AppColors.positive,
    ),
  );
}
