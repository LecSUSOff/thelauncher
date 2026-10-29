import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// Horizontal cyan gradient divider used between holo sections.
class GlowDivider extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final double height;
  final Color? color;
  final double opacity;
  final bool glow;
  final double glowBlurRadius;
  final double glowSpreadRadius;

  const GlowDivider({
    super.key,
    this.margin,
    this.height = 1,
    this.color,
    this.opacity = 0.25,
    this.glow = false,
    this.glowBlurRadius = 6,
    this.glowSpreadRadius = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = color ?? AppColors.holoCyan;

    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            glowColor.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.3),
                  blurRadius: glowBlurRadius,
                  spreadRadius: glowSpreadRadius,
                ),
              ]
            : null,
      ),
    );
  }
}
