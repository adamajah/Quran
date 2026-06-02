import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as q;

import 'package:flutter_quran_app/utils/quran_page_index.dart';

void main() {
  group('QuranPageIndex.resolveSurahForPage', () {
    test('keeps a selected surah that starts on a shared page', () {
      final pages = QuranPageCatalog();
      final anNahlPage = pages[q.getPageNumber(16, 1) - 1];

      expect(anNahlPage.verses.first.surah, 15);
      expect(anNahlPage.verses.any((verse) => verse.surah == 16), isTrue);
      expect(
        QuranPageIndex.resolveSurahForPage(
          anNahlPage.verses,
          preferredSurah: 16,
        ),
        16,
      );
    });

    test('defaults to the first surah when no destination is requested', () {
      final pages = QuranPageCatalog();
      final anNahlPage = pages[q.getPageNumber(16, 1) - 1];

      expect(QuranPageIndex.resolveSurahForPage(anNahlPage.verses), 15);
    });
  });
}
