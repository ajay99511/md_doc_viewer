import 'package:flutter/material.dart';

/// Shared color constants for the dark theme.
abstract class AppColors {
  static const backgroundBase = Color(0xFF0A0E17);
  static const backgroundSurface = Color(0xFF0F1520);
  static const backgroundElevated = Color(0xFF151C2C);
  static const backgroundHover = Color(0xFF1A2332);
  static const backgroundActive = Color(0xFF1E3A5F);

  static const borderSubtle = Color(0xFF1E293B);
  static const borderDefault = Color(0xFF334155);

  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  static const accent = Color(0xFF3B82F6);
  static const accentHover = Color(0xFF2563EB);
  static const accentSoft = Color(0xFF1E3A5F);

  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  static const folderIcon = Color(0xFF3B82F6);
  static const fileIcon = Color(0xFF94A3B8);

  static const starActive = Color(0xFFFBBF24);
  static const starInactive = Color(0xFF475569);
}

/// Material color scheme for the dark theme.
final darkColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.accent,
  brightness: Brightness.dark,
  surface: AppColors.backgroundBase,
  primary: AppColors.accent,
  onPrimary: Colors.white,
  secondary: AppColors.accentHover,
  surfaceContainerHighest: AppColors.backgroundElevated,
);

/// Material color scheme for the light theme.
final lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF3B82F6),
  brightness: Brightness.light,
  surface: const Color(0xFFF8FAFC),
  primary: const Color(0xFF3B82F6),
  onPrimary: Colors.white,
  secondary: const Color(0xFF2563EB),
  surfaceContainerHighest: const Color(0xFFF1F5F9),
);
