import 'package:flutter/material.dart';

/// Brixen's single-mode brand palette — four colours only:
/// Blue #356B86 (dominant), White #FFFFFF (surfaces), Green #80C080
/// (positive/accent), Black #0F0F0F (rare/structural). Every named
/// constant below resolves to one of these four (or a tint/shade of
/// blue), so the rest of the app never references raw hex values.
class AppColors {
  AppColors._();

  // ── The four brand colours ─────────────────────────────────────
  static const Color brand = Color(0xFF356B86);       // blue — 60%
  static const Color paper = Color(0xFFFFFFFF);        // white — 25%
  static const Color positive = Color(0xFF80C080);     // green — 10%
  static const Color ink = Color(0xFF0F0F0F);           // black — 5%

  // Blue tints/shades — still "blue", used for hierarchy within the
  // dominant colour rather than introducing a new hue.
  static const Color brandDeep = Color(0xFF264F63);
  static const Color brandLight = Color(0xFF6B9AB0);
  static const Color brandPale = Color(0xFFDCE8ED);

  // ── Backgrounds / surfaces ──────────────────────────────────────
  static const Color background = Color(0xFFF3F7F9);        // app scaffold — pale blue-tinted white
  static const Color surface = Color(0xFFFFFFFF);            // cards — pure white
  static const Color surfaceElevated = Color(0xFFE9F0F3);    // inputs/chips — pale blue-grey

  static const Color lightBackground = background;
  static const Color lightSurface = surface;
  static const Color lightSurfaceElevated = surfaceElevated;

  static const Color primary = brand;
  static const Color lightPrimary = brand;

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textHint = Color(0xFF7A7A7A);

  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color lightTextHint = textHint;

  // ── Borders ───────────────────────────────────────────────────
  static const Color border = Color(0xFFD5E1E6);
  static const Color borderSilver = border;
  static const Color lightBorder = border;

  // ── Legacy "silver" aliases — now resolve to blue ────────────────
  static const Color silver = brand;
  static const Color silverLight = brandLight;
  static const Color silverDark = brandDeep;
  static const Color chrome = brandPale;

  static const Color white = paper;
  static const Color black = ink;

  static const Color error = ink;      // no red in the palette — danger reads as black
  static const Color success = positive;

  // ── Legacy per-module accent aliases — collapsed onto the 4-colour set ──
  static const Color accentIndigo  = brand;       // companies
  static const Color accentEmerald = positive;    // active, present
  static const Color accentTeal    = brand;       // employees, info
  static const Color accentGold    = brandLight;  // subscriptions, pending
  static const Color accentRose    = ink;         // inactive, absent, danger
  static const Color accentViolet  = brandDeep;   // enterprise
  static const Color accentSlate   = brandLight;  // neutral, activity

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient silverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandLight, brand, brandDeep, brand],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7FAFB), background, Color(0xFFEDF3F5)],
  );

  static const LinearGradient lightBackgroundGradient = backgroundGradient;
}
