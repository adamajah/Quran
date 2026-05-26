import 'package:quran/quran.dart' as q;

void main() {
  // In some versions, you might need to build the URL manually if getAudioURLByVerse doesn't support reciters.
  // Let's check the parameters of getAudioURLByVerse.
  // For now, I'll just see if I can pass a string as a third param.
  
  try {
    // print(q.getAudioURLByVerse(1, 1, reciter: 'ar.shaatree')); // If it exists
  } catch(e) {}
}
