import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as q;

import '../../constants/quran_fonts.dart';
import '../../models/settings_model.dart';

class VerseNumberOrnament extends StatelessWidget {
  final int verse;
  final MushafFont mushafFont;
  final double fontSize;
  final Color color;
  final double? height;

  const VerseNumberOrnament({
    super.key,
    required this.verse,
    required this.mushafFont,
    required this.fontSize,
    required this.color,
    this.height,
  });

  static String textFor(int verse) => q.getVerseEndSymbol(verse);

  static String arabicNumeralsFor(int verse) {
    const numerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return verse
        .toString()
        .split('')
        .map((digit) => numerals[int.parse(digit)])
        .join();
  }

  static bool usesNativeGlyph(MushafFont _) => false;

  static String measurementTextFor(int verse, MushafFont font) {
    return usesNativeGlyph(font) ? textFor(verse) : arabicNumeralsFor(verse);
  }

  @override
  Widget build(BuildContext context) {
    if (!usesNativeGlyph(mushafFont)) {
      final size = fontSize * 1.45;
      return SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _VerseNumberOrnamentPainter(color),
          child: Center(
            child: Text(
              arabicNumeralsFor(verse),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppQuranFonts.naskhStyle.copyWith(
                fontSize: fontSize * 0.54,
                color: color,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Text(
      textFor(verse),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: AppQuranFonts.styleFor(
        mushafFont,
      ).copyWith(fontSize: fontSize, color: color, height: height),
    );
  }
}

class _VerseNumberOrnamentPainter extends CustomPainter {
  final Color color;

  const _VerseNumberOrnamentPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.35;
    final stroke =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.15;
    final accent =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, stroke);
    canvas.drawCircle(center, radius * 0.82, stroke..strokeWidth = 0.65);

    for (final offset in [
      Offset(0, -radius * 1.18),
      Offset(radius * 1.18, 0),
      Offset(0, radius * 1.18),
      Offset(-radius * 1.18, 0),
    ]) {
      canvas.save();
      canvas.translate(center.dx + offset.dx, center.dy + offset.dy);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 0.30,
          height: radius * 0.30,
        ),
        accent,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_VerseNumberOrnamentPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
