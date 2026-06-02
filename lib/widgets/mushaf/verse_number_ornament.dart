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

  @override
  Widget build(BuildContext context) {
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
