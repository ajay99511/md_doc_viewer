import 'package:flutter/material.dart';

/// Theme-aware structural colors (backgrounds, text, borders).
///
/// Accent and semantic colors (accent, success, warning, error, star, file /
/// folder icons) are intentionally NOT here — they read well on both light and
/// dark and stay as the shared constants in `AppColors`. Only the roles that
/// must flip between light and dark live in this palette so the app has a real,
/// readable light theme.
///
/// Field names mirror `AppColors` so call sites read naturally
/// (`context.palette.textPrimary`).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color backgroundBase;
  final Color backgroundSurface;
  final Color backgroundElevated;
  final Color backgroundHover;
  final Color backgroundActive;
  final Color borderSubtle;
  final Color borderDefault;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const AppPalette({
    required this.backgroundBase,
    required this.backgroundSurface,
    required this.backgroundElevated,
    required this.backgroundHover,
    required this.backgroundActive,
    required this.borderSubtle,
    required this.borderDefault,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  /// Dark palette — matches the original "spatial" dark design exactly.
  static const dark = AppPalette(
    backgroundBase: Color(0xFF030712),
    backgroundSurface: Color(0x0CFFFFFF),
    backgroundElevated: Color(0x19FFFFFF),
    backgroundHover: Color(0x19FFFFFF),
    backgroundActive: Color(0x193B82F6),
    borderSubtle: Color(0x33FFFFFF),
    borderDefault: Color(0x4DFFFFFF),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFFD1D5DB),
    textMuted: Color(0xFF6B7280),
  );

  /// Light palette — readable counterpart for light mode.
  static const light = AppPalette(
    backgroundBase: Color(0xFFF8FAFC),
    backgroundSurface: Color(0xCCFFFFFF),
    backgroundElevated: Color(0xFFFFFFFF),
    backgroundHover: Color(0x0F000000),
    backgroundActive: Color(0x143B82F6),
    borderSubtle: Color(0x1F000000),
    borderDefault: Color(0x33000000),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
  );

  @override
  AppPalette copyWith({
    Color? backgroundBase,
    Color? backgroundSurface,
    Color? backgroundElevated,
    Color? backgroundHover,
    Color? backgroundActive,
    Color? borderSubtle,
    Color? borderDefault,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return AppPalette(
      backgroundBase: backgroundBase ?? this.backgroundBase,
      backgroundSurface: backgroundSurface ?? this.backgroundSurface,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      backgroundHover: backgroundHover ?? this.backgroundHover,
      backgroundActive: backgroundActive ?? this.backgroundActive,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderDefault: borderDefault ?? this.borderDefault,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      backgroundBase: Color.lerp(backgroundBase, other.backgroundBase, t)!,
      backgroundSurface: Color.lerp(backgroundSurface, other.backgroundSurface, t)!,
      backgroundElevated: Color.lerp(backgroundElevated, other.backgroundElevated, t)!,
      backgroundHover: Color.lerp(backgroundHover, other.backgroundHover, t)!,
      backgroundActive: Color.lerp(backgroundActive, other.backgroundActive, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

/// Convenient access: `context.palette.textPrimary`.
extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
