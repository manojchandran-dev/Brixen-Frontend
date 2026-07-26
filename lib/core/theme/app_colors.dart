import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Dark palette (true black) ───────────────────────────────────
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1C1C1C);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFF616161);
  static const Color border = Color(0xFF1F1F1F);
  static const Color borderSilver = Color(0xFF333333);

  // ── Light palette — silver · white · dark grey · black ────────
  static const Color lightBackground = Color(0xFFF0F0F0);      // near-white silver scaffold
  static const Color lightSurface = Color(0xFFFFFFFF);          // white cards — pop against bg
  static const Color lightSurfaceElevated = Color(0xFFE8E8E8);  // inputs/chips

  static const Color lightTextPrimary = Color(0xFF2A2A2A);      // dark grey — max contrast
  static const Color lightTextSecondary = Color(0xFF3D3D3D);    // dark grey
  static const Color lightTextHint = Color(0xFF808080);         // silver-grey hint
  static const Color lightBorder = Color(0xFFD0D0D0);           // silver border

  // ── Shared silver palette ─────────────────────────────────────
  static const Color silver = Color(0xFFC0C0C0);
  static const Color silverLight = Color(0xFFE8E8E8);
  static const Color silverDark = Color(0xFF808080);
  static const Color chrome = Color(0xFFD4D4D4);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color error   = Color(0xFFBE185D);
  static const Color success = Color(0xFF059669);

  // ── Premium jewel-tone accent palette ─────────────────────────
  static const Color accentIndigo  = Color(0xFF4361EE); // companies, primary
  static const Color accentEmerald = Color(0xFF059669); // active, present
  static const Color accentTeal    = Color(0xFF0D9488); // employees, info
  static const Color accentGold    = Color(0xFFB45309); // subscriptions, pending
  static const Color accentRose    = Color(0xFFBE185D); // inactive, absent, danger
  static const Color accentViolet  = Color(0xFF7C3AED); // users, enterprise
  static const Color accentSlate   = Color(0xFF64748B); // neutral, activity

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient silverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8E8E8),
      Color(0xFFB0B0B0),
      Color(0xFFD4D4D4),
      Color(0xFF909090),
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF121212), Color(0xFF000000), Color(0xFF0A0A0A)],
  );

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5F5F5), Color(0xFFF0F0F0), Color(0xFFEAEAEA)],
  );
}
