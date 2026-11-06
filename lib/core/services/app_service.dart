import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thelauncher/widgets/pause.dart';
import 'package:biometric_authorization/biometric_authorization.dart';
import 'package:biometric_authorization/biometric_type.dart';

class AppService {
  static Future<List<AppInfo>> getInstalledApps() async {
    return await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );
  }

  static Future<List<AppInfo>> getAppsInfoFromPackageNames(
    List<String> packageNames,
  ) async {
    final results = await Future.wait(
      packageNames.map((packageName) async {
        try {
          return await InstalledApps.getAppInfo(packageName);
        } catch (_) {
          return null;
        }
      }),
    );

    return results.whereType<AppInfo>().toList();
  }

  static Future<void> launchApp(
    BuildContext context,
    String packageName,
  ) async {
    final biometricAuth = BiometricAuthorization();

    bool isAvailable = await biometricAuth.isBiometricAvailable();

    bool isEnrolled = await biometricAuth.isBiometricEnrolled();

    List<BiometricType> types = await biometricAuth.getAvailableBiometricTypes();

    if (await isAppBlocked(packageName)) {
      if (!context.mounted) return;

      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, _, _) => PauseScreen(packageName: packageName),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
      return;
    }

    if (await isAppLocked(packageName)) {
      bool authenticated = await biometricAuth.authenticate(
        reason: 'The app is locked',
        title: 'Please authenticate to access the app',
        confirmText: 'Open',
        useCustomUI: true,
      );

      if (!authenticated) return;
    }

    InstalledApps.startApp(packageName);
  }

  static Future<void> openAppSettings(String packageName) async {
    InstalledApps.openSettings(packageName);
  }

  static Future<List<String>> getPinnedPackages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('pinned_apps') ?? [];
  }

  static Future<void> savePinnedPackages(List<String> packages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pinned_apps', packages);
  }

  static Future<List<String>> getBlockedPackages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('blocked_apps') ?? [];
  }

  static Future<List<String>> getLockedPackages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('locked_apps') ?? [];
  }

  static Future<bool> isAppBlocked(String packageName) async =>
      (await getBlockedPackages()).contains(packageName);

  static Future<bool> isAppLocked(String packageName) async =>
      (await getLockedPackages()).contains(packageName);

  static Future<void> saveBlockedPackages(List<String> packages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_apps', packages);
  }

  static Future<void> saveLockedPackages(List<String> packages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('locked_apps', packages);
  }

  static Future<List<String>> getSavedWidgets() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('saved_widgets') ?? [];
  }

  static Future<void> saveWidgets(List<String> widgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_widgets', widgets);
  }

  static Future<String> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('youhub_notes') ?? '';
  }

  static Future<void> saveNotes(String notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('youhub_notes', notes);
  }
}
