import 'package:quran/quran.dart' as q;

void main() {
  String v1 = q.getVerse(1, 1, verseEndSymbol: true);
  print('Verse 1: "$v1"');
  print('Bytes: ${v1.codeUnits}');
  
  List<String> words = v1.split(RegExp(r'\s+'));
  print('Words: $words');
  for (var w in words) {
    print('Word: "$w", Bytes: ${w.codeUnits}');
  }
}
