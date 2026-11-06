import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../../core/constants.dart';
import 'icon_shadow_cache.dart';

class AppIcon extends StatelessWidget {
  final AppInfo app;
  final double size;

  const AppIcon({super.key, required this.app, this.size = 50});

  @override
  Widget build(BuildContext context) {
    if (app.icon == null) {
      return Icon(
        Icons.android_rounded,
        size: size,
        color: AppColors.holoCyan,
        shadows: const [
          Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3.5)),
        ],
      );
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -12,
          top: -12 + 3.5,
          width: size + 24,
          height: size + 24,
          child: FutureBuilder(
            key: ValueKey((
              app.icon!,
              size,
              MediaQuery.devicePixelRatioOf(context),
            )),
            future: IconShadowCache.get(
              app.icon!,
              size,
              MediaQuery.devicePixelRatioOf(context),
            ),
            builder: (context, snapshot) => snapshot.hasData
                ? Image.memory(snapshot.data!, fit: BoxFit.fill)
                : const SizedBox.shrink(),
          ),
        ),
        Image.memory(app.icon!, width: size, height: size),
      ],
    );
  }
}
