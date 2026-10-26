import 'package:flutter/material.dart';

/// Core design constants used throughout the app
class AppColors {
  static const Color holoCyan = Color(0xFF33B5E5);
  static const Color holoSurface = Color(0xCC181B20);
  static const Color holoSurfaceLight = Color(0xCC121417);
}

/// Common UI constants
class AppDimensions {
  static const double borderRadiusLarge = 28.0;
  static const double borderRadiusMedium = 22.0;
  static const double borderRadiusSmall = 12.0;
  static const double borderWidth = 1.0;
  static const double glowHeight = 2.0;
}

/// Animation durations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 400);
}
