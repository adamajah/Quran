import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class IslamicOrnament extends StatelessWidget {
  final double size;
  final Color? color;
  final double opacity;

  const IslamicOrnament({
    super.key,
    this.size = 100,
    this.color,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Icon(
        Icons.brightness_7_outlined, // Placeholder for a real ornament icon
        size: size,
        color: color ?? AppColors.gold,
      ),
    );
  }
}
