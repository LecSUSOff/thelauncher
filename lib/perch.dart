import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:intl/intl.dart';
import 'core/constants.dart';
import 'core/services/weather_service.dart';
import 'core/services/calendar_service.dart';
import 'core/services/media_service.dart';
import 'widgets/common/holo_container.dart';
import 'widgets/digital_clock.dart';

class PerchScreen extends StatefulWidget {
  const PerchScreen({super.key});

  @override
  State<PerchScreen> createState() => _PerchScreenState();
}

class _PerchScreenState extends State<PerchScreen> {
  // Using AppColors constants

  // Clock state (from HomePage)
  bool digitalClock = false;

  // Media state (from HomePage)
  MediaInfo? mediaInfo;
  Timer? _mediaPollTimer;

  // YouHub context states
  Future<WeatherData?>? _weatherFuture;
  Future<List<Event>>? _eventsFuture;

  final PageController _contextPageController = PageController();

  @override
  void initState() {
    super.initState();
    // 1. Hide status bar and gesture navigation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 2. Load Context data
    _initMediaController();
    _weatherFuture = fetchCurrentWeather();
    _eventsFuture = _fetchUpcomingEvents();

    // Poll media info periodically while resting on Perch
    _mediaPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshMedia();
    });
  }

  @override
  void dispose() {
    _mediaPollTimer?.cancel();
    _contextPageController.dispose();
    // Restore edge-to-edge system UI when leaving Perch
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // --- MEDIA CONTROLLER (from HomePage) ---

  Future<void> _initMediaController() async {
    final info = await MediaService.getCurrentMediaInfo();
    if (mounted) setState(() => mediaInfo = info);
  }

  Future<void> _refreshMedia() async {
    final info = await MediaService.getCurrentMediaInfo();
    if (mounted) setState(() => mediaInfo = info);
  }

  // --- WEATHER & CALENDAR (from YouHub) ---

  Future<WeatherData?> fetchCurrentWeather() async {
    return WeatherService.fetchCurrentWeather(
      timeout: const Duration(seconds: 5),
    );
  }

  Future<List<Event>> _fetchUpcomingEvents() async {
    return CalendarService.fetchUpcomingEvents(daysAhead: 2, limit: 2);
  }

  String _getWeatherCondition(int code) {
    return WeatherService.getWeatherCondition(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== LEFT PANE: CLOCK (60%) ====================
              Expanded(
                flex: 6,
                child: HoloContainer(
                  borderRadius: 24,
                  child: Column(
                    children: [
                      // Holo shelf glow line
                      const HoloTopGlow(),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => digitalClock = !digitalClock);
                            HapticFeedback.selectionClick();
                          },
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Spacer(),
                                AnimatedCrossFade(
                                  firstChild: const Center(
                                    child: DigitalClock(),
                                  ),
                                  secondChild: const Center(
                                    child: AnimatedAnalogClock(),
                                  ),
                                  crossFadeState: digitalClock
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  duration: AppDurations.fast,
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat(
                                    'EEEE, MMMM d',
                                  ).format(DateTime.now()).toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 16,
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 18),

              // ==================== RIGHT PANE: CONTEXT (40%) ====================
              Expanded(
                flex: 4,
                child: HoloContainer(
                  borderRadius: 24,
                  borderColor: AppColors.holoCyan.withValues(alpha: 0.15),
                  child: Column(
                    children: [
                      const HoloTopGlow(),
                      Expanded(
                        child: PageView(
                          controller: _contextPageController,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // 1. MEDIA CONTROLLER PANE
                            _buildMediaPane(),

                            // 2. AMBIENT WEATHER & CALENDAR PANE
                            _buildAmbientPane(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPane() {
    if (mediaInfo == null) {
      return Center(
        child: Text(
          "NO MEDIA PLAYING",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.holoCyan.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: mediaInfo!.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      mediaInfo!.thumbnailUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 72,
                        height: 72,
                        color: Colors.white.withValues(alpha: 0.05),
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 36,
                          color: AppColors.holoCyan,
                        ),
                      ),
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      color: Colors.white.withValues(alpha: 0.05),
                      child: const Icon(
                        Icons.music_note_rounded,
                        size: 36,
                        color: AppColors.holoCyan,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            mediaInfo!.track,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            mediaInfo!.artist.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: AppColors.holoCyan,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                splashRadius: 20,
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await MediaService.previousTrack();
                  await _refreshMedia();
                },
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.holoCyan,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.holoCyan.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  splashRadius: 24,
                  icon: Icon(
                    mediaInfo!.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: const Color(0xFF121417),
                    size: 28,
                  ),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await MediaService.playPause();
                    await _refreshMedia();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                splashRadius: 20,
                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await MediaService.nextTrack();
                  await _refreshMedia();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientPane() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Weather Row
          FutureBuilder(
            future: _weatherFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox(height: 40);
              }
              final data = snapshot.data!;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.city,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _getWeatherCondition(data.weatherCode),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        WeatherService.getWeatherIcon(data.weatherCode),
                        color: AppColors.holoCyan,
                        size: 26,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${data.temperature.round()}°",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white10),
          const SizedBox(height: 12),

          // Events Preview
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return Center(
                    child: Text(
                      "No upcoming events",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final startTime = event.start as DateTime;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 2.5,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.holoCyan,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title ?? "Busy",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  DateFormat('h:mm a').format(startTime),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Digital clock component identical to HomePage's
// DigitalClock moved to widgets/digital_clock.dart
