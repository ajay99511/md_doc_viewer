import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Responsive layout breakpoints and helpers.
///
/// Layout modes:
/// - **compact** (< 600px): Mobile — single panel, drawer sidebar, bottom sheet viewer
/// - **medium** (600-1024px): Tablet — 2 panels, slide transitions
/// - **expanded** (> 1024px): Desktop — 3 panels with optional splitters
abstract class AppBreakpoints {
  static const compactMaxWidth = 600.0;
  static const mediumMaxWidth = 1024.0;

  static LayoutMode getMode(double width) {
    if (width < compactMaxWidth) return LayoutMode.compact;
    if (width < mediumMaxWidth) return LayoutMode.medium;
    return LayoutMode.expanded;
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactMaxWidth;

  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= compactMaxWidth && w < mediumMaxWidth;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mediumMaxWidth;
}

enum LayoutMode { compact, medium, expanded }

/// Platform-aware helper.
abstract class AppPlatform {
  static bool get isDesktop => [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      ].contains(defaultTargetPlatform);

  static bool get isMobile => [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform);

  static bool get hasMouse => isDesktop;
}
