// ─────────────────────────────────────────────────────────────────────────────
// Tajwid Utilities  (extracted from home_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';
import '../constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tajwid Color Map  (rule-name → color)
// PERUBAHAN: lam_shamsiah diubah dari cyan (#18FFFF) ke ungu (#B388FF)
// agar tidak mirip dengan idgham (#00CFFF)
// ─────────────────────────────────────────────────────────────────────────────
const tajwidColors = <String, Color>{
  'ghunnah'      : Color(0xFFFF6B00),  // oranye terang  – dengung
  'idgham'       : Color(0xFF00CFFF),  // biru langit    – lebur
  'ikhfa'        : Color(0xFFE040FB),  // magenta        – samar
  'iqlab'        : Color(0xFFFF1744),  // merah terang   – ganti nun→mim
  'qalqalah'     : Color(0xFFFFD600),  // kuning emas    – memantul
  'madd'         : Color(0xFF00E676),  // hijau neon     – panjang
  'lam_shamsiah' : Color(0xFFB388FF),  // ungu/violet    – lebur lam (DIUBAH dari #18FFFF)
  'default'      : AppColors.ink,
};

// ─────────────────────────────────────────────────────────────────────────────
// PERUBAHAN: Fungsi tajwidColor diperbaiki total.
// Sebelumnya: 'اوي' selalu berwarna hijau → hampir semua teks jadi hijau/biru.
// Sekarang: default hitam (_ink), hanya huruf dengan konteks tajwid yang jelas
// yang diberi warna. Mad hanya ditandai jika وي diikuti sukun (ْ).
// ─────────────────────────────────────────────────────────────────────────────
Color tajwidColor(String char, String? nextChar) {
  // Qalqalah: huruf قطبجد saat diikuti spasi atau akhir kata (posisi sukun/waqaf)
  const qalqalah = 'قطبجد';
  if (qalqalah.contains(char) &&
      (nextChar == null || nextChar == ' ' || nextChar == '\n')) {
    return tajwidColors['qalqalah']!;
  }

  // Ghunnah: nun atau mim diikuti tasydid (ّ)
  if ((char == 'ن' || char == 'م') && nextChar == 'ّ') {
    return tajwidColors['ghunnah']!;
  }

  // Iqlab: nun diikuti ba (ب) → nun berubah menjadi mim samar
  if (char == 'ن' && nextChar == 'ب') {
    return tajwidColors['iqlab']!;
  }

  // Idgham: nun diikuti يرملون → nun lebur
  const idghamLetters = 'يرملون';
  if (char == 'ن' && nextChar != null && idghamLetters.contains(nextChar)) {
    return tajwidColors['idgham']!;
  }

  // Ikhfa: nun diikuti 15 huruf ikhfa → dibaca samar
  const ikhfaLetters = 'تثجدذزسشصضطظفقك';
  if (char == 'ن' && nextChar != null && ikhfaLetters.contains(nextChar)) {
    return tajwidColors['ikhfa']!;
  }

  // Madd: HANYA waw (و) atau ya (ي) yang diikuti sukun (ْ) → mad
  // Alif (ا) tidak diberi warna agar teks tidak banjir warna hijau
  if ('وي'.contains(char) && nextChar == 'ْ') {
    return tajwidColors['madd']!;
  }

  // Default: warna tinta normal (hitam)
  return tajwidColors['default']!;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tajwid-colored RichText builder
// ─────────────────────────────────────────────────────────────────────────────
List<InlineSpan> buildTajwidSpans(
    String text, double fontSize, double height, bool active, bool showTajwid) {
  if (!showTajwid) {
    return [TextSpan(
      text: text,
      style: QuranLibrary().hafsStyle.copyWith(
        fontSize: fontSize, height: height,
        color: active ? AppColors.hl : AppColors.ink,
        backgroundColor: active ? AppColors.hl.withOpacity(0.06) : null,
      ),
    )];
  }
  final spans = <InlineSpan>[];
  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    final nextChar = i + 1 < text.length ? text[i + 1] : null;
    final color = active ? AppColors.hl : tajwidColor(char, nextChar);
    spans.add(TextSpan(
      text: char,
      style: QuranLibrary().hafsStyle.copyWith(
        fontSize: fontSize, height: height, color: color,
        backgroundColor: active ? AppColors.hl.withOpacity(0.06) : null,
      ),
    ));
  }
  return spans;
}
