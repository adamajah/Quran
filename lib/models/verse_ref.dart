// ─────────────────────────────────────────────────────────────────────────────
// Data Models  (extracted from home_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

class VerseRef {
  final int surah, verse;
  const VerseRef(this.surah, this.verse);
}

class BookmarkEntry {
  final int surah, verse, pageIdx;
  final String surahName, surahNameAr;
  const BookmarkEntry({
    required this.surah, required this.verse, required this.pageIdx,
    required this.surahName, required this.surahNameAr,
  });

  Map<String, dynamic> toJson() => {
    'surah': surah, 'verse': verse, 'pageIdx': pageIdx,
    'surahName': surahName, 'surahNameAr': surahNameAr,
  };
  factory BookmarkEntry.fromJson(Map<String, dynamic> m) => BookmarkEntry(
    surah: m['surah'], verse: m['verse'], pageIdx: m['pageIdx'],
    surahName: m['surahName'], surahNameAr: m['surahNameAr'],
  );
}

class PageData {
  final int pageNum, juz, surah;
  final String surahName, surahNameAr;
  final List<VerseRef> verses;
  final List<SurahGroup> groups;
  const PageData({
    required this.pageNum, required this.juz,
    required this.surah, required this.surahName, required this.surahNameAr,
    required this.verses, required this.groups,
  });
}

class SurahGroup {
  final int surah;
  final String surahNameAr;
  final bool isFirstInMushaf;
  final List<VerseRef> verses;
  const SurahGroup({
    required this.surah, required this.surahNameAr,
    required this.isFirstInMushaf, required this.verses,
  });
}
