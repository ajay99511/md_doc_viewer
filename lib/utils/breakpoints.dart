import 'package:flutter/material.dart';

/// Responsive breakpoint thresholds.
abstract class Breakpoints {
  /// Mobile: single column, viewer opens fullscreen.
  static const mobile = 768.0;

  /// Tablet: two columns (sidebar + file list), viewer slides in.
  static const tablet = 1200.0;

  /// Desktop: three columns (sidebar + file list + viewer).
  static const desktop = double.infinity;

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tablet;
  }
}
