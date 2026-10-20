import 'package:flutter/material.dart';
import 'package:animated_analog_clock/animated_analog_clock.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AnimatedAnalogClock(),
    );
  }
}