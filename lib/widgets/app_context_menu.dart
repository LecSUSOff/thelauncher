import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../core/services/app_service.dart';
import 'common/holo_container.dart';
import 'common/glow_divider.dart';
import 'package:biometric_authorization/biometric_authorization.dart';
import 'package:biometric_authorization/biometric_type.dart';

class AppContextMenu {
  static void show(
    BuildContext context, {
    required AppInfo app,
    required bool isPinned,
    required bool isBlocked,
    required bool isLocked,
    required ValueChanged<AppInfo> onTogglePin,
    required ValueChanged<AppInfo> onToggleBlock,
    required ValueChanged<AppInfo> onToggleLock,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return HoloContainer(
          child: Padding(
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
                    isPinned ? 'Unpin from the dock' : 'Pin to  the dock',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(modalContext);
                    onTogglePin(app);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.white),
                  title: Text('About ${app.name}', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(modalContext);
                    AppService.openAppSettings(app.packageName);
                  },
                ),
                ListTile(
                  leading: Icon(
                    isBlocked ? Icons.lock_open_outlined : Icons.lock_outlined,
                  ),
                  title: Text(
                    "Mark ${app.name} as ${isBlocked ? 'not' : ''} distractive",
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(modalContext);
                    onToggleBlock(app);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.fingerprint,
                  ),
                  title: Text(
                    "${isLocked ? 'Unlock' : 'Lock'} ${app.name}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    final biometricAuth = BiometricAuthorization();
                    bool authenticated = await biometricAuth.authenticate(
                      reason: 'Verify your identity',
                      title: 'This setting requires your verification',
                      confirmText: 'Proceed',
                      useCustomUI: true,
                    );

                    if (!authenticated) return;
                    Navigator.pop(modalContext);
                    onToggleLock(app);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
