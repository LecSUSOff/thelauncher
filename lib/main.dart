import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:palette_generator/palette_generator.dart';

void main() {
  runApp(const MyLauncherApp());
}


Future<Color> getIconColor(Uint8List iconBytes) async {
  final palette = await PaletteGenerator.fromImageProvider(
    MemoryImage(iconBytes),
    maximumColorCount: 4,
  );
  
  return palette.dominantColor?.color ?? Colors.grey.shade900;
}

class MyLauncherApp extends StatelessWidget {
  const MyLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LauncherHomeScreen(),
    );
  }
}

class LauncherHomeScreen extends StatelessWidget {
  const LauncherHomeScreen({super.key});

  Future<List<AppInfo>> _getApps() async {
    return await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<AppInfo>>(
          future: _getApps(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No apps found... weird'));
            }

            final apps = snapshot.data!;

            return PageView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                return GestureDetector( 
                  child: Stack( 
                    children: 
                    [
                      Positioned.fill(
                      child: FutureBuilder<Color>(
                        future: getIconColor(apps[index].icon!),
                        builder: (context, snapshot) {
                          // Use fallback/default color while it's still calculating
                          final color = snapshot.data ?? Colors.black;
                          return ColoredBox(color: color);
                        },
                      ),
                    ),

                      Center(
                        child: Image.memory(
                          apps[index].icon!,
                          width: 150,
                          height: 150,
                        ),
                      ),
                    ]
                  ),
                  onTap: () => InstalledApps.startApp(apps[index].packageName),
                );
              }
            );
          },
        ),
      ),
    );
  }
}