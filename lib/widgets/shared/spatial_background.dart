import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/palette.dart';

class SpatialBackground extends StatefulWidget {
  const SpatialBackground({super.key});

  @override
  State<SpatialBackground> createState() => _SpatialBackgroundState();
}

class _SpatialBackgroundState extends State<SpatialBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Glows read well but heavy on light backgrounds; dim them in light mode.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowAlpha = isDark ? 0.15 : 0.08;
    final orbAlpha = isDark ? 0.15 : 0.06;

    return Container(
      color: context.palette.backgroundBase,
      child: Stack(
        children: [
          // Static background glow
          Positioned(
            left: MediaQuery.of(context).size.width * 0.15,
            top: MediaQuery.of(context).size.height * 0.5,
            child: _buildGlow(AppColors.accentHover.withValues(alpha: glowAlpha), 400),
          ),
          Positioned(
            right: MediaQuery.of(context).size.width * 0.15,
            top: MediaQuery.of(context).size.height * 0.3,
            child: _buildGlow(const Color(0xFF641496).withValues(alpha: glowAlpha), 400),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.5,
            top: MediaQuery.of(context).size.height * 0.8,
            child: _buildGlow(const Color(0xFF149696).withValues(alpha: glowAlpha * 0.7), 500),
          ),
          // Animated Orbs
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final val = _animation.value;
              return Stack(
                children: [
                  Positioned(
                    left: -100 + (val * 100),
                    top: -100 + (val * 100),
                    child: _buildOrb(
                      const Color(0xFF38BDF8).withValues(alpha: orbAlpha),
                    ),
                  ),
                  Positioned(
                    right: -100 + ((1 - val) * 100),
                    bottom: -100 + ((1 - val) * 100),
                    child: _buildOrb(
                      const Color(0xFFA855F7).withValues(alpha: orbAlpha),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  Widget _buildOrb(Color color) {
    // A soft radial gradient gives the orb glow on its own. We deliberately do
    // NOT wrap it in a BackdropFilter blur: a full-screen blur animating every
    // frame for 20s is a major GPU/battery cost for a purely decorative effect.
    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}
