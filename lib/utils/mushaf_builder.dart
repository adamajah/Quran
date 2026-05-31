// ─────────────────────────────────────────────────────────────────────────────
// Mushaf Page Builder  (extracted from home_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:quran/quran.dart' as q;
import '../models/verse_ref.dart';
import 'quran_page_index.dart';

List<PageData> buildMushafPages() {
  final pageVerses = QuranPageIndex.pageVerseMap;
  final pages = <PageData>[];
  final pageNums = pageVerses.keys.toList()..sort();
  for (final pgNum in pageNums) {
    final verses = pageVerses[pgNum]!;
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
          surahNameAr: q.getSurahNameArabic(cur),
          isFirstInMushaf: grpVerses.first.verse == 1,
          verses: grpVerses,
        ),
      );
    }
    pages.add(
      PageData(
        pageNum: pgNum,
        juz: q.getJuzNumber(domSurah, verses.first.verse),
        surah: domSurah,
        surahName: q.getSurahName(domSurah),
        surahNameAr: q.getSurahNameArabic(domSurah),
        verses: verses,
        groups: groups,
      ),
    );
  }
  return pages;
}
