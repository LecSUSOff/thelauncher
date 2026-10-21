import 'package:flutter/material.dart';
import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:device_wallpaper_flutter/device_wallpaper_flutter.dart';
import 'dart:ui' as ui;

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
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: 15,
                      sigmaY: 15,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white.withValues(
                        alpha: 0.75,
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
