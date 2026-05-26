import 'package:quran/quran.dart' as q;

void main() {
  int surah = 41;
  int verseNum = 41;
  String vText = q.getVerse(surah, verseNum, verseEndSymbol: false);
  
  print('Full text: "$vText"');
  for (int i = 0; i < vText.length; i++) {
    print('Char $i: "${vText[i]}" (U+${vText.codeUnitAt(i).toRadixString(16)})');
  }
}
