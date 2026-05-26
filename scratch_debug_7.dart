import 'package:quran/quran.dart' as q;

void main() {
  int surah = 6;
  int verseNum = 9;
  String vText = q.getVerse(surah, verseNum, verseEndSymbol: false);
  
  print('Al-An\'am Verse 9 (false): "$vText"');
  for (int i = 0; i < vText.length; i++) {
    print('Char $i: "${vText[i]}" (U+${vText.codeUnitAt(i).toRadixString(16)})');
  }
}
