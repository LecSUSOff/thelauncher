import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';

class PauseScreen extends StatefulWidget {
  final String packageName;

  const PauseScreen({
    super.key,
    required this.packageName,
  });

  @override
  State<PauseScreen> createState() => _PauseScreenState();
}

class _PauseScreenState extends State<PauseScreen>
    with SingleTickerProviderStateMixin {
  static const Color holoCyan = Color(0xFF33B5E5);
  static const Color holoSurface = Color(0xCC181B20);

  late AnimationController _sweepController;
  Timer? _timer;
  int _secondsLeft = 5;
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();

    // 1. Continuous slow radar sweep for the telemetry ring
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 2. 5-second technical countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        HapticFeedback.selectionClick();
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        HapticFeedback.mediumImpact();
        setState(() {
          _secondsLeft = 0;
          _canProceed = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _proceedToApp() {
    HapticFeedback.lightImpact();
    InstalledApps.startApp(widget.packageName);
    Navigator.of(context).pop();
  }

  void _stepBack() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  String get _targetAppName {
    // Extracts clean name from package: "com.instagram.android" -> "INSTAGRAM"
    final parts = widget.packageName.split('.');
    return (parts.length > 1 ? parts[parts.length - (parts.last == 'android' ? 2 : 1)] : widget.packageName).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (5 - _secondsLeft) / 5.0;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.75),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: const SizedBox.expand(),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  decoration: BoxDecoration(
                    color: holoSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: holoCyan.withValues(alpha: 0.22),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Signature 2px Holo Shelf Rim Light
                        Container(
                          height: 2,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, holoCyan, Colors.transparent],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                          child: Column(
                            children: [

                              const SizedBox(height: 20),

                              // Target Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: Text(
                                  _targetAppName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Neo-Holo Telemetry Ring
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [

                                    // Crisp progress arc
                                    SizedBox(
                                      width: 130,
                                      height: 130,
                                      child: CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 2.0,
                                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                                        color: _canProceed ? Colors.greenAccent : holoCyan,
                                      ),
                                    ),

                                    // Center Digits
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _canProceed ? "Open?" : "$_secondsLeft",
                                          style: TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w200,
                                            letterSpacing: 2.0,
                                            color: _canProceed ? Colors.greenAccent : Colors.white,
                                          ),
                                        ),
                                        Text(
                                          _canProceed ? "Open the app?" : "Take a breath",
                                          style: TextStyle(
                                            fontSize: 9,
                                            letterSpacing: 1.5,
                                            color: holoCyan.withValues(alpha: 0.6),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Tactical Holo Buttons
                              // 1. Primary Action: Step back
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: holoCyan.withValues(alpha: 0.1),
                                    side: BorderSide(
                                      color: holoCyan.withValues(alpha: 0.7),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _stepBack,
                                  child: const Text(
                                    "Nevermind",
                                    style: TextStyle(
                                      color: holoCyan,
                                      fontSize: 13,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // 2. Secondary Action: Proceed (Fades in when timer clears)
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: _canProceed ? 1.0 : 0.0,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: TextButton(
                                    onPressed: _canProceed ? _proceedToApp : null,
                                    child: Text(
                                      "I need to open it",
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.45),
                                        fontSize: 12,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}

// Custom Painter for 2012 Holo HUD Brackets & Ticks
class _HoloTelemetryPainter extends CustomPainter {
  final Color color;

  _HoloTelemetryPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw 4 corner radar tick marks
    const tickCount = 8;
    for (int i = 0; i < tickCount; i++) {
      final double angle = (i * 2 * math.pi) / tickCount;
      final p1 = Offset(
        center.dx + (radius - 6) * math.cos(angle),
        center.dy + (radius - 6) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}