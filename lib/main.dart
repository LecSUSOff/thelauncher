import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/services.dart';
import 'home.dart';
import 'applist.dart';

void main() {
  runApp(const MyLauncherApp());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

const platform = MethodChannel('launcher/defaults');

Future<List<String>> getDefaultPackageNames() async {
  final Map<dynamic, dynamic> defaults = await platform.invokeMethod('getDefaults');
  
  return defaults.values.whereType<String>().toList();
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

  Future<({List<AppInfo> allApps, List<AppInfo> pinnedApps})> _loadLauncherData() async {
    final allApps = await _getApps();
    final defaultPackages = await getDefaultPackageNames();

    final appMap = {for (final app in allApps) app.packageName: app};
    final pinned = defaultPackages
        .map((pkg) => appMap[pkg])
        .whereType<AppInfo>()
        .toList();

    return (allApps: allApps, pinnedApps: pinned);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: _loadLauncherData(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final allApps = snapshot.data!.allApps;
            final pinnedApps = snapshot.data!.pinnedApps;

            return PageView(
              children: [
                HomePage(PinnedApps: pinnedApps),
                AppList(apps: allApps),
              ] 
            );
          },
        ),
      ),
    );
  }
}