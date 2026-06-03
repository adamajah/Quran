import 'dart:collection';

import 'package:quran/quran.dart' as quran;

import '../models/verse_ref.dart';

class QuranPageCatalog extends ListBase<PageData> {
  static const int totalPages = 604;
  final Map<int, PageData> _cache = {};

  @override
  int get length => totalPages;

  @override
  set length(int newLength) {
    throw UnsupportedError('QuranPageCatalog has a fixed length');
  }

  @override
  PageData operator [](int index) {
    if (index < 0 || index >= totalPages) {
      throw RangeError.index(index, this);
    }
    return _cache.putIfAbsent(index, () => _buildPage(index + 1));
  }

  @override
  void operator []=(int index, PageData value) {
    throw UnsupportedError('QuranPageCatalog is read-only');
  }

  PageData _buildPage(int pageNum) {
    final verses = QuranPageIndex.versesForPage(pageNum);

    final domSurah = verses.first.surah;
    final groups = <SurahGroup>[];
    int i = 0;
    while (i < verses.length) {
      final cur = verses[i].surah;
      final grpVerses = <VerseRef>[];
      while (i < verses.length && verses[i].surah == cur) {
        grpVerses.add(verses[i]);
        i++;
      }
      groups.add(
        SurahGroup(
          surah: cur,
          surahNameAr: quran.getSurahNameArabic(cur),
          isFirstInMushaf: grpVerses.first.verse == 1,
          verses: grpVerses,
        ),
      );
    }

    return PageData(
      pageNum: pageNum,
      juz: quran.getJuzNumber(domSurah, verses.first.verse),
      surah: domSurah,
      surahName: quran.getSurahName(domSurah),
      surahNameAr: quran.getSurahNameArabic(domSurah),
      verses: verses,
      groups: groups,
    );
  }
}

class QuranPageIndex {
  static Map<int, List<VerseRef>>? _pageVerseMap;
  static final Map<String, List<Map<String, dynamic>>> _translationCache = {};

  static int resolveSurahForPage(List<VerseRef> verses, {int? preferredSurah}) {
    if (verses.isEmpty) {
      throw ArgumentError.value(verses, 'verses', 'Page must contain verses');
    }
    if (preferredSurah != null &&
        verses.any((verse) => verse.surah == preferredSurah)) {
      return preferredSurah;
    }
    return verses.first.surah;
  }

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
          (v) =>
              {
                    'surah': v.surah,
                    'verse': v.verse,
                    'text': quran.getVerseTranslation(
                      v.surah,
                      v.verse,
                      translation: translation,
                    ),
                  }
                  as Map<String, dynamic>,
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
