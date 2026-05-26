import 'package:quran/quran.dart' as q;

void main() {
  int surah = 4;
  int verseNum = 3;
  String vText = q.getVerse(surah, verseNum, verseEndSymbol: true);
  
  print('An-Nisa Verse 3 (true): "$vText"');
  List<String> words = vText.split(' ').where((w) => w.trim().isNotEmpty).toList();
  print('Word count: ${words.length}');
  for (int i = 0; i < words.length; i++) {
    print('Word $i: "${words[i]}"');
  }
}
