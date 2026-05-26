import 'package:quran/quran.dart' as q;

void main() {
  String url = q.getAudioURLByVerse(1, 1);
  print(url);
}
