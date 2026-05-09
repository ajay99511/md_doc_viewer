import 'package:flutter/material.dart';
import 'dart:ui';
import '../../utils/constants.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool withGlow;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24.0,
    this.withGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
          if (withGlow)
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: -5,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface, // usually white/5 or black/20
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppColors.borderSubtle, // usually white/20
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
