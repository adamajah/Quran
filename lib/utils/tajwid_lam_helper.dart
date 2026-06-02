abstract final class TajwidLamHelper {
  static const lam = '\u0644';
  static const _articleAlifLetters = {
    '\u0627', // Alif
    '\u0623', // Alif hamzah atas
    '\u0625', // Alif hamzah bawah
    '\u0622', // Alif madda
    '\u0671', // Alif waslah
  };
  static const _qamariahLetters = {
    '\u0627', // Alif
    '\u0623', // Alif hamzah atas
    '\u0625', // Alif hamzah bawah
    '\u0622', // Alif madda
    '\u0628', // Ba
    '\u062C', // Jim
    '\u062D', // Ha tenggorokan
    '\u062E', // Kho
    '\u0639', // Ain
    '\u063A', // Ghain
    '\u0641', // Fa
    '\u0642', // Qaf
    '\u0643', // Kaf
    '\u0645', // Mim
    '\u0648', // Waw
    '\u0647', // Ha
    '\u064A', // Ya
  };
  static final _attachedMarkPattern = RegExp(
    r'[\u064B-\u065F\u0670\u06D6-\u06ED]',
  );

  static bool isLamQamariahAt(String text, int index) {
    if (index < 0 || index >= text.length || text[index] != lam) {
      return false;
    }

    final previousChar = _previousBaseChar(text, index - 1);
    if (previousChar == null || !_articleAlifLetters.contains(previousChar)) {
      return false;
    }

    final nextChar = _nextBaseChar(text, index + 1);
    return nextChar != null && _qamariahLetters.contains(nextChar);
  }

  static String? _previousBaseChar(String text, int index) {
    for (int i = index; i >= 0; i--) {
      final char = text[i];
      if (_isAttachedMark(char)) continue;
      return char;
    }
    return null;
  }

  static String? _nextBaseChar(String text, int index) {
    for (int i = index; i < text.length; i++) {
      final char = text[i];
      if (_isAttachedMark(char)) continue;
      return char;
    }
    return null;
  }

  static bool _isAttachedMark(String char) =>
      _attachedMarkPattern.hasMatch(char);
}
