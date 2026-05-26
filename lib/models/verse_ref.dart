// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

class VerseRef {
  final int surah, verse;
  const VerseRef(this.surah, this.verse);
}

class BookmarkEntry {
  final int surah, verse, pageIdx;
  final String surahName, surahNameAr;
  final String? translation; // New field
  final String? note;
  final String folder;
  final bool isFavorite;
  final int? highlightColor;
  final DateTime timestamp;

  const BookmarkEntry({
    required this.surah,
    required this.verse,
    required this.pageIdx,
    required this.surahName,
    required this.surahNameAr,
    this.translation,
    this.note,
    this.folder = 'Umum',
    this.isFavorite = false,
    this.highlightColor,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'surah': surah,
    'verse': verse,
    'pageIdx': pageIdx,
    'surahName': surahName,
    'surahNameAr': surahNameAr,
    'translation': translation,
    'note': note,
    'folder': folder,
    'isFavorite': isFavorite,
    'highlightColor': highlightColor,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BookmarkEntry.fromJson(Map<String, dynamic> m) => BookmarkEntry(
    surah: m['surah'],
    verse: m['verse'],
    pageIdx: m['pageIdx'],
    surahName: m['surahName'],
    surahNameAr: m['surahNameAr'],
    translation: m['translation'],
    note: m['note'],
    folder: m['folder'] ?? 'Umum',
    isFavorite: m['isFavorite'] ?? false,
    highlightColor: m['highlightColor'],
    timestamp: DateTime.tryParse(m['timestamp'] ?? '') ?? DateTime.now(),
  );

  BookmarkEntry copyWith({
    String? note,
    String? folder,
    bool? isFavorite,
    int? highlightColor,
    String? translation,
  }) => BookmarkEntry(
    surah: surah,
    verse: verse,
    pageIdx: pageIdx,
    surahName: surahName,
    surahNameAr: surahNameAr,
    translation: translation ?? this.translation,
    note: note ?? this.note,
    folder: folder ?? this.folder,
    isFavorite: isFavorite ?? this.isFavorite,
    highlightColor: highlightColor ?? this.highlightColor,
    timestamp: timestamp,
  );
}

class BookmarkFolder {
  final String name;
  final String icon; 
  final int count;
  final int color; // Added color
  const BookmarkFolder({required this.name, required this.icon, this.count = 0, this.color = 0xFFA07848});
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
