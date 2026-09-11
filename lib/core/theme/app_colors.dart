import 'package:flutter/material.dart';

/// Brixen's brand palette — four colours only: Blue #356B86 (dominant),
/// White #FFFFFF (surfaces), Green #80C080 (positive/accent), Black
/// #0F0F0F (rare/structural). The brand hues themselves stay fixed across
/// light and dark mode; the neutral "surface" and "foreground" roles
/// (background/surface/border/ink/text) flip so the whole app can run in
/// either theme. Call [AppColors.setBrightness] once per frame (done in
/// `main.dart`) before anything reads these.
class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.light;
  static bool get _isDark => _brightness == Brightness.dark;

  static void setBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get isDark => _isDark;

  // ── The four brand colours — fixed across themes ─────────────────
  static const Color brand = Color(0xFF356B86); // blue — 60%
  static const Color paper = Color(0xFFFFFFFF); // white — 25%
  static const Color positive = Color(0xFF80C080); // green — 10%

  // Blue tints/shades — still "blue", used for hierarchy within the
  // dominant colour rather than introducing a new hue.
  static const Color brandDeep = Color(0xFF264F63);
  static const Color brandLight = Color(0xFF6B9AB0);
  static const Color brandPale = Color(0xFFDCE8ED);

  static const Color primary = brand;
  static const Color lightPrimary = brand;

  // ── "ink" — the max-contrast neutral: black in light mode, near-white
  // in dark mode. Used for text/icon foreground and as the 5th rotation
  // accent. NOT used for shadow colours (see shadowDark/shadowLight).
  static const Color _lightInk = Color(0xFF0F0F0F);
  static const Color _darkInk = Color(0xFFF2F5F6);
  static Color get ink => _isDark ? _darkInk : _lightInk;

  // Fixed "black" brand swatch — used wherever black is one of a set of
  // rotating accent/fill colours (card accents, avatar badges, drawer icon
  // tiles) rather than foreground text. Those need a colour that stays a
  // solid, visible fill in both themes; `ink` inverting to near-white would
  // make that specific accent bucket vanish into a dark-mode card.
  static const Color brandBlack = _lightInk;

  // ── Backgrounds / surfaces ──────────────────────────────────────
  static const Color _lightBackground = Color(0xFFF3F7F9);
  static const Color _darkBackground = Color(0xFF10161A);
  static Color get background => _isDark ? _darkBackground : _lightBackground;

  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _darkSurface = Color(0xFF1B2328);
  static Color get surface => _isDark ? _darkSurface : _lightSurface;

  static const Color _lightSurfaceElevated = Color(0xFFE9F0F3);
  static const Color _darkSurfaceElevated = Color(0xFF242E33);
  static Color get surfaceElevated =>
      _isDark ? _darkSurfaceElevated : _lightSurfaceElevated;

  static const Color lightBackground = _lightBackground;
  static const Color lightSurface = _lightSurface;
  static const Color lightSurfaceElevated = _lightSurfaceElevated;

  static const Color darkBackground = _darkBackground;
  static const Color darkSurface = _darkSurface;
  static const Color darkSurfaceElevated = _darkSurfaceElevated;

  // ── Text ──────────────────────────────────────────────────────
  static Color get textPrimary => ink;
  static const Color _lightTextSecondary = Color(0xFF4A4A4A);
  static const Color _darkTextSecondary = Color(0xFFB8C2C6);
  static Color get textSecondary =>
      _isDark ? _darkTextSecondary : _lightTextSecondary;

  static const Color _lightTextHint = Color(0xFF7A7A7A);
  static const Color _darkTextHint = Color(0xFF8A9599);
  static Color get textHint => _isDark ? _darkTextHint : _lightTextHint;

  static const Color lightTextPrimary = _lightInk;
  static const Color lightTextSecondary = _lightTextSecondary;
  static const Color lightTextHint = _lightTextHint;

  // ── Borders ───────────────────────────────────────────────────
  static const Color _lightBorder = Color(0xFFD5E1E6);
  static const Color _darkBorder = Color(0xFF323E44);
  static Color get border => _isDark ? _darkBorder : _lightBorder;
  static Color get borderSilver => border;
  static const Color lightBorder = _lightBorder;

  // ── Fixed shadow neutrals — deliberately NOT theme-reactive. The
  // matte-3D dual-shadow idiom (dark bottom-right + light top-left) needs
  // a shadow that stays dark and a highlight that stays light in both
  // themes, independent of the ink/white foreground tokens above.
  static const Color shadowDark = Color(0xFF000000);
  static const Color shadowLight = Color(0xFFFFFFFF);

  // Fixed near-black fill for error/danger surfaces (e.g. error SnackBars)
  // that pair with white text by design — deliberately NOT theme-reactive,
  // since flipping it to near-white in dark mode would put white text on a
  // white background.
  static const Color dangerFill = _lightInk;

  // The matte-3D card idiom pairs a dark bottom-right shadow with a white
  // top-left highlight to fake a raised, lit-from-above surface. That
  // highlight only reads correctly against a light card — on a dark card
  // in dark mode it shows up as a stray white glow, so drop it entirely
  // there rather than trying to find a dark-mode equivalent tone.
  static Color highlightShadow(double alpha) =>
      _isDark ? Colors.transparent : Colors.white.withValues(alpha: alpha);

  // Icon/avatar badges rotate through the 5-colour accent set and render
  // as a `[base, base@75%]` gradient. The `brandBlack` bucket is a flat,
  // fixed near-black — fine on a light card, but on a dark-mode card it
  // reads as an inert black square. Swap that one bucket for a blue→green
  // brand gradient in dark mode instead; every other accent keeps its own
  // colour, just gradiented against itself as before.
  static List<Color> accentGradient(Color base) {
    if (_isDark && base == brandBlack) return [brand, positive];
    return [base, base.withValues(alpha: 0.75)];
  }

  // Dark mode drops every drop shadow app-wide rather than trying to find
  // dark-appropriate shadow tones — on a dark surface a drop shadow just
  // reads as a smudge, not depth. Wrap any `boxShadow: AppColors.shadows([...])` list with
  // this so it collapses to nothing once dark mode is on.
  static List<BoxShadow> shadows(List<BoxShadow> list) =>
      _isDark ? const [] : list;

  // ── Legacy "silver" aliases — now resolve to blue ────────────────
  static const Color silver = brand;
  static const Color silverLight = brandLight;
  static const Color silverDark = brandDeep;
  static const Color chrome = brandPale;

  static const Color white = paper;
  static Color get black => ink;

  static Color get error => ink; // no red in the palette — danger reads as ink
  static const Color success = positive;

  // ── List-card pale-tint blend ────────────────────────────────────
  // Every module rotates its cards through the same 5 colours (brand,
  // positive, brandDeep, brandLight, ink) and blends them into the
  // surface for a pale card background. Three of those five are shades of
  // blue, so a single uniform blend factor makes different categories
  // land on near-identical pale-blue cards. Varying the blend per colour
  // (darker for brandDeep, much paler for brandLight) keeps all five
  // buckets visually distinct even though the hue repeats.
  static double cardTintBlend(Color c) {
    if (c == brandDeep) return 0.5;
    if (c == brandLight) return 0.16;
    if (c == brandBlack) return 0.22;
    return 0.30; // brand, positive
  }

  // Same idea as [cardTintBlend], but for the "black" bucket in dark mode —
  // where the border/avatar already swap to a blue→green gradient via
  // [accentGradient] — the card's own background stayed a single flat
  // blended colour, reading as plain/no colour at all next to that
  // gradient edge. Blending both accentGradient stops into the surface
  // gives the background the same subtle two-tone wash instead.
  static List<Color> cardTintGradient(Color accent) {
    final blend = cardTintBlend(accent);
    final base = Color.lerp(surface, accent, blend)!;
    if (!(_isDark && accent == brandBlack)) return [base, base];
    return [
      Color.lerp(surface, brand, blend)!,
      Color.lerp(surface, positive, blend)!,
    ];
  }

  // ── Legacy per-module accent aliases — collapsed onto the 4-colour set ──
  static const Color accentIndigo = brand; // companies
  static const Color accentEmerald = positive; // active, present
  static const Color accentTeal = brand; // employees, info
  static const Color accentGold = brandLight; // subscriptions, pending
  static const Color accentRose = brandBlack; // inactive, absent, danger
  static const Color accentViolet = brandDeep; // enterprise
  static const Color accentSlate = brandLight; // neutral, activity

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient silverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandLight, brand, brandDeep, brand],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7FAFB), _lightBackground, Color(0xFFEDF3F5)],
  );

  static LinearGradient get backgroundGradient => _isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141B20), _darkBackground, Color(0xFF0C1114)],
        )
      : lightBackgroundGradient;
}
