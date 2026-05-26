import 'package:quran/quran.dart' as q;

void main() {
  int surah = 41;
  int verseNum = 41;
  String vText = q.getVerse(surah, verseNum, verseEndSymbol: false);
  print('Surah $surah Verse $verseNum (false): "$vText"');
  
  String vTextTrue = q.getVerse(surah, verseNum, verseEndSymbol: true);
  print('Surah $surah Verse $verseNum (true): "$vTextTrue"');
}
