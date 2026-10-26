import 'package:flutter/foundation.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';

class MediaService {
  static Future<void> ensurePermissions() async {
    try {
      await FlutterMediaController.getCurrentMediaInfo();
    } catch (e) {
      await FlutterMediaController.requestPermissions();
    }
  }

  static Future<MediaInfo?> getCurrentMediaInfo() async {
    try {
      await ensurePermissions();
      return await FlutterMediaController.getCurrentMediaInfo();
    } catch (e) {
      debugPrint("Media Controller Error: $e");
      return null;
    }
  }

  static Future<void> playPause() async {
    await FlutterMediaController.togglePlayPause();
  }

  static Future<void> nextTrack() async {
    await FlutterMediaController.nextTrack();
  }

  static Future<void> previousTrack() async {
    await FlutterMediaController.previousTrack();
  }
}
