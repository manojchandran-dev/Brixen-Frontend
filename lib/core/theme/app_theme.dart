import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    fontFamily: 'Inter',
    // Back/swipe shows the page underneath as you drag: Android's
    // predictive back (needs enableOnBackInvokedCallback in the
    // manifest) and the iOS edge swipe.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
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
    // Back/swipe shows the page underneath as you drag: Android's
    // predictive back (needs enableOnBackInvokedCallback in the
    // manifest) and the iOS edge swipe.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
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
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.lightSurface,
      contentTextStyle: TextStyle(color: AppColors.lightTextPrimary),
    ),
  );
}
