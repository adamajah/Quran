import 'package:quran/quran.dart' as q;

void main() {
  int surah = 7;
  int verseNum = 39;
  String vText = q.getVerse(surah, verseNum, verseEndSymbol: false);
  
  print('Text length: ${vText.length}');
  for (int i = vText.length - 10; i < vText.length; i++) {
    if (i < 0) continue;
    print('Char $i: "${vText[i]}" (U+${vText.codeUnitAt(i).toRadixString(16)})');
  }
}
