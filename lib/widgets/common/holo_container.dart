import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/constants.dart';

class HoloContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double sigmaX;
  final double sigmaY;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  const HoloContainer({
    super.key,
    required this.child,
    this.borderRadius = AppDimensions.borderRadiusMedium,
    this.sigmaX = 16,
    this.sigmaY = 16,
    this.borderColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.holoSurface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppColors.holoCyan.withValues(alpha: 0.22),
              width: AppDimensions.borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class HoloTopGlow extends StatelessWidget {
  const HoloTopGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.glowHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.holoCyan,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
