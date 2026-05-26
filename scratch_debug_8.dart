import 'package:quran/quran.dart' as q;

void main() {
  String symbol = q.getVerseEndSymbol(9);
  print('Symbol: "$symbol"');
  for (int i = 0; i < symbol.length; i++) {
    print('Char $i: "${symbol[i]}" (U+${symbol.codeUnitAt(i).toRadixString(16)})');
  }
}
