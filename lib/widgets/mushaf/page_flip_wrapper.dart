import 'dart:math' as math;
import 'package:flutter/material.dart';

class PageFlipWrapper extends StatelessWidget {
  final bool flipping;
  final double angle;
  final Widget child;

  const PageFlipWrapper({
    super.key,
    required this.flipping,
    required this.angle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!flipping) return child;
    return Transform(
      alignment: Alignment.centerRight,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(angle),
      child: child,
    );
  }
}
