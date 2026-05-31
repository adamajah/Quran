import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TajwidUtils {
  static const _sunLetters = 'تثدذرزسشصضطظلن';
  static const _idghamLetters = 'يرملون';
  static const _ikhfaLetters = 'تثجدذزسشصضطظفقك';
  static const _maddSigns = 'آٰٓۦۧ';
  static const _ignorableChars = {
    'َ',
    'ِ',
    'ُ',
    'ً',
    'ٍ',
    'ٌ',
    'ْ',
    'ّ',
    'ٰ',
    'ٓ',
    'ٔ',
    'ٕ',
    'ۖ',
    'ۗ',
    'ۘ',
    'ۙ',
    'ۚ',
    'ۛ',
    'ۜ',
    '۟',
    '۠',
    'ۡ',
    'ۢ',
    'ۣ',
    'ۤ',
    'ۧ',
    'ۨ',
    '۪',
    '۫',
    '۬',
    'ۭ',
    'ـ',
    ' ',
    '\n',
    '\r',
    '\t',
    '،',
    '؛',
    '؟',
    '.',
    ',',
    '!',
  };

  static bool _isIgnorable(String char) => _ignorableChars.contains(char);

  static bool _isTanwin(String char) =>
      char == 'ً' || char == 'ٍ' || char == 'ٌ';

  static String? _nextMeaningfulChar(String text, int startIndex) {
    for (int i = startIndex; i < text.length; i++) {
      final ch = text[i];
      if (_isIgnorable(ch)) continue;
      return ch;
    }
    return null;
  }

  static bool _hasMarkAhead(String text, int index, String mark) {
    for (int i = index + 1; i < text.length; i++) {
      final ch = text[i];
      if (ch == mark) return true;
      if (!_isIgnorable(ch)) return false;
    }
    return false;
  }

  static bool _hasShortVowelBefore(String text, int index, String vowel) {
    for (int i = index - 1; i >= 0; i--) {
      final ch = text[i];
      if (ch == vowel) return true;
      if (!_isIgnorable(ch)) return false;
    }
    return false;
  }

  static String? _prevMeaningfulChar(String text, int index) {
    for (int i = index; i >= 0; i--) {
      final ch = text[i];
      if (_isIgnorable(ch)) continue;
      return ch;
    }
    return null;
  }

  static (Color, String, String) getTajwidInfo(String text, int index) {
    final char = text[index];
    final nextMeaningfulChar = _nextMeaningfulChar(text, index + 1);

    // 1. Ghunnah: Nun/Mim Tasydid
    if ((char == 'ن' || char == 'م') && _hasMarkAhead(text, index, 'ّ')) {
      return (
        AppColors.tajwidColors['ghunnah']!,
        'Ghunnah',
        'Dengung 2 harakat pada nun/mim bertasydid.',
      );
    }

    // 2. Qalqalah: قطبجد (Sukun or end of word)
    const qalqalah = 'قطبجد';
    if (qalqalah.contains(char)) {
      if (_hasMarkAhead(text, index, 'ْ') || nextMeaningfulChar == null) {
        return (
          AppColors.tajwidColors['qalqalah']!,
          'Qalqalah',
          'Pantulan suara pada huruf mati.',
        );
      }
    }

    // 3. Iqlab: Nun followed by Ba
    if ((char == 'ن' || _isTanwin(char)) &&
        nextMeaningfulChar != null &&
        'ب'.contains(nextMeaningfulChar)) {
      return (
        AppColors.tajwidColors['iqlab']!,
        'Iqlab',
        'Nun mati berubah menjadi suara mim samar.',
      );
    }

    // 4. Idgham: Nun followed by يرملون
    if ((char == 'ن' || _isTanwin(char)) &&
        nextMeaningfulChar != null &&
        _idghamLetters.contains(nextMeaningfulChar)) {
      return (
        AppColors.tajwidColors['idgham']!,
        'Idgham',
        'Melebur nun mati ke huruf berikutnya.',
      );
    }

    // 5. Ikhfa: Nun followed by 15 letters
    if ((char == 'ن' || _isTanwin(char)) &&
        nextMeaningfulChar != null &&
        _ikhfaLetters.contains(nextMeaningfulChar)) {
      return (
        AppColors.tajwidColors['ikhfa']!,
        'Ikhfa',
        'Menyamarkan suara nun mati.',
      );
    }

    // 6. Madd: Mad signs or vowel prolongations
    if (_maddSigns.contains(char) ||
        (char == 'ا' && _hasShortVowelBefore(text, index, 'َ')) ||
        (char == 'و' && _hasShortVowelBefore(text, index, 'ُ')) ||
        (char == 'ي' && _hasShortVowelBefore(text, index, 'ِ')) ||
        (char == 'ى' && _hasShortVowelBefore(text, index, 'َ'))) {
      return (
        AppColors.tajwidColors['madd']!,
        'Mad',
        'Pemanjangan suara huruf mad.',
      );
    }

    // 7. Lam Syamsiyah: alif-lam assimilates into the next sun letter
    if (char == 'ل' &&
        nextMeaningfulChar != null &&
        _sunLetters.contains(nextMeaningfulChar) &&
        (_prevMeaningfulChar(text, index - 1) == 'ا' ||
            _prevMeaningfulChar(text, index - 1) == 'ٱ')) {
      return (
        AppColors.tajwidColors['lamSyamsiyah']!,
        'Lam Syamsiyah',
        'Lam pada ال melebur ke huruf syamsiyah berikutnya.',
      );
    }

    // 8. Lam Tafkhim: Allah name marks (approximation)
    // Common marks used in Allah name for Tafkhim
    if (char == 'ـ' || (char == 'ّ' && nextMeaningfulChar == 'ٰ')) {
      // This often appears in the name of Allah
      return (
        AppColors.tajwidColors['tafkhim']!,
        'Tafkhim',
        'Penebalan bunyi pada lafadz Allah.',
      );
    }

    return (AppColors.tajwidColors['default']!, '', '');
  }

  static Color getTajwidColor(String text, int index) {
    return getTajwidInfo(text, index).$1;
  }
}
