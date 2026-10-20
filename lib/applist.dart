import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class AppList extends StatelessWidget {
  final List<AppInfo> apps;

  const AppList({super.key, required this.apps});

  @override
  Widget build(BuildContext context) {
  return GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      mainAxisSpacing: 20,
      crossAxisSpacing: 10,
      childAspectRatio: 0.8,
    ),
    itemCount: apps.length,
    itemBuilder: (context, index) {
      final app = apps[index];

      return GestureDetector(
        onTap: () => InstalledApps.startApp(app.packageName),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (app.icon != null)
              Image.memory(
                app.icon!,
                width: 50,
                height: 50,
              )
            else
              const Icon(Icons.android, size: 50),
            const SizedBox(height: 8),
            Text(
              app.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  );
}
}