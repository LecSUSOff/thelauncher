import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:system_theme/system_theme.dart';

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
    final glowColor = color ?? SystemTheme.accentColor.accent;

    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            glowColor.withValues(alpha: 0),
            glowColor.withValues(alpha: opacity),
            glowColor.withValues(alpha: 0),
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
