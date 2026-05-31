class Reciter {
  final String name;
  final String id;
  final int bitrate;
  final String? surahAudioId;
  final int? surahAudioBitrate;
  final String? surahAudioBaseUrl;
  final Set<int>? downloadableSurahs;
  final String? collectionName;
  final int? timingReadId;

  const Reciter({
    required this.name,
    required this.id,
    this.bitrate = 128,
    this.surahAudioId,
    this.surahAudioBitrate,
    this.surahAudioBaseUrl,
    this.downloadableSurahs,
    this.collectionName,
    this.timingReadId,
  });

  bool get supportsSurahAudioDownload =>
      surahAudioId != null || surahAudioBaseUrl != null;

  bool get usesSurahAudioStream => surahAudioBaseUrl != null;

  bool supportsSurahDownload(int surah) =>
      supportsSurahAudioDownload &&
      (downloadableSurahs == null || downloadableSurahs!.contains(surah));

  String surahAudioUrl(int surah) {
    final baseUrl = surahAudioBaseUrl;
    if (baseUrl != null) {
      final separator = baseUrl.endsWith('/') ? '' : '/';
      final fileName = surah.toString().padLeft(3, '0');
      return '$baseUrl$separator$fileName.mp3';
    }

    return 'https://cdn.islamic.network/quran/audio-surah/'
        '$surahAudioBitrate/$surahAudioId/$surah.mp3';
  }
}

const List<Reciter> availableReciters = [
  Reciter(
    name: 'Mishary Rashid Alafasy',
    id: 'ar.alafasy',
    bitrate: 128,
    surahAudioId: 'ar.alafasy',
    surahAudioBitrate: 128,
  ),
  Reciter(
    name: 'AbdulBaset AbdulSamad',
    id: 'ar.abdulsamad',
    bitrate: 64,
    surahAudioId: 'ar.abdulbasitmurattal',
    surahAudioBitrate: 128,
  ),
  Reciter(
    name: 'Hani Ar-Rifai',
    id: 'ar.hanirifai',
    bitrate: 192,
    surahAudioId: 'ar.haniarrifai',
    surahAudioBitrate: 128,
  ),
  Reciter(
    name: 'Muhammad Ayyoub',
    id: 'ar.muhammadayyoub',
    bitrate: 128,
    surahAudioId: 'ar.muhammadayyub',
    surahAudioBitrate: 128,
  ),
];

const Set<String> popularReciterNameKeys = {
  'misharyrashidalafasy',
  'abdulbasetabdulsamad',
  'haniarrifai',
  'muhammadayyoub',
};

String normalizeReciterName(String name) {
  return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

bool isPopularReciterName(String name) {
  return popularReciterNameKeys.contains(normalizeReciterName(name));
}

List<Reciter> get offlineReciters => availableReciters
    .where((reciter) => reciter.supportsSurahAudioDownload)
    .toList(growable: false);
