import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../core/services/app_service.dart';
import '../core/constants.dart';

class AppContextMenu {
  static void show(
    BuildContext context, {
    required AppInfo app,
    required bool isPinned,
    required ValueChanged<AppInfo> onTogglePin,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: Colors.white,
                ),
                title: Text(
                  isPinned ? 'Unpin from Dock' : 'Pin to Dock',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  onTogglePin(app);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text('See app settings', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(modalContext);
                  AppService.openAppSettings(app.packageName);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
