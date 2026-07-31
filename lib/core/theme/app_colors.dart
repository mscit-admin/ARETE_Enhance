import 'package:flutter/material.dart';

/// Brand palette for ARETE.
///
/// Ember (energetic action) is the primary accent; Teal is the secondary /
/// success accent; Ink is the deep near-black used for headers and CTAs.
/// These mirror the approved design proposal.
class AppColors {
  AppColors._();

  // Brand accents (theme-independent)
  static const Color ember = Color(0xFFEF5A2A);
  static const Color emberDark = Color(0xFFB8340F);
  static const Color teal = Color(0xFF10A596);
  static const Color gold = Color(0xFFD9A441);
  static const Color slate = Color(0xFF33404F);

  // Semantic
  static const Color success = teal;
  static const Color warning = gold;
  static const Color danger = Color(0xFFE0483C);

  // ---- Light theme tokens ----
  static const _lightBg = Color(0xFFF4F2EE);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceAlt = Color(0xFFF4F2EE);
  static const _lightLine = Color(0xFFDCD8D0);
  static const _lightText = Color(0xFF1A1F26);
  static const _lightMuted = Color(0xFF6B7480);
  static const _lightInk = Color(0xFF12161B);
  static const _lightEmberSoft = Color(0xFFFBE3D8);
  static const _lightTealSoft = Color(0xFFD5EFEC);

  // ---- Dark theme tokens ----
  static const _darkBg = Color(0xFF0E1216);
  static const _darkSurface = Color(0xFF161B21);
  static const _darkSurfaceAlt = Color(0xFF1B2129);
  static const _darkLine = Color(0xFF262D36);
  static const _darkText = Color(0xFFE7E9EC);
  static const _darkMuted = Color(0xFF8A94A1);
  static const _darkInk = Color(0xFF05070A);
  static const _darkEmberSoft = Color(0xFF2A1913);
  static const _darkTealSoft = Color(0xFF10231F);

  static AppPalette light = const AppPalette(
    background: _lightBg,
    surface: _lightSurface,
    surfaceAlt: _lightSurfaceAlt,
    line: _lightLine,
    text: _lightText,
    muted: _lightMuted,
    ink: _lightInk,
    emberSoft: _lightEmberSoft,
    tealSoft: _lightTealSoft,
    brightness: Brightness.light,
  );

  static AppPalette dark = const AppPalette(
    background: _darkBg,
    surface: _darkSurface,
    surfaceAlt: _darkSurfaceAlt,
    line: _darkLine,
    text: _darkText,
    muted: _darkMuted,
    ink: _darkInk,
    emberSoft: _darkEmberSoft,
    tealSoft: _darkTealSoft,
    brightness: Brightness.dark,
  );
}

/// A resolved set of surface/text tokens for the active theme.
/// Access via `context.palette` (see AppTheme extension).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.line,
    required this.text,
    required this.muted,
    required this.ink,
    required this.emberSoft,
    required this.tealSoft,
    required this.brightness,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color line;
  final Color text;
  final Color muted;
  final Color ink;
  final Color emberSoft;
  final Color tealSoft;
  final Brightness brightness;

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? line,
    Color? text,
    Color? muted,
    Color? ink,
    Color? emberSoft,
    Color? tealSoft,
    Brightness? brightness,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      line: line ?? this.line,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      ink: ink ?? this.ink,
      emberSoft: emberSoft ?? this.emberSoft,
      tealSoft: tealSoft ?? this.tealSoft,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      line: Color.lerp(line, other.line, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      emberSoft: Color.lerp(emberSoft, other.emberSoft, t)!,
      tealSoft: Color.lerp(tealSoft, other.tealSoft, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}
