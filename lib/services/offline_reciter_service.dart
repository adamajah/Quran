import 'package:dio/dio.dart';

import '../models/reciter.dart';

class AyahTiming {
  final int ayah;
  final Duration start;
  final Duration end;

  const AyahTiming({
    required this.ayah,
    required this.start,
    required this.end,
  });
}

class OfflineReciterService {
  static const _ayahTimingUrl = 'https://mp3quran.net/api/v3/ayat_timing';

  static final Map<String, Future<List<AyahTiming>>> _cachedAyahTimings = {};

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
    return availableReciters
        .where((reciter) => isPopularReciterName(reciter.name))
        .where((reciter) => reciter.supportsSurahDownload(surah))
        .toList(growable: false);
  }

  Future<Duration?> getAyahStartPosition(
    Reciter reciter,
    int surah,
    int ayah,
  ) async {
    final timings = await getAyahTimings(reciter, surah);
    for (final timing in timings) {
      if (timing.ayah == ayah) return timing.start;
    }
    return null;
  }

  Future<List<AyahTiming>> getAyahTimings(Reciter reciter, int surah) async {
    final readId = reciter.timingReadId;
    if (readId == null) return const [];

    final key = '$readId:$surah';
    final timings =
        _cachedAyahTimings[key] ??= _fetchAyahTimings(readId, surah);
    try {
      return await timings;
    } catch (_) {
      if (identical(_cachedAyahTimings[key], timings)) {
        _cachedAyahTimings.remove(key);
      }
      return const [];
    }
  }

  Future<List<AyahTiming>> _fetchAyahTimings(int readId, int surah) async {
    final response = await _dio.get<List<dynamic>>(
      _ayahTimingUrl,
      queryParameters: {'read': readId, 'surah': surah},
    );
    return parseAyahTimings(response.data ?? const []);
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
    for (final timing in parseAyahTimings(data)) {
      if (timing.ayah == ayah) return timing.start;
    }
    return null;
  }

  static List<AyahTiming> parseAyahTimings(List<dynamic> data) {
    final timings = <AyahTiming>[];
    for (final rawTiming in data) {
      final timing = rawTiming as Map<String, dynamic>;
      final ayah = timing['ayah'];
      final start = timing['start_time'];
      final end = timing['end_time'];
      if (ayah is int && ayah > 0 && start is num && end is num) {
        timings.add(
          AyahTiming(
            ayah: ayah,
            start: Duration(milliseconds: start.round()),
            end: Duration(milliseconds: end.round()),
          ),
        );
      }
    }
    return timings;
  }

  static int? findAyahForPosition(List<AyahTiming> timings, Duration position) {
    for (final timing in timings) {
      if (position >= timing.start && position < timing.end) {
        return timing.ayah;
      }
    }
    if (timings.isNotEmpty && position >= timings.last.start) {
      return timings.last.ayah;
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
      if (!isPopularReciterName(name)) continue;

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
