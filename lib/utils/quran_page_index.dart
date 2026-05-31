import 'package:quran/quran.dart' as quran;

import '../models/verse_ref.dart';

class QuranPageIndex {
  static Map<int, List<VerseRef>>? _pageVerseMap;
  static final Map<String, List<Map<String, dynamic>>> _translationCache = {};

  static Map<int, List<VerseRef>> get pageVerseMap {
    _ensureBuilt();
    return _pageVerseMap!;
  }

  static List<VerseRef> versesForPage(int pageNum) {
    return pageVerseMap[pageNum] ?? const <VerseRef>[];
  }

  static List<Map<String, dynamic>> translationsForPage(
    int pageNum,
    quran.Translation translation,
  ) {
    final key = '${translation.name}|$pageNum';
    return _translationCache.putIfAbsent(key, () {
      return List<Map<String, dynamic>>.unmodifiable(
        versesForPage(pageNum).map(
          (v) => {
            'surah': v.surah,
            'verse': v.verse,
            'text': quran.getVerseTranslation(
              v.surah,
              v.verse,
              translation: translation,
            ),
          } as Map<String, dynamic>,
        ),
      );
    });
  }

  static void _ensureBuilt() {
    if (_pageVerseMap != null) return;

    final map = <int, List<VerseRef>>{};
    for (int s = 1; s <= quran.totalSurahCount; s++) {
      final verseCount = quran.getVerseCount(s);
      for (int v = 1; v <= verseCount; v++) {
        final pageNum = quran.getPageNumber(s, v);
        map.putIfAbsent(pageNum, () => <VerseRef>[]).add(VerseRef(s, v));
      }
    }
    _pageVerseMap = map;
  }
}
