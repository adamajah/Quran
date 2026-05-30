import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';
import 'app_colors.dart';

abstract class AppTextStyle {
  /// HeadLineText == 32 Size
  static Widget headlineText(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.headlineLarge?.copyWith(color: AppColors.textColor),
      textAlign: TextAlign.center,
    );
  }

  /// TitleLargeText == 22 Size
  static Widget titleLargeText(
    BuildContext context,
    String text, [
    Color? color,
  ]) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(color: color ?? AppColors.textColor),
    );
  }

  /// TitleMediumText == 20 Size
  static Widget titleMediumText(
    BuildContext context,
    String text, [
    Color? color,
  ]) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: color ?? AppColors.textColor,
        fontSize: 20,
      ),
    );
  }

  /// TitleSmallText == 16 Size
  static Widget titleSmallText(
    BuildContext context,
    String text, [
    Color? color,
  ]) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: color ?? AppColors.textColor,
        fontSize: 16,
      ),
    );
  }

  /// LabelMediumText == 12 Size
  static Widget labelMediumText(
    BuildContext context,
    String text, [
    Color? color,
  ]) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: AppColors.textColor),
      textAlign: TextAlign.center,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ QURAN STYLES — font Hafs dari quran_library (identik Mushaf Madinah)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Teks AYAT AL-QURAN — font Hafs utama
  /// Gunakan: style: AppTextStyle.quranVerseStyle()
  static TextStyle quranVerseStyle({
    double fontSize = 22,
    Color color = const Color(0xFF1A1008),
    double height = 2.2,
  }) {
    return QuranLibrary().hafsStyle.copyWith(
      fontSize: fontSize,
      height: height,
      color: color,
    );
  }

  /// Teks NAMA SURAH — font Hafs untuk nama surah
  static TextStyle quranSurahNameStyle({
    double fontSize = 20,
    Color color = const Color(0xFF3B2A1A),
  }) {
    return QuranLibrary().hafsStyle.copyWith(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.bold,
    );
  }

  /// Teks NOMOR AYAT — di dalam lingkaran emas
  static TextStyle quranVerseNumberStyle({
    double fontSize = 10,
    Color color = const Color(0xFF3B2A1A),
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
    Color color = const Color(0xFF3B2A1A),
  }) {
    return QuranLibrary().naskhStyle.copyWith(
      fontSize: fontSize,
      color: color.withValues(alpha: 0.8),
    );
  }
}
