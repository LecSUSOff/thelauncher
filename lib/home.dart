import 'package:flutter/material.dart';
import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:device_wallpaper_flutter/device_wallpaper_flutter.dart';
import 'dart:ui' as ui;

class WallpaperViewer extends StatefulWidget {
  @override
  _WallpaperViewerState createState() => _WallpaperViewerState();
}

class _WallpaperViewerState extends State<WallpaperViewer> {
  Uint8List? _wallpaperBytes;

  @override
  void initState() {
    super.initState();
    _getCurrentWallpaper();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _wallpaperBytes != null
            ? Image.memory(_wallpaperBytes!)
            : CircularProgressIndicator(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<AppInfo> PinnedApps;
  const HomePage({super.key, required this.PinnedApps});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _getCurrentWallpaper();
  }

  Uint8List? _wallpaperBytes;

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: _wallpaperBytes != null
              ? Image.memory(_wallpaperBytes!, fit: BoxFit.cover,
              width: double.infinity,
    height: double.infinity,)
              : CircularProgressIndicator(),
        ),
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: 15,
                      sigmaY: 15,
                    ), // blurs the wallpaper behind it
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white.withValues(
                        alpha: 0.8,
                      ),
                      child: PageView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const Center(child: AnimatedAnalogClock()),
                
                          Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: TableCalendar(
                                firstDay: DateTime.utc(2010, 10, 16),
                                lastDay: DateTime.utc(2030, 3, 14),
                                focusedDay: DateTime.now(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.PinnedApps.map((app) {
                return GestureDetector(
                  onTap: () => InstalledApps.startApp(app.packageName),
                  child: Image.memory(app.icon!, width: 48, height: 48),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ],
    );
  }
}
