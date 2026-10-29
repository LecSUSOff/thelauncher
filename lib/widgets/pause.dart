import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import '../core/constants.dart';
import 'common/holo_container.dart';

class PauseScreen extends StatefulWidget {
  final String packageName;

  const PauseScreen({super.key, required this.packageName});

  @override
  State<PauseScreen> createState() => _PauseScreenState();
}

class _PauseScreenState extends State<PauseScreen> {
  Timer? _timer;
  int _secondsLeft = 5;
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();

    // 5-second technical countdown
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
    return (parts.length > 1
            ? parts[parts.length - (parts.last == 'android' ? 2 : 1)]
            : widget.packageName)
        .toUpperCase();
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: HoloContainer(
                    borderRadius: 20,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Signature 2px Holo Shelf Rim Light
                        const HoloTopGlow(),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),

                              // Target Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
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
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.05),
                                        color: _canProceed
                                            ? Colors.greenAccent
                                            : AppColors.holoCyan,
                                      ),
                                    ),

                                    // Center Digits
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _canProceed
                                              ? "Open?"
                                              : "$_secondsLeft",
                                          style: TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w200,
                                            letterSpacing: 2.0,
                                            color: _canProceed
                                                ? Colors.greenAccent
                                                : Colors.white,
                                          ),
                                        ),
                                        Text(
                                          _canProceed
                                              ? "Open the app?"
                                              : "Take a breath",
                                          style: TextStyle(
                                            fontSize: 9,
                                            letterSpacing: 1.5,
                                            color: AppColors.holoCyan
                                                .withValues(alpha: 0.6),
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
                                    backgroundColor: AppColors.holoCyan
                                        .withValues(alpha: 0.1),
                                    side: BorderSide(
                                      color: AppColors.holoCyan.withValues(
                                        alpha: 0.7,
                                      ),
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
                                      color: AppColors.holoCyan,
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
                                    onPressed: _canProceed
                                        ? _proceedToApp
                                        : null,
                                    child: Text(
                                      "I need to open it",
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.45,
                                        ),
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
