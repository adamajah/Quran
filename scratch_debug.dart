import 'package:quran/quran.dart' as q;

void main() {
  String verse = q.getVerse(1, 1, verseEndSymbol: false);
  print('Verse (false): "$verse"');
  print('Words: ${verse.split(' ')}');
  
  String verseTrue = q.getVerse(1, 1, verseEndSymbol: true);
  print('Verse (true): "$verseTrue"');
  print('Words: ${verseTrue.split(' ')}');
  
  print('End Symbol: ${q.getVerseEndSymbol(1)}');
}
