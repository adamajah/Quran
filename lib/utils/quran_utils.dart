import 'package:quran/quran.dart' as q;

class QuranUtils {
  static const _muqattaahDisplayForms = {
    'الم': 'ال\u0653م\u0653',
    'المص': 'ال\u0653م\u0653ص\u0653',
    'الر': 'ال\u0653ر',
    'المر': 'ال\u0653م\u0653ر',
    'كهيعص': 'ك\u0653هيع\u0653ص\u0653',
    'طه': 'طه',
    'طسم': 'طس\u0653م\u0653',
    'طس': 'طس\u0653',
    'يس': 'يس\u0653',
    'ص': 'ص\u0653',
    'حم': 'حم\u0653',
    'عسق': 'ع\u0653س\u0653ق\u0653',
    'ق': 'ق\u0653',
    'ن': 'ن\u0653',
  };

  /// Returns the verse text without the Bismillah prefix for surahs other than Al-Fatihah.
  static String getCleanVerse(
    int surah,
    int verse, {
    bool verseEndSymbol = false,
  }) {
    String text = q.getVerse(surah, verse, verseEndSymbol: verseEndSymbol);

    // Al-Fatihah (1) should keep its Bismillah as it's the first verse.
    // At-Tawbah (9) doesn't have Bismillah.
    if (surah != 1 && verse == 1 && surah != 9) {
      String bismillah = q.getVerse(1, 1, verseEndSymbol: false);
      if (text.startsWith(bismillah)) {
        text = text.replaceFirst(bismillah, "").trim();
      }
    }
    return _addMuqattaahDisplayMarks(text);
  }

  /// Removes Bismillah prefix from a string if it exists.
  static String cleanText(String text) {
    String bismillah = q.getVerse(1, 1, verseEndSymbol: false);
    if (text.startsWith(bismillah)) {
      // Check if it's ONLY Bismillah (could be Surah 1, Verse 1)
      // If it's longer than Bismillah, it's definitely a prefix.
      if (text.trim() != bismillah.trim()) {
        return _addMuqattaahDisplayMarks(
          text.replaceFirst(bismillah, "").trim(),
        );
      }
    }
    return _addMuqattaahDisplayMarks(text);
  }

  static String _addMuqattaahDisplayMarks(String text) {
    for (final entry in _muqattaahDisplayForms.entries) {
      final token = entry.key;
      if (text == token ||
          text.startsWith('$token ') ||
          text.startsWith('$token۝')) {
        return '${entry.value}${text.substring(token.length)}';
      }
    }
    return text;
  }
}
