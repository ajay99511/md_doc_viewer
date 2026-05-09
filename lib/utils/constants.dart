import 'package:flutter/material.dart';

/// Shared color constants for the dark theme.
abstract class AppColors {
  static const backgroundBase = Color(0xFF030712); // Deep space background
  static const backgroundSurface = Color(0x0CFFFFFF); // Glass panel: white/5
  static const backgroundElevated = Color(0x19FFFFFF); // Glass hover: white/10
  static const backgroundHover = Color(0x19FFFFFF);
  static const backgroundActive = Color(0x193B82F6); // bg-blue-500/10

  static const borderSubtle = Color(0x33FFFFFF); // border-white/20
  static const borderDefault = Color(0x4DFFFFFF);

  static const textPrimary = Color(0xFFF3F4F6); // Gray 100
  static const textSecondary = Color(0xFFD1D5DB); // Gray 300
  static const textMuted = Color(0xFF6B7280); // Gray 500

  static const accent = Color(0xFF22D3EE); // Cyan 400
  static const accentHover = Color(0xFF38BDF8); // Blue 400
  static const accentSoft = Color(0x8022D3EE); // Cyan 400 with opacity

  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  static const folderIcon = Color(0xFF3B82F6); // Blue 500
  static const fileIcon = Color(0xFF9CA3AF); // Gray 400

  static const starActive = Color(0xFFFBBF24);
  static const starInactive = Color(0xFF4B5563);
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
