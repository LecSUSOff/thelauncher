import 'dart:ui' as math hide Stack;
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:device_wallpaper_flutter/device_wallpaper_flutter.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart' hide Stack;
import 'home.dart';
import 'applist.dart';
import 'youhub.dart';
import 'perch.dart';
import 'core/services/app_service.dart';
import 'core/constants.dart';
import 'package:system_theme/system_theme.dart';

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
  List<AppInfo> _blockedApps = [];
  List<AppInfo> _lockedApps = [];
  List<String> _userWidgets = [];
  List<AppInfo> _allApps = [];
  bool _isLoading = true;

  final glowColor = SystemTheme.accentColor.accent;

  final PageController _rootPageController = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();
    _getCurrentWallpaper();
    _initLauncher();

    homeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onHomePressed') {
        if (_rootPageController.hasClients && _rootPageController.page != 1) {
          _rootPageController.animateToPage(
            1,
            duration: AppDurations.medium,
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _rootPageController.dispose();
    super.dispose();
  }

  Future<void> _initLauncher() async {
    final allApps = await AppService.getInstalledApps();
    final savedPackages = await AppService.getPinnedPackages();
    final blockedPackages = await AppService.getBlockedPackages();
    final lockedPackages = await AppService.getLockedPackages();
    final savedWidgets = await AppService.getSavedWidgets();
    final blockedApps = await AppService.getAppsInfoFromPackageNames(
      blockedPackages,
    );
    final lockedApps = await AppService.getAppsInfoFromPackageNames(
      lockedPackages,
    );

    List<String> packagesToUse = savedPackages;
    if (packagesToUse.isEmpty) {
      packagesToUse = await getDefaultPackageNames();
    }

    final appMap = {for (final app in allApps) app.packageName: app};
    final pinned = packagesToUse
        .map((pkg) => appMap[pkg])
        .whereType<AppInfo>()
        .toList();

    if (mounted) {
      setState(() {
        _allApps = allApps;
        _pinnedApps = pinned;
        _blockedApps = blockedApps;
        _lockedApps = lockedApps;
        _userWidgets = savedWidgets;
        _isLoading = false;
      });
    }
  }

  void saveWidget(String widget) {
    setState(() {
      _userWidgets.add(widget);
    });
    AppService.saveWidgets(_userWidgets);
  }

  void removeWidget(String widget) {
    setState(() {
      _userWidgets.remove(widget);
    });
    AppService.saveWidgets(_userWidgets);
  }

  void togglePinApp(AppInfo app) {
    setState(() {
      if (_pinnedApps.any((a) => a.packageName == app.packageName)) {
        _pinnedApps.removeWhere((a) => a.packageName == app.packageName);
      } else {
        if (_pinnedApps.length < 5) _pinnedApps.add(app);
      }
    });
    AppService.savePinnedPackages(
      _pinnedApps.map((a) => a.packageName).toList(),
    );
  }

  void toggleBlockApp(AppInfo app) {
    setState(() {
      if (_blockedApps.any((a) => a.packageName == app.packageName)) {
        _blockedApps.removeWhere((a) => a.packageName == app.packageName);
      } else {
        _blockedApps.add(app);
      }
    });
    AppService.saveBlockedPackages(
      _blockedApps.map((a) => a.packageName).toList(),
    );
  }

  void toggleLockApp(AppInfo app) {
    setState(() {
      if (_lockedApps.any((a) => a.packageName == app.packageName)) {
        _lockedApps.removeWhere((a) => a.packageName == app.packageName);
      } else {
        _lockedApps.add(app);
      }
    });
    AppService.saveLockedPackages(
      _lockedApps.map((a) => a.packageName).toList(),
    );
  }

  Future<void> _getCurrentWallpaper() async {
    try {
      Uint8List? bytes = await DeviceWallpaperFlutter.getWallpaper();
      if (mounted) {
        setState(() {
          _wallpaperBytes = bytes;
        });
      }
    } catch (e) {
      // Silent fail to maintain same behavior
    }
  }

  double _launcherBlur = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return const PerchScreen();
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rootPageController,
                  builder: (context, child) {
                    final double page = _rootPageController.hasClients
                        ? (_rootPageController.page ?? 1.0)
                        : 1.0;
                    final double offset = (1.0 - page) * 35.0;

                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: Transform.scale(
                        scale: 1.15,
                        child: _wallpaperBytes != null
                            ? Image.memory(_wallpaperBytes!, fit: BoxFit.cover)
                            : const SizedBox.expand(),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 30, bottom: 65),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    glowColor.withAlpha(clampDouble(_launcherBlur/1.5, 0, 50).round()),
                    BlendMode.overlay
                  ),
                  child: ImageFiltered(
                    imageFilter: math.ImageFilter.blur(sigmaX: _launcherBlur, sigmaY: _launcherBlur),
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          _launcherBlur = _launcherBlur + (details.primaryDelta ?? 0) * 2.5;
                        });
                        if (details.primaryDelta! > 10) {
                          HapticFeedback.mediumImpact();
                          homeChannel.invokeMethod('openNotifications');
                        }
                      },
                      onVerticalDragEnd: (_) {
                        setState(() {
                          _launcherBlur = 0.0;
                        });
                      },
                      child: PageView(
                        controller: _rootPageController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const YouHub(),
                          HomePage(
                            pinnedApps: _pinnedApps,
                            blockedApps: _blockedApps,
                            lockedApps: _lockedApps,
                            onTogglePin: togglePinApp,
                            onToggleBlock: toggleBlockApp,
                            onToggleLock: toggleLockApp,
                            userWidgets: _userWidgets,
                            onAddWidget: saveWidget,
                            onRemoveWidget: removeWidget,
                          ),
                          AppList(
                            apps: _allApps,
                            pinnedApps: _pinnedApps,
                            blockedApps: _blockedApps,
                            lockedApps: _lockedApps,
                            onTogglePin: togglePinApp,
                            onToggleBlock: toggleBlockApp,
                            onToggleLock: toggleLockApp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
