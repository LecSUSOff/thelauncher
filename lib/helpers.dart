import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'widgets/app_context_menu.dart';

/// Legacy function - use AppContextMenu.show() instead
void showAppContextMenu(
  BuildContext context, {
  required AppInfo app,
  required bool isPinned,
  required ValueChanged<AppInfo> onTogglePin,
}) {
  AppContextMenu.show(
    context,
    app: app,
    isPinned: isPinned,
    onTogglePin: onTogglePin,
  );
}

Widget HtmlWidgetRenderer(String html) {
  WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadHtmlString(html);
  return WebViewWidget(controller: controller);
}