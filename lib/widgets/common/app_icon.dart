import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../../core/constants.dart';

class AppIcon extends StatelessWidget {
  final AppInfo app;
  final double size;

  const AppIcon({
    super.key,
    required this.app,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (app.icon == null) {
      return Icon(
        Icons.android_rounded,
        size: size,
        color: AppColors.holoCyan,
        shadows: const [
          Shadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 3.5),
          ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, 3.5),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
            child: Image.memory(
              app.icon!,
              width: size,
              height: size,
              color: Colors.black.withValues(alpha: 0.45),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
        Image.memory(
          app.icon!,
          width: size,
          height: size,
        ),
      ],
    );
  }
}
