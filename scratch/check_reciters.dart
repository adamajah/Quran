import 'package:quran/quran.dart' as q;

void main() {
  // In many versions of the quran package, the reciter is a String identifier.
  // We can also check if there's a Reciter enum or similar.
  // Actually, quranPkg 1.x usually just accepts a String URL prefix or an ID.
  
  // Let's see what getAudioURLByVerse returns and if we can customize it.
  print("Default audio: ${q.getAudioURLByVerse(1, 1)}");
}
