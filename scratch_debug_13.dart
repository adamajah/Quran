import 'package:quran/quran.dart' as q;

void main() {
  int surah = 4;
  int verseNum = 3;
  String vText = q.getVerse(surah, verseNum, verseEndSymbol: false);
  
  print('An-Nisa Verse 3 (false): "$vText"');
  for (int i = 0; i < vText.length; i++) {
    print('Char $i: "${vText[i]}" (U+${vText.codeUnitAt(i).toRadixString(16)})');
  }
}
