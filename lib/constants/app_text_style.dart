import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';
import 'app_colors.dart';

abstract class AppTextStyle {
  // ── Legacy Widget Builders (used in SplashScreen)
  static Widget headlineText(BuildContext context, String text) {
    return Text(text,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.gold, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center);
  }

  static Widget titleMediumText(BuildContext context, String text) {
    return Text(text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.gold.withOpacity(0.7), fontSize: 14),
        textAlign: TextAlign.center);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ QURAN STYLES — font Hafs dari quran_library (identik Mushaf Madinah)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Teks AYAT AL-QURAN — font Hafs utama
  static TextStyle quranVerseStyle({
    double fontSize = 22,
    Color color = AppColors.ink,
    double height = 2.2,
    Color? backgroundColor,
    List<Shadow>? shadows,
  }) {
    return QuranLibrary().hafsStyle.copyWith(
      fontSize: fontSize,
      height: height,
      color: color,
      backgroundColor: backgroundColor,
      shadows: shadows,
    );
  }

  /// Teks NAMA SURAH — font Hafs untuk nama surah
  static TextStyle quranSurahNameStyle({
    double? fontSize,
    Color? color,
  }) {
    return QuranLibrary().hafsStyle.copyWith(
      fontSize: fontSize ?? 20,
      color: color ?? AppColors.dark,
      fontWeight: FontWeight.bold,
    );
  }

  /// Teks NOMOR AYAT — di dalam lingkaran emas
  static TextStyle quranVerseNumberStyle({
    double fontSize = 10,
    Color color = AppColors.dark,
  }) {
    return QuranLibrary().hafsStyle.copyWith(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.bold,
    );
  }

  /// Teks INFO HALAMAN — juz, info header mushaf
  static TextStyle quranPageInfoStyle({
    double fontSize = 12,
    Color color = AppColors.dark,
  }) {
    return QuranLibrary().naskhStyle.copyWith(
      fontSize: fontSize,
      color: color.withOpacity(0.8),
    );
  }

  /// Teks TERJEMAHAN — modern, clean, dan nyaman dibaca lama
  static TextStyle quranTranslationStyle({
    required bool isDark,
    double fontSize = 14,
  }) {
    return TextStyle(
      fontSize: fontSize,
      height: 1.6,
      fontWeight: FontWeight.w300,
      letterSpacing: 0.2,
      fontFamily: 'Roboto', // Or any clean sans-serif
      color: isDark ? Colors.white.withOpacity(0.65) : AppColors.dark.withOpacity(0.7),
    );
  }
}
