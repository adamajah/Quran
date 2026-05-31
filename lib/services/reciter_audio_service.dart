import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:quran/quran.dart' as quran_pkg;

import '../models/reciter.dart';

class ReciterAudioService {
  ReciterAudioService._();

  static final instance = ReciterAudioService._();

  final Dio _dio = Dio();
  final Map<String, Future<_SurahAudioCatalog>> _surahCatalogCache = {};

  Future<String> verseAudioUrl(Reciter reciter, int surah, int verse) async {
    final catalog = await _loadSurahCatalog(reciter, surah);
    final url = catalog.urlForVerse(verse);
    if (url != null && url.isNotEmpty) return url;
    return _fallbackVerseUrl(reciter, surah, verse);
  }

  Future<_SurahAudioCatalog> _loadSurahCatalog(Reciter reciter, int surah) {
    final key = '${reciter.id}:$surah';
    return _surahCatalogCache[key] ??=
        _fetchSurahCatalog(reciter, surah).catchError((_) {
          _surahCatalogCache.remove(key);
          return _SurahAudioCatalog.empty();
        });
  }

  Future<_SurahAudioCatalog> _fetchSurahCatalog(Reciter reciter, int surah) async {
    final response = await _dio.get<String>(
      'https://api.alquran.cloud/v1/surah/$surah/${reciter.id}',
      options: Options(responseType: ResponseType.plain),
    );

    final raw = response.data;
    if (raw == null || raw.isEmpty) return _SurahAudioCatalog.empty();

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    final ayahs = data?['ayahs'] as List<dynamic>? ?? const [];

    final urls = <int, String>{};
    for (final rawAyah in ayahs) {
      final ayah = rawAyah as Map<String, dynamic>;
      final verse = ayah['numberInSurah'];
      final audio = ayah['audio'];
      String? chosen;
      if (audio is String && audio.isNotEmpty) {
        chosen = audio;
      } else {
        final secondary = ayah['audioSecondary'] as List<dynamic>? ?? const [];
        for (final item in secondary) {
          if (item is String && item.isNotEmpty) {
            chosen = item;
            break;
          }
        }
      }

      if (verse is int && chosen != null && chosen.isNotEmpty) {
        urls[verse] = chosen;
      }
    }

    return _SurahAudioCatalog(urls);
  }

  String _fallbackVerseUrl(Reciter reciter, int surah, int verse) {
    int globalVerse = 0;
    for (int s = 1; s < surah; s++) {
      globalVerse += quran_pkg.getVerseCount(s);
    }
    globalVerse += verse;

    return 'https://cdn.islamic.network/quran/audio/${reciter.bitrate}/${reciter.id}/$globalVerse.mp3';
  }
}

class _SurahAudioCatalog {
  final Map<int, String> _urls;

  const _SurahAudioCatalog(this._urls);

  factory _SurahAudioCatalog.empty() => const _SurahAudioCatalog({});

  String? urlForVerse(int verse) => _urls[verse];
}
