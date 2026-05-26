import 'package:quran/quran.dart' as q;

void main() {
  int surah = 4;
  int verseNum = 3;
  String vText = q.getVerse(surah, verseNum, verseEndSymbol: true);
  
  print('Last 20 chars of An-Nisa 3:');
  for (int i = vText.length - 20; i < vText.length; i++) {
    if (i < 0) continue;
    print('Char $i: "${vText[i]}" (U+${vText.codeUnitAt(i).toRadixString(16)})');
  }
}
