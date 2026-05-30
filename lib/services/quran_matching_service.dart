import 'dart:math' as math;

class QuranMatchingService {
  /// Comprehensive Arabic Text Normalization for AI Speech Matching
  static String normalizeArabic(String text) {
    if (text.isEmpty) return "";

    String cleaned = text;

    // 1. Remove Harakat / Tashkeel
    final harakat = RegExp(r'[\u064B-\u0652\u0670\u0653\u0654\u0655]');
    cleaned = cleaned.replaceAll(harakat, '');

    // 2. Normalize Alif
    cleaned = cleaned.replaceAll(RegExp(r'[\u0622\u0623\u0625]'), '\u0627');

    // 3. Normalize Ya and Alif Maqsura
    cleaned = cleaned.replaceAll('\u0649', '\u064A'); // Alif Maqsura -> Ya

    // 4. Normalize Ta Marbuta
    cleaned = cleaned.replaceAll('\u0629', '\u0647'); // Ta Marbuta -> Ha

    // 5. Normalize Hamza (optional, for even looser matching)
    cleaned = cleaned.replaceAll(
      '\u0621',
      '\u0627',
    ); // Isolated Hamza -> Alif (sometimes STT does this)

    // 6. Strip symbols, verse markers, and digits
    cleaned = cleaned.replaceAll(RegExp(r'[^\u0621-\u064A\s]'), '');

    // 7. Collapse whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    return cleaned.trim();
  }

  /// Calculate similarity between two words (0.0 to 1.0)
  static double getSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    int distance = _levenshteinDistance(s1, s2);
    int maxLen = math.max(s1.length, s2.length);

    // Weighted similarity: give more importance to the start of the word
    double baseScore = 1.0 - (distance / maxLen);

    // Prefix bonus (if first 2 chars match, it's more likely the same word in Arabic)
    double prefixBonus = 0.0;
    if (s1.length >= 2 &&
        s2.length >= 2 &&
        s1.substring(0, 2) == s2.substring(0, 2)) {
      prefixBonus = 0.1;
    }

    return (baseScore + prefixBonus).clamp(0.0, 1.0);
  }

  static int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = math.min(v1[j] + 1, math.min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }
}
