import 'package:quran/quran.dart' as q;
import '../lib/models/verse_ref.dart';
import '../lib/utils/mushaf_builder.dart';

void main() {
  final pages = buildMushafPages();
  print('Total pages built: ${pages.length}');
  if (pages.isNotEmpty) {
    print('First page: ${pages.first.pageNum}, Surah: ${pages.first.surahName}');
    print('Last page: ${pages.last.pageNum}, Surah: ${pages.last.surahName}');
  }
}
