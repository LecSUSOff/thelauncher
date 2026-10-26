import 'package:flutter/material.dart';
import '../../core/constants.dart';

class GlowDivider extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const GlowDivider({
    super.key,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.holoCyan.withValues(alpha: 0.25),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
