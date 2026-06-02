abstract final class TajwidIdzharHelper {
  static const nun = '\u0646';
  static const sukun = '\u0652';
  static const _halqiLetters = {
    '\u0621', // Hamzah
    '\u0627', // Alif
    '\u0623', // Alif hamzah atas
    '\u0625', // Alif hamzah bawah
    '\u0622', // Alif madda
    '\u0671', // Alif waslah
    '\u0647', // Ha
    '\u062D', // Ha tenggorokan
    '\u062E', // Kho
    '\u0639', // Ain
    '\u063A', // Ghain
  };
  static final _wordPattern = RegExp(r'\S+');
  static final _attachedMarkPattern = RegExp(
    r'[\u064B-\u065F\u0670\u06D6-\u06ED]',
  );
  static final _arabicLetterPattern = RegExp(
    r'[\u0621-\u063A\u0641-\u064A\u066E-\u066F\u0671-\u06D3\u06FA-\u06FC]',
  );

  static Set<int> detectIdzharHalqi(String text) {
    final matches = <int>{};

    for (final word in _wordPattern.allMatches(text)) {
      for (int index = word.start; index < word.end; index++) {
        if (isIdzharHalqiAt(text, index)) {
          matches.add(index);
        }
      }
    }
    return matches;
  }

  static bool isIdzharHalqiAt(String text, int index) {
    if (index < 0 || index >= text.length || text[index] != nun) {
      return false;
    }
    if (!_hasAttachedSukun(text, index)) return false;

    final nextLetter = _nextArabicLetter(text, index + 1);
    return nextLetter != null && _halqiLetters.contains(nextLetter);
  }

  static bool _hasAttachedSukun(String text, int index) {
    for (int i = index + 1; i < text.length; i++) {
      final char = text[i];
      if (char == sukun) return true;
      if (!_isAttachedMark(char)) return false;
    }
    return false;
  }

  static String? _nextArabicLetter(String text, int index) {
    for (int i = index; i < text.length; i++) {
      final char = text[i];
      if (_isAttachedMark(char)) continue;
      if (_arabicLetterPattern.hasMatch(char)) return char;
    }
    return null;
  }

  static bool _isAttachedMark(String char) =>
      _attachedMarkPattern.hasMatch(char);
}
