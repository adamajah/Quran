import 'package:quran/quran.dart' as q;

void main() {
  int surah = 41;
  int verseNum = 1;
  String vText = q.getVerse(surah, verseNum, verseEndSymbol: false);
  print('Surah $surah Verse $verseNum (false): "$vText"');
  print('Words: ${vText.split(' ')}');
  
  String vTextTrue = q.getVerse(surah, verseNum, verseEndSymbol: true);
  print('Surah $surah Verse $verseNum (true): "$vTextTrue"');
}
