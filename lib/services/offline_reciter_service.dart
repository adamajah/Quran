import 'package:dio/dio.dart';

import '../models/reciter.dart';

class OfflineReciterService {
  static const _catalogUrl =
      'https://www.mp3quran.net/api/v3/reciters?language=eng';
  static const _timingReadsUrl =
      'https://mp3quran.net/api/v3/ayat_timing/reads';
  static const _ayahTimingUrl = 'https://mp3quran.net/api/v3/ayat_timing';

  static Future<List<Reciter>>? _cachedReciters;
  static final Map<String, Future<Duration?>> _cachedAyahPositions = {};

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
    try {
      final timings = await _dio.get<List<dynamic>>(_timingReadsUrl);
      return parseCatalog(
        response.data ?? const {},
        timingReadIds: parseTimingReadIds(timings.data ?? const []),
      );
    } catch (_) {
      return parseCatalog(response.data ?? const {});
    }
  }

  Future<Duration?> getAyahStartPosition(
    Reciter reciter,
    int surah,
    int ayah,
  ) async {
    final readId = reciter.timingReadId;
    if (readId == null) return null;

    final key = '$readId:$surah:$ayah';
    final position =
        _cachedAyahPositions[key] ??= _fetchAyahStartPosition(
          readId,
          surah,
          ayah,
        );
    try {
      return await position;
    } catch (_) {
      if (identical(_cachedAyahPositions[key], position)) {
        _cachedAyahPositions.remove(key);
      }
      return null;
    }
  }

  Future<Duration?> _fetchAyahStartPosition(
    int readId,
    int surah,
    int ayah,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      _ayahTimingUrl,
      queryParameters: {'read': readId, 'surah': surah},
    );
    return parseAyahStartPosition(response.data ?? const [], ayah);
  }

  static Map<String, int> parseTimingReadIds(List<dynamic> data) {
    final readIds = <String, int>{};
    for (final rawRead in data) {
      final read = rawRead as Map<String, dynamic>;
      final id = read['id'];
      final server = read['folder_url'] as String?;
      if (id is int && server != null && server.isNotEmpty) {
        readIds[_normalizeServer(server)] = id;
      }
    }
    return readIds;
  }

  static Duration? parseAyahStartPosition(List<dynamic> data, int ayah) {
    for (final rawTiming in data) {
      final timing = rawTiming as Map<String, dynamic>;
      if (timing['ayah'] == ayah && timing['start_time'] is num) {
        return Duration(milliseconds: (timing['start_time'] as num).round());
      }
    }
    return null;
  }

  static List<Reciter> parseCatalog(
    Map<String, dynamic> data, {
    Map<String, int> timingReadIds = const {},
  }) {
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
            timingReadId: timingReadIds[_normalizeServer(server)],
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

  static String _normalizeServer(String server) {
    final uri = Uri.tryParse(server.trim());
    if (uri == null || uri.host.isEmpty) return server.trim();
    final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
    return '${uri.host.toLowerCase()}$path';
  }
}
