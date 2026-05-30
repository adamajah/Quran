import 'package:quran/quran.dart' as q;

class QuranUtils {
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
    return text;
  }

  /// Removes Bismillah prefix from a string if it exists.
  static String cleanText(String text) {
    String bismillah = q.getVerse(1, 1, verseEndSymbol: false);
    if (text.startsWith(bismillah)) {
      // Check if it's ONLY Bismillah (could be Surah 1, Verse 1)
      // If it's longer than Bismillah, it's definitely a prefix.
      if (text.trim() != bismillah.trim()) {
        return text.replaceFirst(bismillah, "").trim();
      }
    }
    return text;
  }
}
