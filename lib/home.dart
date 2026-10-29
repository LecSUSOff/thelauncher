import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'package:installed_apps/app_info.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_media_controller/flutter_media_controller.dart';

import 'core/constants.dart';
import 'core/services/app_service.dart';
import 'core/services/media_service.dart';
import 'widgets/common/app_icon.dart';
import 'widgets/common/glow_divider.dart';
import 'widgets/common/holo_container.dart';
import 'widgets/digital_clock.dart';
import 'widgets/app_context_menu.dart';

// ==============================================================
// ONGOING NOTIFICATION DATA MODEL
// ==============================================================

class NotificationMessage {
  final String sender;
  final String text;
  final DateTime? time;

  const NotificationMessage({
    required this.sender,
    required this.text,
    this.time,
  });

  factory NotificationMessage.fromMap(Map<String, dynamic> map) {
    final rawTime = map['time'];
    return NotificationMessage(
      sender: (map['sender'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      time: rawTime is num && rawTime > 0
          ? DateTime.fromMillisecondsSinceEpoch(rawTime.toInt())
          : null,
    );
  }
}

class OngoingNotificationData {
  final String key;
  final String packageName;
  final String title;
  final String bigTitle;
  final String content;
  final String bigText;
  final String subText;
  final String infoText;
  final String summaryText;
  final String conversationTitle;
  final String tickerText;
  final List<String> textLines;
  final List<NotificationMessage> messages;
  final List<String> actions;
  final Uint8List? iconBytes;
  final double? progress;
  final bool progressIndeterminate;
  final bool usesChronometer;
  final bool chronometerCountDown;
  final int? timestamp;
  final bool isOngoing;

  OngoingNotificationData({
    required this.key,
    required this.packageName,
    required this.title,
    required this.content,
    required this.actions,
    this.bigTitle = '',
    this.bigText = '',
    this.subText = '',
    this.infoText = '',
    this.summaryText = '',
    this.conversationTitle = '',
    this.tickerText = '',
    this.textLines = const [],
    this.messages = const [],
    this.iconBytes,
    this.progress,
    this.progressIndeterminate = false,
    this.usesChronometer = false,
    this.chronometerCountDown = false,
    this.timestamp,
    this.isOngoing = true,
  });

  factory OngoingNotificationData.fromMap(Map<String, dynamic> map) {
    final bool indeterminate = map['progressIndeterminate'] == true;
    double? parsedProgress;

    if (!indeterminate && map['progress'] is num) {
      final cur = (map['progress'] as num).toDouble();
      final max = (map['maxProgress'] is num)
          ? (map['maxProgress'] as num).toDouble()
          : 0.0;
      if (max > 0) {
        parsedProgress = (cur / max).clamp(0.0, 1.0);
      } else if (cur > 0.0 && cur <= 1.0) {
        parsedProgress = cur;
      } else if (cur > 1.0 && cur <= 100.0) {
        parsedProgress = (cur / 100.0).clamp(0.0, 1.0);
      }
    }

    if (parsedProgress == null && !indeterminate) {
      final contentStr = (map['content'] as String?) ?? '';
      final match = RegExp(r'(\d{1,3})\s*%').firstMatch(contentStr);
      if (match != null) {
        final val = double.tryParse(match.group(1)!);
        if (val != null) parsedProgress = (val / 100.0).clamp(0.0, 1.0);
      }
    }

    final bool ongoing =
        (map['isOngoing'] as bool?) ?? (map['ongoing'] as bool?) ?? true;

    final rawIcon = map['iconBytes'];
    final iconBytes = rawIcon is Uint8List
        ? rawIcon
        : (rawIcon is List
              ? Uint8List.fromList(rawIcon.whereType<int>().toList())
              : null);

    final rawWhen = map['when'];

    return OngoingNotificationData(
      key: (map['key'] as String?) ?? '',
      packageName: (map['packageName'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      bigTitle: (map['bigTitle'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      bigText: (map['bigText'] as String?) ?? '',
      subText: (map['subText'] as String?) ?? '',
      infoText: (map['infoText'] as String?) ?? '',
      summaryText: (map['summaryText'] as String?) ?? '',
      conversationTitle: (map['conversationTitle'] as String?) ?? '',
      tickerText: (map['tickerText'] as String?) ?? '',
      textLines:
          (map['textLines'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      messages:
          (map['messages'] as List?)
              ?.whereType<Map>()
              .map(
                (e) =>
                    NotificationMessage.fromMap(Map<String, dynamic>.from(e)),
              )
              .where((m) => m.text.isNotEmpty)
              .toList() ??
          [],
      actions:
          (map['actions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      iconBytes: iconBytes,
      progress: parsedProgress,
      progressIndeterminate: indeterminate,
      usesChronometer: map['usesChronometer'] == true,
      chronometerCountDown: map['chronometerCountDown'] == true,
      timestamp: rawWhen is num ? rawWhen.toInt() : null,
      isOngoing: ongoing,
    );
  }

  /// Signature of every value that should bring a hidden notification back.
  String get signature => [
    key,
    packageName,
    title,
    bigTitle,
    content,
    bigText,
    subText,
    infoText,
    summaryText,
    conversationTitle,
    tickerText,
    textLines.join('\u0001'),
    messages.map((m) => '${m.sender}\u0002${m.text}').join('\u0001'),
    actions.join('\u0001'),
    progress?.toString() ?? '',
    progressIndeterminate.toString(),
    usesChronometer.toString(),
    chronometerCountDown.toString(),
    timestamp?.toString() ?? '',
    isOngoing.toString(),
    (iconBytes?.length ?? 0).toString(),
  ].join('\u0003');
}

// ==============================================================
// HOME PAGE
// ==============================================================

class HomePage extends StatefulWidget {
  final List<AppInfo> pinnedApps;
  final List<AppInfo> blockedApps;
  final ValueChanged<AppInfo> onTogglePin;
  final ValueChanged<AppInfo> onToggleBlock;
  final List<String> userWidgets;
  final ValueChanged<String> onAddWidget;
  final ValueChanged<String> onRemoveWidget;

  const HomePage({
    super.key,
    required this.pinnedApps,
    required this.blockedApps,
    required this.onTogglePin,
    required this.onToggleBlock,
    required this.userWidgets,
    required this.onAddWidget,
    required this.onRemoveWidget,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const MethodChannel _notificationChannel = MethodChannel(
    'launcher/notifications',
  );

  MediaInfo? mediaInfo;
  bool digitalClock = false;

  OngoingNotificationData? _activeNotification;
  OngoingNotificationData? _dismissedNotification;
  bool _isDismissed = false;

  final PageController _pageController = PageController();

  static const double _kHeroWidgetHeight = 315.0;

  @override
  void initState() {
    super.initState();
    _initMediaController();
    _initNotificationListener();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- NATIVE NOTIFICATION BRIDGE ---

  void _initNotificationListener() async {
    _notificationChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationUpdated') {
        if (!mounted) return;
        final payload = call.arguments;

        setState(() {
          if (payload == null) {
            _activeNotification = null;
            _dismissedNotification = null;
            _isDismissed = false;
          } else {
            final map = Map<String, dynamic>.from(payload as Map);
            final updated = OngoingNotificationData.fromMap(map);

            // Filter: ONLY display ongoing notifications
            if (!updated.isOngoing) {
              _activeNotification = null;
              _dismissedNotification = null;
              _isDismissed = false;
              return;
            }

            if (_isDismissed && _dismissedNotification?.key == updated.key) {
              if (_dismissedNotification?.signature != updated.signature) {
                _isDismissed = false;
              }
            }
            _activeNotification = updated;
          }
        });
      }
    });

    try {
      final bool hasPermission =
          await _notificationChannel.invokeMethod('hasPermission') ?? false;

      if (!hasPermission) {
        await _notificationChannel.invokeMethod('requestPermission');
      } else {
        await _notificationChannel.invokeMethod('sync');
      }
    } catch (e) {
      debugPrint("Notification channel error: $e");
    }
  }

  void _dismissNotification() {
    if (_activeNotification == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _dismissedNotification = _activeNotification;
      _isDismissed = true;
    });
  }

  void _restoreNotification() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isDismissed = false;
    });
  }

  void _openNotification() {
    if (_activeNotification == null) return;
    HapticFeedback.lightImpact();

    final key = _activeNotification!.key;
    final pkg = _activeNotification!.packageName;

    // 1. Invoke native notification pending intent
    if (key.isNotEmpty) {
      _notificationChannel.invokeMethod('open', {'key': key}).catchError((e) {
        debugPrint("Native open error: $e");
      });
    }

    // 2. Concurrently launch the app package so opening is 100% reliable
    if (pkg.isNotEmpty) {
      AppService.launchApp(context, pkg);
    }
  }

  void _triggerNotificationAction(int index) {
    final notification = _activeNotification;
    if (notification == null || notification.key.isEmpty) return;
    HapticFeedback.mediumImpact();
    _notificationChannel
        .invokeMethod('triggerAction', {
          'key': notification.key,
          'actionIndex': index,
        })
        .catchError((e) {
          debugPrint("Native action error: $e");
        });
  }

  // --- MEDIA CONTROLLER ---

  Future<void> _initMediaController() async {
    final info = await MediaService.getCurrentMediaInfo();
    if (mounted) setState(() => mediaInfo = info);
  }

  Future<void> _refreshMedia() async {
    final info = await MediaService.getCurrentMediaInfo();
    if (mounted) setState(() => mediaInfo = info);
  }

  // --- WIDGET MANAGEMENT ---

  void _showWriteHtmlDialog() {
    final TextEditingController htmlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1217),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.holoCyan.withValues(alpha: 0.3)),
        ),
        title: const Text(
          "CODE WIDGET",
          style: TextStyle(
            color: AppColors.holoCyan,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        content: TextField(
          controller: htmlController,
          maxLines: 8,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText:
                "<h1>Hello</h1>\n<p style='color:white'>Write HTML/CSS...</p>",
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.holoCyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.white60, letterSpacing: 0.8),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.holoCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (htmlController.text.trim().isNotEmpty) {
                widget.onAddWidget(htmlController.text);
                Navigator.pop(context);
              }
            },
            child: const Text(
              "APPLY",
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWidgetSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1217),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.white10),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "ADD CUSTOM WIDGET",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.holoCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.holoCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.code_rounded,
                  color: AppColors.holoCyan,
                  size: 20,
                ),
              ),
              title: const Text(
                "Write HTML / CSS Code",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
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
        backgroundColor: const Color(0xFF0F1217),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        title: const Text(
          "REMOVE WIDGET",
          style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1),
        ),
        content: const Text(
          "Delete this custom widget from your launcher space?",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: AppColors.holoCyan),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              widget.onRemoveWidget(htmlContent);
              Navigator.pop(context);
            },
            child: const Text("REMOVE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showLiveActivity = _activeNotification != null && !_isDismissed;
    final showRestorePill = _activeNotification != null && _isDismissed;

    return Stack(
      children: [
        Column(
          children: [
            // 1. HERO WIDGET STACK
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
              child: HoloContainer(
                height: _kHeroWidgetHeight,
                borderRadius: AppDimensions.borderRadiusMedium,
                child: Column(
                  children: [
                    const HoloTopGlow(),
                    Expanded(
                      child: PageView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        controller: _pageController,
                        children: [
                          // 0: CLOCK
                          GestureDetector(
                            onTap: () {
                              setState(() => digitalClock = !digitalClock);
                              HapticFeedback.selectionClick();
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0,
                                        vertical: 8.0,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: AnimatedCrossFade(
                                          firstChild: const Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: DigitalClock(),
                                          ),
                                          secondChild: const Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: AnimatedAnalogClock(),
                                          ),
                                          crossFadeState: digitalClock
                                              ? CrossFadeState.showFirst
                                              : CrossFadeState.showSecond,
                                          duration: AppDurations.fast,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  "TAP TO SWITCH TO ${digitalClock ? "ANALOG" : "DIGITAL"}",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),

                          // 1: CALENDAR
                          Center(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: TableCalendar(
                                firstDay: DateTime.utc(2010, 10, 16),
                                lastDay: DateTime.utc(2030, 3, 14),
                                focusedDay: DateTime.now(),
                                rowHeight: 33,
                                daysOfWeekHeight: 18,
                                calendarStyle: CalendarStyle(
                                  defaultTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  weekendTextStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 12,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: AppColors.holoCyan.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.holoCyan,
                                      width: 1.2,
                                    ),
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: AppColors.holoCyan,
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                headerStyle: const HeaderStyle(
                                  headerPadding: EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  titleTextStyle: TextStyle(
                                    color: AppColors.holoCyan,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                  formatButtonVisible: false,
                                  leftChevronIcon: Icon(
                                    Icons.chevron_left_rounded,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  rightChevronIcon: Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 2: MEDIA PLAYER
                          Center(
                            child: mediaInfo == null
                                ? Text(
                                    "NO MEDIA PLAYING",
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 11,
                                      letterSpacing: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                      vertical: 8.0,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child:
                                                  mediaInfo!
                                                      .thumbnailUrl
                                                      .isNotEmpty
                                                  ? Image.network(
                                                      mediaInfo!.thumbnailUrl,
                                                      width: 64,
                                                      height: 64,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, _, _) =>
                                                          Container(
                                                            width: 64,
                                                            height: 64,
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.05,
                                                                ),
                                                            child: const Icon(
                                                              Icons
                                                                  .music_note_rounded,
                                                              size: 30,
                                                              color: AppColors
                                                                  .holoCyan,
                                                            ),
                                                          ),
                                                    )
                                                  : Container(
                                                      width: 64,
                                                      height: 64,
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.05,
                                                          ),
                                                      child: const Icon(
                                                        Icons
                                                            .music_note_rounded,
                                                        size: 30,
                                                        color:
                                                            AppColors.holoCyan,
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    mediaInfo!.track,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    mediaInfo!.artist
                                                        .toUpperCase(),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.9,
                                                      color: AppColors.holoCyan,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              iconSize: 28,
                                              splashRadius: 22,
                                              icon: const Icon(
                                                Icons.skip_previous_rounded,
                                                color: Colors.white,
                                              ),
                                              onPressed: () async {
                                                HapticFeedback.lightImpact();
                                                await MediaService.previousTrack();
                                                await _refreshMedia();
                                              },
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              decoration: const BoxDecoration(
                                                color: AppColors.holoCyan,
                                                shape: BoxShape.circle,
                                              ),
                                              child: IconButton(
                                                iconSize: 30,
                                                splashRadius: 26,
                                                icon: Icon(
                                                  mediaInfo!.isPlaying
                                                      ? Icons.pause_rounded
                                                      : Icons
                                                            .play_arrow_rounded,
                                                  color: const Color(
                                                    0xFF121417,
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  HapticFeedback.mediumImpact();
                                                  await MediaService.playPause();
                                                  await _refreshMedia();
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            IconButton(
                                              iconSize: 28,
                                              splashRadius: 22,
                                              icon: const Icon(
                                                Icons.skip_next_rounded,
                                                color: Colors.white,
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
                                  ),
                          ),

                          // 3+: CUSTOM USER WIDGETS
                          ...widget.userWidgets.map((htmlContent) {
                            return GestureDetector(
                              onLongPress: () =>
                                  _showRemoveWidgetDialog(htmlContent),
                              child: Center(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.all(14.0),
                                  child: HtmlWidget(
                                    htmlContent,
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.0,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),

                          // LAST: ADD WIDGET BUTTON
                          Center(
                            child: GestureDetector(
                              onTap: _showAddWidgetSheet,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      border: Border.all(
                                        color: AppColors.holoCyan.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      size: 32,
                                      color: AppColors.holoCyan,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Add Widget",
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
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
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: 4 + widget.userWidgets.length,
                        effect: const ExpandingDotsEffect(
                          activeDotColor: AppColors.holoCyan,
                          dotColor: Colors.white24,
                          dotHeight: 5,
                          dotWidth: 5,
                          expansionFactor: 3.0,
                          spacing: 5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. OPEN WALLPAPER SPACE
            const Spacer(),

            // 3. HOLO × FLAT ONGOING NOTIFICATION CONSOLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.08),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: showLiveActivity
                    ? _HoloOngoingNotificationCard(
                        key: ValueKey(_activeNotification!.key),
                        data: _activeNotification!,
                        onOpen: _openNotification,
                        onDismiss: _dismissNotification,
                        onActionTap: _triggerNotificationAction,
                      )
                    : (showRestorePill
                          ? _HoloRestoreConsole(
                              key: const ValueKey('holo_restore_pill'),
                              onRestore: _restoreNotification,
                            )
                          : const SizedBox.shrink()),
              ),
            ),

            // 4. CYAN GLOW DIVIDER
            const GlowDivider(
              height: 1.5,
              opacity: 1.0,
              glow: true,
              margin: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),

            // 5. DOCK
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.pinnedApps.map((app) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        AppService.launchApp(context, app.packageName);
                      },
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        AppContextMenu.show(
                          context,
                          app: app,
                          isPinned: widget.pinnedApps.any(
                            (a) => a.packageName == app.packageName,
                          ),
                          isBlocked: widget.blockedApps.any(
                            (a) => a.packageName == app.packageName,
                          ),
                          onTogglePin: widget.onTogglePin,
                          onToggleBlock: widget.onToggleBlock,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: AppIcon(app: app),
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

// ==============================================================
// HOLO × FLAT ONGOING NOTIFICATION CARD (SWIPE + DIRECT TAP)
// ==============================================================

class _HoloOngoingNotificationCard extends StatelessWidget {
  final OngoingNotificationData data;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;
  final ValueChanged<int> onActionTap;

  const _HoloOngoingNotificationCard({
    super.key,
    required this.data,
    required this.onOpen,
    required this.onDismiss,
    required this.onActionTap,
  });

  String _cleanPackageName(String pkg) {
    if (pkg.contains('google.android.apps.maps')) return 'GOOGLE MAPS';
    if (pkg.contains('.')) {
      final parts = pkg.split('.');
      final last = parts.last;
      if (last.toLowerCase() == 'android' && parts.length > 1) {
        return parts[parts.length - 2].toUpperCase();
      }
      return last.toUpperCase();
    }
    return pkg.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final details =
        <String>{
              if (data.conversationTitle.isNotEmpty) data.conversationTitle,
              if (data.subText.isNotEmpty) data.subText,
              if (data.infoText.isNotEmpty) data.infoText,
              if (data.summaryText.isNotEmpty) data.summaryText,
              if (data.tickerText.isNotEmpty) data.tickerText,
            }
            .where(
              (text) =>
                  text != data.title &&
                  text != data.bigTitle &&
                  text != data.content &&
                  text != data.bigText,
            )
            .toList();

    final messages = data.messages
        .where((message) => message.text != data.content)
        .toList();
    final visibleMessages = messages.length > 3
        ? messages.sublist(messages.length - 3)
        : messages;

    return Dismissible(
      key: ValueKey(data.key.isNotEmpty ? data.key : data.packageName),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDismiss();
      },
      child: HoloContainer(
        borderRadius: 14,
        sigmaX: 18,
        sigmaY: 18,
        color: const Color(0xFF0C1014).withValues(alpha: 0.90),
        borderColor: AppColors.holoCyan.withValues(alpha: 0.35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            splashColor: AppColors.holoCyan.withValues(alpha: 0.20),
            highlightColor: AppColors.holoCyan.withValues(alpha: 0.08),
            onTap: onOpen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TOP HOLO ACCENT STRIP
                const HoloTopGlow(height: 1.5, opacity: 0.8),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. HEADER ROW: APP ICON, PACKAGE & CONTROLS
                      Row(
                        children: [
                          _buildAppIcon(size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _cleanPackageName(data.packageName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),

                          // OPEN LAUNCH GLYPH
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: 14,
                            color: AppColors.holoCyan.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 8),

                          // DISMISS BUTTON
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onDismiss();
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      // 2. TITLE & CONTENT
                      Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),

                      if (data.bigTitle.isNotEmpty &&
                          data.bigTitle != data.title) ...[
                        const SizedBox(height: 2),
                        Text(
                          data.bigTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ],

                      if (data.content.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          data.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                      ],

                      if (data.bigText.isNotEmpty &&
                          data.bigText != data.content) ...[
                        const SizedBox(height: 3),
                        Text(
                          data.bigText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.60),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],

                      // SUBTEXT / INFO / SUMMARY / CONVERSATION / TICKER
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        for (final detail in details.take(3))
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '›',
                                  style: TextStyle(
                                    color: AppColors.holoCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    detail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                      fontSize: 10,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],

                      // INBOX-STYLE TEXT LINES
                      if (data.textLines.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        for (final line in data.textLines.take(4))
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 3,
                                  height: 3,
                                  margin: const EdgeInsets.only(top: 5),
                                  decoration: const BoxDecoration(
                                    color: AppColors.holoCyan,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    line,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.58,
                                      ),
                                      fontSize: 10.5,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],

                      // MESSAGING-STYLE CONVERSATION (LATEST 3)
                      if (visibleMessages.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        for (final message in visibleMessages)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  if (message.sender.isNotEmpty)
                                    TextSpan(
                                      text: '${message.sender.toUpperCase()}  ',
                                      style: TextStyle(
                                        color: AppColors.holoCyan.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  TextSpan(
                                    text: message.text,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.62,
                                      ),
                                      fontSize: 10.5,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],

                      // 3. CHRONOMETER
                      if (data.usesChronometer && data.timestamp != null) ...[
                        const SizedBox(height: 8),
                        _NotificationChronometer(
                          timestamp: data.timestamp!,
                          countDown: data.chronometerCountDown,
                        ),
                      ],

                      // 4. PROGRESS BAR (INDETERMINATE OR MEASURABLE)
                      if (data.progressIndeterminate) ...[
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: null,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.1,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.holoCyan,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "LIVE",
                              style: TextStyle(
                                color: AppColors.holoCyan,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ] else if (data.progress != null) ...[
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: data.progress,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.1,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.holoCyan,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${(data.progress! * 100).toInt()}%",
                              style: const TextStyle(
                                color: AppColors.holoCyan,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // 5. NOTIFICATION ACTIONS
                      if (data.actions.any(
                        (action) => action.trim().isNotEmpty,
                      )) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            for (var i = 0; i < data.actions.length; i++)
                              if (data.actions[i].trim().isNotEmpty)
                                _buildActionButton(i, data.actions[i].trim()),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(int index, String label) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
            side: BorderSide(
              color: AppColors.holoCyan.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => onActionTap(index),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon({required double size}) {
    if (data.iconBytes != null && data.iconBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          data.iconBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.holoCyan.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.navigation_rounded,
        size: size * 0.7,
        color: AppColors.holoCyan,
      ),
    );
  }
}

// ==============================================================
// HOLO LIVE CHRONOMETER
// ==============================================================

class _NotificationChronometer extends StatefulWidget {
  final int timestamp;
  final bool countDown;

  const _NotificationChronometer({
    required this.timestamp,
    required this.countDown,
  });

  @override
  State<_NotificationChronometer> createState() =>
      _NotificationChronometerState();
}

class _NotificationChronometerState extends State<_NotificationChronometer> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    final seconds = safe.inSeconds.remainder(60);

    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:"
          "${minutes.toString().padLeft(2, '0')}:"
          "${seconds.toString().padLeft(2, '0')}";
    }
    return "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final target = DateTime.fromMillisecondsSinceEpoch(widget.timestamp);
    final now = DateTime.now();
    final duration = widget.countDown
        ? target.difference(now)
        : now.difference(target);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.countDown
              ? Icons.hourglass_bottom_rounded
              : Icons.timer_outlined,
          size: 13,
          color: AppColors.holoCyan.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 5),
        Text(
          _formatDuration(duration),
          style: const TextStyle(
            color: AppColors.holoCyan,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ==============================================================
// HOLO RESTORE CONSOLE
// ==============================================================

class _HoloRestoreConsole extends StatelessWidget {
  final VoidCallback onRestore;

  const _HoloRestoreConsole({super.key, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRestore,
      child: HoloContainer(
        height: 34,
        borderRadius: 8,
        sigmaX: 12,
        sigmaY: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: const Color(0xFF0C1014).withValues(alpha: 0.75),
        borderColor: AppColors.holoCyan.withValues(alpha: 0.25),
        borderWidth: 0.8,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.unfold_more_rounded,
              size: 14,
              color: AppColors.holoCyan,
            ),
            const SizedBox(width: 7),
            Text(
              "STATUS STREAM HIDDEN // TAP TO RESTORE",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
