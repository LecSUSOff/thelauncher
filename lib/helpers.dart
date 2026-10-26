import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'widgets/app_context_menu.dart';
import 'package:installed_apps/installed_apps.dart';

/// Legacy function - use AppContextMenu.show() instead
void showAppContextMenu(
  BuildContext context, {
  required AppInfo app,
  required bool isPinned,
  required bool isBlocked,
  required ValueChanged<AppInfo> onTogglePin,
  required ValueChanged<AppInfo> onToggleBlock,
}) {
  AppContextMenu.show(
    context,
    app: app,
    isPinned: isPinned,
    isBlocked: isBlocked,
    onTogglePin: onTogglePin,
    onToggleBlock: onToggleBlock,
  );
}

Widget htmlWidgetRenderer(String html) {
  WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadHtmlString(html);
  return WebViewWidget(controller: controller);
}

// Keep old name for compatibility
Widget HtmlWidgetRenderer(String html) => htmlWidgetRenderer(html);


Future<List<AppInfo>> getAppsInfoFromPackageNames(List<String> packageNames) async {
  List<AppInfo> appsList = [];

  final futures = packageNames.map((packageName) async {
    try {
      AppInfo? info = await InstalledApps.getAppInfo(packageName);
      return info;
    } catch (e) {
      return null;
    }
  });
  final results = await Future.wait(futures);

  for (var info in results) {
    if (info != null) {
      appsList.add(info);
    }
  }

  return appsList;
}