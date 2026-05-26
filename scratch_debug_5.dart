import 'package:quran/quran.dart' as q;

void main() {
  String symbol = q.getVerseEndSymbol(41);
  print('Symbol: "$symbol"');
  print('Length: ${symbol.length}');
  print('Code points: ${symbol.runes.map((r) => r.toRadixString(16)).toList()}');
}
