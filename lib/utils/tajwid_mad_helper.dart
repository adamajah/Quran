enum TajwidMadRule { wajibMuttasil, jaizMunfasil }

abstract final class TajwidMadHelper {
  static const maddahAbove = '\u0653';
  static const _superscriptAlif = '\u0670';
  static const _smallWaw = '\u06E5';
  static const _smallYeh = '\u06E6';
  static const _hamzahLetters = 'ءأإؤئآ';
  static const _maddBlockingMarks = {
    'َ',
    'ِ',
    'ُ',
    'ً',
    'ٍ',
    'ٌ',
    'ْ',
    'ّ',
    'ٔ',
    'ٕ',
  };
  static final _attachedMarkPattern = RegExp(
    r'[\u064B-\u065F\u0670\u06D6-\u06ED]',
  );

  static String applyMadWajibAndJaizSigns(String text) {
    if (text.isEmpty) return text;

    final output = StringBuffer();
    for (int index = 0; index < text.length; index++) {
      output.write(text[index]);
      if (_ruleForCarrier(text, index) != null &&
          !_hasAttachedMaddah(text, index)) {
        output.write(maddahAbove);
      }
    }
    return output.toString();
  }

  static TajwidMadRule? ruleForMaddahAt(String text, int index) {
    if (index < 0 || index >= text.length || text[index] != maddahAbove) {
      return null;
    }
    final carrierIndex = _previousBaseCharIndex(text, index - 1);
    if (carrierIndex == null) return null;
    return _ruleForCarrier(text, carrierIndex);
  }

  static TajwidMadRule? _ruleForCarrier(String text, int index) {
    if (!_isMadCarrier(text, index)) return null;

    final nextIndex = _indexAfterAttachedMarks(text, index + 1);
    if (nextIndex < text.length && _isHamzah(text[nextIndex])) {
      return TajwidMadRule.wajibMuttasil;
    }

    if (nextIndex >= text.length || !_isInterWordSeparator(text[nextIndex])) {
      return null;
    }

    int nextWordIndex = nextIndex;
    while (nextWordIndex < text.length &&
        _isInterWordSeparator(text[nextWordIndex])) {
      nextWordIndex++;
    }
    if (nextWordIndex < text.length && _isHamzah(text[nextWordIndex])) {
      return TajwidMadRule.jaizMunfasil;
    }
    return null;
  }

  static bool _isMadCarrier(String text, int index) {
    if (index < 0 || index >= text.length) return false;

    final char = text[index];
    if (_isStandaloneMadSign(char)) return true;
    if (char != 'ا' && char != 'و' && char != 'ي' && char != 'ى') {
      return false;
    }
    if (char == 'ى' && _hasAttachedMark(text, index, _superscriptAlif)) {
      return false;
    }
    if (_hasMaddBlockingMark(text, index)) return false;

    final requiredVowel = switch (char) {
      'ا' || 'ى' => 'َ',
      'و' => 'ُ',
      'ي' => 'ِ',
      _ => '',
    };
    return _hasVowelBefore(text, index, requiredVowel);
  }

  static bool _hasVowelBefore(String text, int index, String vowel) {
    for (int i = index - 1; i >= 0; i--) {
      final char = text[i];
      if (char == vowel) return true;
      if (!_isAttachedMark(char)) return false;
    }
    return false;
  }

  static bool _hasMaddBlockingMark(String text, int index) {
    for (int i = index + 1; i < text.length; i++) {
      final char = text[i];
      if (_maddBlockingMarks.contains(char)) return true;
      if (!_isAttachedMark(char)) return false;
    }
    return false;
  }

  static bool _hasAttachedMaddah(String text, int index) {
    return _hasAttachedMark(text, index, maddahAbove);
  }

  static bool _hasAttachedMark(String text, int index, String mark) {
    for (int i = index + 1; i < text.length; i++) {
      final char = text[i];
      if (char == mark) return true;
      if (!_isAttachedMark(char)) return false;
    }
    return false;
  }

  static int _indexAfterAttachedMarks(String text, int index) {
    int current = index;
    while (current < text.length && _isAttachedMark(text[current])) {
      current++;
    }
    return current;
  }

  static int? _previousBaseCharIndex(String text, int index) {
    for (int i = index; i >= 0; i--) {
      if (_isStandaloneMadSign(text[i])) return i;
      if (!_isAttachedMark(text[i])) return i;
    }
    return null;
  }

  static bool _isHamzah(String char) => _hamzahLetters.contains(char);

  static bool _isStandaloneMadSign(String char) =>
      char == _superscriptAlif || char == _smallWaw || char == _smallYeh;

  static bool _isAttachedMark(String char) =>
      _attachedMarkPattern.hasMatch(char);

  static bool _isWhitespace(String char) => char.trim().isEmpty;

  static bool _isInterWordSeparator(String char) =>
      _isWhitespace(char) ||
      (char.codeUnitAt(0) >= 0x06D6 && char.codeUnitAt(0) <= 0x06ED);
}
