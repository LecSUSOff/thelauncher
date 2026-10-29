import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// Frosted "holo" surface shared by every large panel in the launcher.
class HoloContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double sigmaX;
  final double sigmaY;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final Color? color;
  final List<BoxShadow>? boxShadow;

  const HoloContainer({
    super.key,
    required this.child,
    this.borderRadius = AppDimensions.borderRadiusMedium,
    this.sigmaX = 16,
    this.sigmaY = 16,
    this.borderColor,
    this.borderWidth = AppDimensions.borderWidth,
    this.padding,
    this.margin,
    this.height,
    this.color,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? AppColors.holoSurface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color:
                    borderColor ?? AppColors.holoCyan.withValues(alpha: 0.22),
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Signature 2px cyan rim light shown at the top of holo panels.
class HoloTopGlow extends StatelessWidget {
  final double height;
  final double opacity;
  final Color? color;

  const HoloTopGlow({
    super.key,
    this.height = AppDimensions.glowHeight,
    this.opacity = 1.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = (color ?? AppColors.holoCyan).withValues(alpha: opacity);

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, glowColor, Colors.transparent],
        ),
      ),
    );
  }
}
