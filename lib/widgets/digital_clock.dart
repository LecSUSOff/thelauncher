import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DigitalClock extends StatefulWidget {
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;

  const DigitalClock({
    super.key,
    this.fontSize = 65,
    this.fontWeight = FontWeight.w400,
    this.letterSpacing = 2.0,
  });

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
      style: TextStyle(
        color: Colors.white,
        fontSize: widget.fontSize,
        fontWeight: widget.fontWeight,
        letterSpacing: widget.letterSpacing,
      ),
    );
  }
}
