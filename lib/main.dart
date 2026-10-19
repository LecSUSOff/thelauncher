import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

void main() {
  runApp(const MyLauncherApp());
}

class MyLauncherApp extends StatelessWidget {
  const MyLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LauncherHomeScreen(),
    );
  }
}

class LauncherHomeScreen extends StatelessWidget {
  const LauncherHomeScreen({super.key});

  Future<List<AppInfo>> _getApps() async {
    // For a launcher, keep excludeSystemApps: false so Settings, Camera, Phone, etc. show up!
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

            return GridView.builder(
              padding: const EdgeInsets.all(16),
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
              },
            );
          },
        ),
      ),
    );
  }
}