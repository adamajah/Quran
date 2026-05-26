import 'package:quran/quran.dart' as q;

void main() {
  int surah = 41;
  int verseNum = 41;
  String vText = q.getVerse(surah, verseNum, verseEndSymbol: false);
  
  print('Has symbol (U+06DD): ${vText.contains('\u06DD')}');
  print('Has digits (0-9): ${RegExp(r'[0-9]').hasMatch(vText)}');
  print('Has Arabic digits (٤١): ${vText.contains('٤') || vText.contains('١')}');
}
