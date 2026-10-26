import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_calendar/device_calendar.dart';
import 'package:intl/intl.dart';
import 'core/constants.dart';
import 'core/services/app_service.dart';
import 'core/services/weather_service.dart';
import 'core/services/calendar_service.dart';
import 'core/utils/app_utils.dart';

class YouHub extends StatefulWidget {
  const YouHub({super.key});

  @override
  State<YouHub> createState() => _YouHubState();
}

class _YouHubState extends State<YouHub> {
  // Using AppColors constants

  final TextEditingController _notesController = TextEditingController();

  // Independent Futures for smart loading
  Future<WeatherData?>? _weatherFuture;
  Future<List<Event>>? _eventsFuture;
  Future<String>? _factFuture;

  @override
  void initState() {
    super.initState();
    _loadSavedNotes();
    _refreshFeed(); // Loads all futures
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Triggers all futures. Linked to a Pull-To-Refresh gesture.
  Future<void> _refreshFeed() async {
    setState(() {
      _weatherFuture = fetchCurrentWeather();
      _eventsFuture = _fetchUpcomingEvents();
      _factFuture = _fetchDailyFact();
    });
  }

  Future<void> _loadSavedNotes() async {
    final notes = await AppService.getNotes();
    if (mounted) {
      setState(() {
        _notesController.text = notes;
      });
    }
  }

  Future<void> _saveNotes(String text) async {
    await AppService.saveNotes(text);
  }

  // --- CALENDAR INTEGRATION ---
  Future<List<Event>> _fetchUpcomingEvents() async {
    return CalendarService.fetchUpcomingEvents(daysAhead: 2, limit: 3);
  }

  // --- WEATHER INTEGRATION ---
  Future<WeatherData?> fetchCurrentWeather() async {
    return WeatherService.fetchCurrentWeather(timeout: const Duration(seconds: 7));
  }

  // --- SMART FACT INTEGRATION ---
  Future<String> _fetchDailyFact() async {
    try {
      final res = await http.get(Uri.parse('https://uselessfacts.jsph.pl/api/v2/facts/random')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return json.decode(res.body)['text'];
      }
    } catch (_) {}
    return "The first computer mouse was invented by Douglas Engelbart in 1964 and consisted of a wooden shell with two metal wheels.";
  }

  String _getWeatherCondition(int code) {
    return WeatherService.getWeatherCondition(code);
  }
 
  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.wb_cloudy_rounded;
    if (code <= 48) return Icons.cloud_queue_rounded;
    if (code <= 67) return Icons.water_drop_rounded;
    if (code <= 77) return Icons.ac_unit_rounded;
    if (code <= 82) return Icons.grain_rounded;
    return Icons.flash_on_rounded;
  }

  String _getGreeting() {
    return AppUtils.getGreeting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                _getGreeting(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 36,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.holoSurface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.holoCyan.withValues(alpha: 0.22),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 2,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, AppColors.holoCyan, Colors.transparent],
                              ),
                            ),
                          ),

                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _refreshFeed,
                              color: AppColors.holoCyan,
                              backgroundColor: AppColors.holoSurface,
                              child: ListView(
                                padding: const EdgeInsets.all(20),
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  
                                  // 1. LIVE WEATHER
                                  HoloSection(
                                    title: "WEATHER",
                                    icon: Icons.cloud_outlined,
                                    showDivider: true,
                                    child: FutureBuilder(
                                      future: _weatherFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator(color: AppColors.holoCyan));
                                        }
                                        final data = snapshot.data;
                                        if (data == null) {
                                          return const Text("Weather unavailable", style: TextStyle(color: Colors.white70));
                                        }
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.holoCyan),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      data.city,
                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _getWeatherCondition(data.weatherCode),
                                                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(_getWeatherIcon(data.weatherCode), color: AppColors.holoCyan, size: 36),
                                                const SizedBox(width: 12),
                                                Text(
                                                  "${data.temperature.round()}°",
                                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),

                                  // 2. UPCOMING CALENDAR
                                  HoloSection(
                                    title: "Get ready for",
                                    icon: Icons.event_note_rounded,
                                    showDivider: true,
                                    child: FutureBuilder<List<Event>>(
                                      future: _eventsFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator(color: AppColors.holoCyan, strokeWidth: 2));
                                        }
                                        final events = snapshot.data ?? [];
                                        if (events.isEmpty) {
                                          return const Text("No events scheduled.", style: TextStyle(color: Colors.white70));
                                        }
                                        return Column(
                                          children: events.map((event) {
                                            final startTime = event.start as DateTime;
                                            final timeString = DateFormat('h:mm a').format(startTime);
                                            final dayString = startTime.day == DateTime.now().day ? "Today" : "Tomorrow";
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 12.0),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 3,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.holoCyan,
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          event.title ?? "Busy",
                                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          "$dayString, $timeString",
                                                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                  ),

                                  // 3. QUICK NOTE
                                  HoloSection(
                                    title: "Quick Note",
                                    icon: Icons.edit_note_rounded,
                                    showDivider: true,
                                    child: TextField(
                                      controller: _notesController,
                                      maxLines: 5,
                                      minLines: 2,
                                      onChanged: _saveNotes,
                                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                                      decoration: InputDecoration(
                                        hintText: "Write a quick thought or a reminder...",
                                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                                        filled: true,
                                        fillColor: Colors.black.withValues(alpha: 0.25),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 4. DAILY FACT
                                  HoloSection(
                                    title: "Did you know?",
                                    icon: Icons.lightbulb_outline_rounded,
                                    showDivider: false,
                                    child: FutureBuilder<String>(
                                      future: _factFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator(color: AppColors.holoCyan, strokeWidth: 2));
                                        }
                                        return Text(
                                          snapshot.data ?? "",
                                          style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white70),
                                        );
                                      },
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HoloSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool showDivider;

  const HoloSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.holoCyan),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        child,

        if (showDivider) ...[
          const SizedBox(height: 24),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.holoCyan.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]
      ],
    );
  }
}