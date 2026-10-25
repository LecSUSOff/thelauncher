import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:device_wallpaper_flutter/device_wallpaper_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'applist.dart';
import 'youhub.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MyLauncherApp());
}

const platform = MethodChannel('launcher/defaults');

Future<List<String>> getDefaultPackageNames() async {
  final Map<dynamic, dynamic> defaults = await platform.invokeMethod(
    'getDefaults',
  );

  return defaults.values.whereType<String>().toList();
}

class MyLauncherApp extends StatelessWidget {
  const MyLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LauncherHomeScreen(),
      theme: ThemeData.dark(),
    );
  }
}

class LauncherHomeScreen extends StatefulWidget {
  const LauncherHomeScreen({super.key});

  @override
  State<LauncherHomeScreen> createState() => _LauncherHomeScreenState();
}

class _LauncherHomeScreenState extends State<LauncherHomeScreen> {
  static const homeChannel = MethodChannel('launcher/home_intent');
  Uint8List? _wallpaperBytes;
  List<AppInfo> _pinnedApps = [];
  List<String> _userWidgets = [];
  final PageController _rootPageController = PageController(
      initialPage: 1,
    );

  @override
  void initState() {
    super.initState();
    _getCurrentWallpaper();

    homeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onHomePressed') {
        if (_rootPageController.hasClients && _rootPageController.page != 1) {
          _rootPageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  Future<({List<AppInfo> allApps, List<AppInfo> pinnedApps, List<String> savedWidgets})> _loadLauncherData() async {
    final allApps = await _getApps();
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedPackages = prefs.getStringList('pinned_apps');
    List<String>? savedWidgets = prefs.getStringList('saved_widgets');
    savedPackages ??= await getDefaultPackageNames();
    savedWidgets ??= [];
    final appMap = {for (final app in allApps) app.packageName: app};
    final pinned = savedPackages
        .map((pkg) => appMap[pkg])
        .whereType<AppInfo>()
        .toList();

    return (allApps: allApps, pinnedApps: pinned, savedWidgets: savedWidgets);
  }

  void saveWidget(String widget) {
    setState(() {
      _userWidgets.add(widget);
    });

    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList(
        'saved_widgets', 
        _userWidgets,
      );
    });
  }

  void removeWidget(String widget) {
    setState(() {
      _userWidgets.remove(widget);
    });

    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList(
        'saved_widgets', 
        _userWidgets,
      );
    });
  }

  void togglePinApp(AppInfo app) {
    setState(() {
      if (_pinnedApps.any((a) => a.packageName == app.packageName)) {
        _pinnedApps.removeWhere((a) => a.packageName == app.packageName);
      } else {
        if (_pinnedApps.length < 5) _pinnedApps.add(app);
      }
    });

    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList(
        'pinned_apps', 
        _pinnedApps.map((a) => a.packageName).toList(),
      );
    });
  }

  Future<void> _getCurrentWallpaper() async {
    try {
      Uint8List? bytes = await DeviceWallpaperFlutter.getWallpaper();
      setState(() {
        _wallpaperBytes = bytes;
      });
    } catch (e) {
      print("Failed to get wallpaper: $e");
    }
  }

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
      body: FutureBuilder(
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
          final userWidgets = snapshot.data!.savedWidgets;

          return Stack(
            children: [
              Center(
                child: _wallpaperBytes != null
                    ? Image.memory(
                        _wallpaperBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : CircularProgressIndicator(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 50, bottom: 45),
                child: PageView(
                  controller: _rootPageController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    YouHub(),
                    HomePage(
                      pinnedApps: pinnedApps,
                      onTogglePin: togglePinApp,
                      userWidgets: userWidgets,
                      onAddWidget: saveWidget,
                      onRemoveWidget: removeWidget,
                    ),
                    AppList(apps: allApps, pinnedApps: _pinnedApps, onTogglePin: togglePinApp,),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
