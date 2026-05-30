import 'package:quran/quran.dart' as q;

class AudioUtils {
  static String getVerseAudioUrl(
    int surah,
    int verse,
    String reciterId,
    int bitrate,
  ) {
    // pattern: https://cdn.islamic.network/quran/audio/{bitrate}/{reciterId}/{globalVerse}.mp3

    int globalVerse = 0;
    for (int s = 1; s < surah; s++) {
      globalVerse += q.getVerseCount(s);
    }
    globalVerse += verse;

    return "https://cdn.islamic.network/quran/audio/$bitrate/$reciterId/$globalVerse.mp3";
  }
}
