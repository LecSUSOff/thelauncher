import 'dart:ui' as ui;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter/material.dart';
import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:async';
import 'helpers.dart';

class HomePage extends StatefulWidget {
  final List<AppInfo> pinnedApps;
  final ValueChanged<AppInfo> onTogglePin;
  final List<String> userWidgets;
  final ValueChanged<String> onAddWidget;
  final ValueChanged<String> onRemoveWidget;

  const HomePage({
    super.key,
    required this.pinnedApps,
    required this.onTogglePin,
    required this.userWidgets,
    required this.onAddWidget,
    required this.onRemoveWidget,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MediaInfo? mediaInfo;
  bool digitalClock = false;

  final PageController _pageController = PageController();

  static const Color holoCyan = Color(0xFF33B5E5);
  static const Color holoSurface = Color(0xCC181B20);

  @override
  void initState() {
    super.initState();
    _initMediaController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initMediaController() async {
    try {
      try {
        await FlutterMediaController.getCurrentMediaInfo();
      } catch (e) {
        await FlutterMediaController.requestPermissions();
      }
      final info = await FlutterMediaController.getCurrentMediaInfo();
      if (mounted) {
        setState(() {
          mediaInfo = info;
        });
      }
    } catch (e) {
      debugPrint("Media Controller Error: $e");
    }
  }

  Future<void> _refreshMedia() async {
    final info = await FlutterMediaController.getCurrentMediaInfo();
    if (mounted) {
      setState(() {
        mediaInfo = info;
      });
    }
  }

  // --- WIDGET MANAGEMENT ---

  void _showWriteHtmlDialog() {
    final TextEditingController htmlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Code Widget", style: TextStyle(color: holoCyan)),
        content: TextField(
          controller: htmlController,
          maxLines: 8,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: "<h1>Hello</h1>\n<p style='color:white'>Write HTML/CSS...</p>",
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: holoCyan),
            onPressed: () {
              if (htmlController.text.trim().isNotEmpty) {
                widget.onAddWidget(htmlController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showAddWidgetSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add Custom Widget", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.code_rounded, color: holoCyan),
              title: const Text("Write HTML Code", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showWriteHtmlDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveWidgetDialog(String htmlContent) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("Remove Widget?", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to delete this custom widget?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: holoCyan)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              widget.onRemoveWidget(htmlContent);
              Navigator.pop(context);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDockIcon(AppInfo app) {
    if (app.icon != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 3.5),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: Image.memory(
                app.icon!,
                width: 50,
                height: 50,
                color: Colors.black.withValues(alpha: 0.45),
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
          Image.memory(app.icon!, width: 50, height: 50),
        ],
      );
    } else {
      return const Icon(
        Icons.android_rounded,
        size: 50,
        color: holoCyan,
        shadows: [Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3.5))],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 26, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: holoSurface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: holoCyan.withValues(alpha: 0.22),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 2,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, holoCyan, Colors.transparent],
                              ),
                            ),
                          ),
                          Expanded(
                            child: PageView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              controller: _pageController,
                              children: [
                                // 1. CLOCK
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      digitalClock = !digitalClock;
                                    });
                                    HapticFeedback.selectionClick();
                                  },
                                  child: Column(
                                    children: [
                                      const Spacer(),
                                      AnimatedCrossFade(
                                        firstChild: const Center(child: DigitalClock()),
                                        secondChild: const Center(child: AnimatedAnalogClock()),
                                        crossFadeState: digitalClock ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                                        duration: const Duration(milliseconds: 300),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "Tap to change to ${digitalClock ? "analog" : "digital"} clock",
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),

                                // 2. CALENDAR
                                Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: TableCalendar(
                                      firstDay: DateTime.utc(2010, 10, 16),
                                      lastDay: DateTime.utc(2030, 3, 14),
                                      focusedDay: DateTime.now(),
                                      calendarStyle: CalendarStyle(
                                        defaultTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
                                        weekendTextStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                                        todayDecoration: BoxDecoration(
                                          color: holoCyan.withValues(alpha: 0.2),
                                          shape: BoxShape.rectangle,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: holoCyan, width: 1.2),
                                        ),
                                        selectedDecoration: BoxDecoration(
                                          color: holoCyan,
                                          shape: BoxShape.rectangle,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      headerStyle: const HeaderStyle(
                                        titleTextStyle: TextStyle(color: holoCyan, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.0),
                                        formatButtonVisible: false,
                                        leftChevronIcon: Icon(Icons.chevron_left_rounded, color: Colors.white70),
                                        rightChevronIcon: Icon(Icons.chevron_right_rounded, color: Colors.white70),
                                      ),
                                    ),
                                  ),
                                ),

                                // 3. MEDIA
                                Center(
                                  child: mediaInfo == null
                                      ? Text(
                                          "No media playing".toUpperCase(),
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w600),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: holoCyan.withValues(alpha: 0.3), width: 1),
                                                  boxShadow: [
                                                    BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 12, offset: const Offset(0, 4)),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(11),
                                                  child: mediaInfo!.thumbnailUrl != null && mediaInfo!.thumbnailUrl!.isNotEmpty
                                                      ? Image.network(
                                                          mediaInfo!.thumbnailUrl!,
                                                          width: 86,
                                                          height: 86,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => Container(
                                                            width: 86,
                                                            height: 86,
                                                            color: Colors.white.withValues(alpha: 0.05),
                                                            child: const Icon(Icons.music_note_rounded, size: 44, color: holoCyan),
                                                          ),
                                                        )
                                                      : Container(
                                                          width: 86,
                                                          height: 86,
                                                          color: Colors.white.withValues(alpha: 0.05),
                                                          child: const Icon(Icons.music_note_rounded, size: 44, color: holoCyan),
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(height: 14),
                                              Text(
                                                mediaInfo!.track,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: Colors.white, letterSpacing: 0.2),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                mediaInfo!.artist.toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: holoCyan),
                                              ),
                                              const SizedBox(height: 14),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  IconButton(
                                                    splashRadius: 24,
                                                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 30),
                                                    onPressed: () async {
                                                      HapticFeedback.lightImpact();
                                                      await FlutterMediaController.previousTrack();
                                                      await _refreshMedia();
                                                    },
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: holoCyan,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [BoxShadow(color: holoCyan.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1)],
                                                    ),
                                                    child: IconButton(
                                                      splashRadius: 28,
                                                      icon: Icon(
                                                        mediaInfo!.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                        color: const Color(0xFF121417),
                                                        size: 34,
                                                      ),
                                                      onPressed: () async {
                                                        HapticFeedback.mediumImpact();
                                                        await FlutterMediaController.togglePlayPause();
                                                        await _refreshMedia();
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  IconButton(
                                                    splashRadius: 24,
                                                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 30),
                                                    onPressed: () async {
                                                      HapticFeedback.lightImpact();
                                                      await FlutterMediaController.nextTrack();
                                                      await _refreshMedia();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                                
                                // 4. CUSTOM HTML WIDGETS
                                ...widget.userWidgets.map((htmlContent) {
                                  return GestureDetector(
                                    onLongPress: () => _showRemoveWidgetDialog(htmlContent),
                                    child: Center(
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: HtmlWidget(
                                            htmlContent,
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                                // 5. ADD WIDGET BUTTON
                                Center(
                                  child: GestureDetector(
                                    onTap: _showAddWidgetSheet,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(alpha: 0.05),
                                            border: Border.all(color: holoCyan.withValues(alpha: 0.5), width: 1.5),
                                          ),
                                          child: const Icon(Icons.add_rounded, size: 40, color: holoCyan),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          "Add Widget",
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SmoothPageIndicator(
                              controller: _pageController,
                              // 3 Defaults + N Custom Widgets + 1 Add Button
                              count: 4 + widget.userWidgets.length, 
                              effect: const ExpandingDotsEffect(
                                activeDotColor: holoCyan,
                                dotColor: Colors.white24,
                                dotHeight: 6,
                                dotWidth: 6,
                                expansionFactor: 3.2,
                                spacing: 6,
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

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      holoCyan.withValues(alpha: 0.1),
                      holoCyan.withValues(alpha: 1),
                      holoCyan.withValues(alpha: 0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(color: holoCyan.withValues(alpha: 0.3), blurRadius: 6, spreadRadius: 0.5),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.pinnedApps.map((app) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        InstalledApps.startApp(app.packageName);
                      },
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        showAppContextMenu(
                          context,
                          app: app,
                          isPinned: widget.pinnedApps.any((a) => a.packageName == app.packageName),
                          onTogglePin: widget.onTogglePin,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _buildDockIcon(app),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DigitalClock extends StatefulWidget {
  const DigitalClock({super.key});

  @override
  State<DigitalClock> createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  late Timer _timer;
  late String _currentTime;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateTime();
    });
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentTime,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 65,
        fontWeight: FontWeight.w400,
        letterSpacing: 2.0,
      ),
    );
  }
}