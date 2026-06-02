import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../constants/app_colors.dart';

class QiblaCompassWidget extends StatelessWidget {
  final double qiblaDirection;

  const QiblaCompassWidget({super.key, required this.qiblaDirection});

  @override
  Widget build(BuildContext context) {
    final stream = FlutterCompass.events;
    if (stream == null) {
      return _CompassFace(rotationDegrees: qiblaDirection);
    }

    return StreamBuilder<CompassEvent>(
      stream: stream,
      builder: (context, snapshot) {
        final heading = snapshot.data?.heading;
        final rotation =
            heading == null ? qiblaDirection : qiblaDirection - heading;
        return _CompassFace(rotationDegrees: rotation);
      },
    );
  }
}

class _CompassFace extends StatelessWidget {
  final double rotationDegrees;

  const _CompassFace({required this.rotationDegrees});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size.square(280), painter: _CompassPainter()),
          Transform.rotate(
            angle: rotationDegrees * math.pi / 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.navigation_rounded,
                  size: 96,
                  color: AppColors.goldLt,
                ),
                Container(
                  width: 4,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;

    final fill =
        Paint()
          ..color = const Color(0xFF202020)
          ..style = PaintingStyle.fill;
    final border =
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
    final tick =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 1.1;

    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, border);
    canvas.drawCircle(center, radius * 0.72, border);

    for (var i = 0; i < 60; i++) {
      final angle = i * 6 * math.pi / 180;
      final isMajor = i % 5 == 0;
      final outer = Offset(
        center.dx + math.sin(angle) * radius,
        center.dy - math.cos(angle) * radius,
      );
      final innerRadius = radius - (isMajor ? 15 : 8);
      final inner = Offset(
        center.dx + math.sin(angle) * innerRadius,
        center.dy - math.cos(angle) * innerRadius,
      );
      canvas.drawLine(inner, outer, tick..strokeWidth = isMajor ? 1.6 : 0.8);
    }

    _drawLabel(canvas, center, radius, 'N', 0);
    _drawLabel(canvas, center, radius, 'E', 90);
    _drawLabel(canvas, center, radius, 'S', 180);
    _drawLabel(canvas, center, radius, 'W', 270);
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    String label,
    double degrees,
  ) {
    final angle = degrees * math.pi / 180;
    final position = Offset(
      center.dx + math.sin(angle) * (radius - 34),
      center.dy - math.cos(angle) * (radius - 34),
    );
    final paragraph = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: label == 'N' ? AppColors.goldLt : Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    paragraph.paint(
      canvas,
      position - Offset(paragraph.width / 2, paragraph.height / 2),
    );
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) => false;
}
