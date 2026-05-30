import 'package:dio/dio.dart';

import '../models/reciter.dart';

class OfflineReciterService {
  static const _catalogUrl =
      'https://www.mp3quran.net/api/v3/reciters?language=eng';

  static Future<List<Reciter>>? _cachedReciters;

  final Dio _dio;

  OfflineReciterService({Dio? dio}) : _dio = dio ?? Dio();

  Future<Reciter?> findReciterForSurah(String id, int surah) async {
    for (final reciter in availableReciters) {
      if (reciter.id == id) return reciter;
    }

    final reciters = await getRecitersForSurah(surah);
    for (final reciter in reciters) {
      if (reciter.id == id) return reciter;
    }
    return null;
  }

  Future<List<Reciter>> getRecitersForSurah(int surah) async {
    final catalog = _cachedReciters ??= _fetchReciters();
    try {
      final reciters = (await catalog)
          .where((reciter) => reciter.supportsSurahDownload(surah))
          .toList(growable: false);
      if (reciters.isNotEmpty) return reciters;
    } catch (_) {
      if (identical(_cachedReciters, catalog)) _cachedReciters = null;
    }

    return offlineReciters
        .where((reciter) => reciter.supportsSurahDownload(surah))
        .toList(growable: false);
  }

  Future<List<Reciter>> _fetchReciters() async {
    final response = await _dio.get<Map<String, dynamic>>(_catalogUrl);
    return parseCatalog(response.data ?? const {});
  }

  static List<Reciter> parseCatalog(Map<String, dynamic> data) {
    final reciters = <Reciter>[];
    for (final rawReciter in data['reciters'] as List<dynamic>? ?? const []) {
      final reciter = rawReciter as Map<String, dynamic>;
      final name = reciter['name'] as String?;
      final collections = reciter['moshaf'] as List<dynamic>? ?? const [];
      if (name == null || name.isEmpty) continue;

      for (final rawCollection in collections) {
        final collection = rawCollection as Map<String, dynamic>;
        final server = collection['server'] as String?;
        final surahList = collection['surah_list'] as String?;
        final collectionId = collection['id'];
        if (server == null ||
            server.isEmpty ||
            surahList == null ||
            surahList.isEmpty ||
            collectionId == null) {
          continue;
        }

        final surahs =
            surahList.split(',').map(int.tryParse).whereType<int>().toSet();
        if (surahs.isEmpty) continue;

        reciters.add(
          Reciter(
            name: name,
            id: 'mp3quran.$collectionId',
            surahAudioBitrate: 128,
            surahAudioBaseUrl: server,
            downloadableSurahs: surahs,
            collectionName: collection['name'] as String?,
          ),
        );
      }
    }

    reciters.sort((a, b) {
      final nameComparison = a.name.compareTo(b.name);
      if (nameComparison != 0) return nameComparison;
      return (a.collectionName ?? '').compareTo(b.collectionName ?? '');
    });
    return reciters;
  }
}
