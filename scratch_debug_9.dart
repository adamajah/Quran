import 'package:quran/quran.dart' as q;

void main() {
  int surah = 7;
  int verseNum = 39;
  String vText = q.getVerse(surah, verseNum, verseEndSymbol: false);
  
  print('Al-A\'raf Verse 39 (false): "$vText"');
  for (int i = 0; i < vText.length; i++) {
    print('Char $i: "${vText[i]}" (U+${vText.codeUnitAt(i).toRadixString(16)})');
  }
}
