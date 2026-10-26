import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppService {
  static Future<List<AppInfo>> getInstalledApps() async {
    return await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );
  }

  static Future<void> launchApp(String packageName) async {
    await InstalledApps.startApp(packageName);
  }

  static Future<void> openAppSettings(String packageName) async {
    await InstalledApps.openSettings(packageName);
  }

  static Future<List<String>> getPinnedPackages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('pinned_apps') ?? [];
  }

  static Future<void> savePinnedPackages(List<String> packages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pinned_apps', packages);
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
