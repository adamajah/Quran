import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'tajwid_mad_helper.dart';

class TajwidUtils {
  static const _sunLetters = 'تثدذرزسشصضطظلن';
  static const _idghamLetters = 'يرملون';
  static const _ikhfaLetters = 'تثجدذزسشصضطظفقك';
  static const _maddahAbove = '\u0653';
  static const _muqattaahAlphabet = 'المصركهيعطسحقن';
  static const _muqattaahTokens = {
    'الم',
    'المص',
    'الر',
    'المر',
    'كهيعص',
    'طه',
    'طسم',
    'طس',
    'يس',
    'ص',
    'حم',
    'عسق',
    'ق',
    'ن',
  };
  static const _twoHarakatMuqattaahLetters = 'حيطهر';
  static const _sixHarakatMuqattaahLetters = 'نقصسلكم';
  static final _attachedMarkPattern = RegExp(
    r'[\u064B-\u065F\u0670\u06D6-\u06ED]',
  );
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
    'ۥ',
    'ۦ',
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

  static bool _isAttachedMark(String char) =>
      _attachedMarkPattern.hasMatch(char);

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
      if (!_isAttachedMark(ch)) return false;
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

  static (Color, String, String)? _getMuqattaahMaddInfo(
    String text,
    int index,
  ) {
    int tokenEnd = 0;
    final tokenBuffer = StringBuffer();
    while (tokenEnd < text.length) {
      final char = text[tokenEnd];
      if (_muqattaahAlphabet.contains(char)) {
        tokenBuffer.write(char);
      } else if (char != _maddahAbove) {
        break;
      }
      tokenEnd++;
    }

    final token = tokenBuffer.toString();
    final hasTokenBoundary =
        tokenEnd == text.length ||
        text[tokenEnd].trim().isEmpty ||
        text[tokenEnd] == '۝';
    if (!hasTokenBoundary ||
        !_muqattaahTokens.contains(token) ||
        index >= tokenEnd) {
      return null;
    }

    final char =
        text[index] == _maddahAbove
            ? _prevMeaningfulChar(text, index - 1)
            : text[index];
    if (char == null) return null;

    final String description;
    if (_twoHarakatMuqattaahLetters.contains(char)) {
      description = "Huruf muqatta'ah $char dibaca panjang 2 harakat.";
    } else if (_sixHarakatMuqattaahLetters.contains(char)) {
      description =
          "Mad lazim harfi pada huruf muqatta'ah $char dibaca panjang 6 harakat.";
    } else if (char == 'ع') {
      description =
          "Huruf muqatta'ah ع dibaca panjang 4 atau 6 harakat sesuai riwayat bacaan.";
    } else {
      return null;
    }

    return (AppColors.tajwidColors['madHarfi']!, 'Mad Harfi', description);
  }

  static (Color, String, String)? _getAppliedMadInfo(String text, int index) {
    final rule = TajwidMadHelper.ruleForMaddahAt(text, index);
    return switch (rule) {
      TajwidMadRule.wajibMuttasil => (
        AppColors.tajwidColors['madWajibMuttasil']!,
        'Mad Wajib Muttasil',
        'Huruf mad bertemu hamzah dalam satu kata.',
      ),
      TajwidMadRule.jaizMunfasil => (
        AppColors.tajwidColors['madJaizMunfasil']!,
        'Mad Jaiz Munfasil',
        'Huruf mad di akhir kata bertemu hamzah pada awal kata berikutnya.',
      ),
      null => null,
    };
  }

  static (Color, String, String) getTajwidInfo(String text, int index) {
    final char = text[index];
    final nextMeaningfulChar = _nextMeaningfulChar(text, index + 1);
    final muqattaahMaddInfo = _getMuqattaahMaddInfo(text, index);

    if (muqattaahMaddInfo != null) return muqattaahMaddInfo;
    final appliedMadInfo = _getAppliedMadInfo(text, index);
    if (appliedMadInfo != null) return appliedMadInfo;

    // 1. Ghunnah: Nun/Mim Tasydid
    if ((char == 'ن' || char == 'م') && _hasMarkAhead(text, index, 'ّ')) {
      return (
        AppColors.tajwidColors['ghunnah']!,
        'Ghunnah',
        'Dengung 2 harakat pada nun/mim bertasydid.',
      );
    }

    // 2. Qalqalah: قطبجد (Sukun or end of verse)
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
    if (((char == 'ن' && _hasMarkAhead(text, index, 'ْ')) || _isTanwin(char)) &&
        nextMeaningfulChar != null &&
        'ب'.contains(nextMeaningfulChar)) {
      return (
        AppColors.tajwidColors['iqlab']!,
        'Iqlab',
        'Nun mati berubah menjadi suara mim samar.',
      );
    }

    // 4. Idgham: Nun followed by يرملون
    if (((char == 'ن' && _hasMarkAhead(text, index, 'ْ')) || _isTanwin(char)) &&
        nextMeaningfulChar != null &&
        _idghamLetters.contains(nextMeaningfulChar)) {
      return (
        AppColors.tajwidColors['idgham']!,
        'Idgham',
        'Melebur nun mati ke huruf berikutnya.',
      );
    }

    // 5. Ikhfa: Nun followed by 15 letters
    if (((char == 'ن' && _hasMarkAhead(text, index, 'ْ')) || _isTanwin(char)) &&
        nextMeaningfulChar != null &&
        _ikhfaLetters.contains(nextMeaningfulChar)) {
      return (
        AppColors.tajwidColors['ikhfa']!,
        'Ikhfa',
        'Menyamarkan suara nun mati.',
      );
    }

    // 6. Lam Syamsiyah: alif-lam assimilates into the next sun letter
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

    return (AppColors.tajwidColors['default']!, '', '');
  }

  static Color getTajwidColor(String text, int index) {
    return getTajwidInfo(text, index).$1;
  }
}
