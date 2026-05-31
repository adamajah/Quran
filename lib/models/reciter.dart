import 'package:quran/quran.dart' as q;

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

  bool get supportsVerseAudio => verseReciter != null;

  q.Reciter? get verseReciter {
    switch (id) {
      case 'ar.alafasy':
        return q.Reciter.arAlafasy;
      case 'ar.husary':
        return q.Reciter.arHusary;
      case 'ar.ahmedajamy':
        return q.Reciter.arAhmedAjamy;
      case 'ar.hudhaify':
        return q.Reciter.arHudhaify;
      case 'ar.mahermuaiqly':
        return q.Reciter.arMaherMuaiqly;
      case 'ar.muhammadayyoub':
        return q.Reciter.arMuhammadAyyoub;
      case 'ar.muhammadjibreel':
        return q.Reciter.arMuhammadJibreel;
      case 'ar.minshawi':
        return q.Reciter.arMinshawi;
      case 'ar.shaatree':
        return q.Reciter.arShaatree;
      default:
        return null;
    }
  }

  bool supportsSurahDownload(int surah) =>
      supportsSurahAudioDownload &&
      (downloadableSurahs == null || downloadableSurahs!.contains(surah));

  String verseAudioUrl(int surah, int verse) {
    final reciter = verseReciter;
    if (reciter == null) {
      throw StateError('Reciter $name does not support verse-by-verse audio');
    }

    return q.getAudioURLByVerse(
      surah,
      verse,
      reciter: reciter,
      bitrate: bitrate,
    );
  }

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
    name: 'Abu Bakr Ash-Shatri',
    id: 'ar.shaatree',
    bitrate: 128,
    surahAudioId: 'ar.shaatree',
    surahAudioBitrate: 128,
  ),
  Reciter(
    name: 'Maher Al-Muaiqly',
    id: 'ar.mahermuaiqly',
    bitrate: 128,
    surahAudioId: 'ar.mahermuaiqly',
    surahAudioBitrate: 128,
  ),
  Reciter(
    name: 'Mahmoud Khalil Al-Husary',
    id: 'ar.husary',
    bitrate: 128,
    surahAudioId: 'ar.husary',
    surahAudioBitrate: 128,
  ),
  Reciter(
    name: 'Muhammad Ayyoub',
    id: 'ar.muhammadayyoub',
    bitrate: 128,
    surahAudioId: 'ar.muhammadayyoub',
    surahAudioBitrate: 128,
  ),
  Reciter(
    name: 'Muhammad Jibreel',
    id: 'ar.muhammadjibreel',
    bitrate: 128,
    surahAudioId: 'ar.muhammadjibreel',
    surahAudioBitrate: 128,
  ),
  Reciter(
    name: 'Ahmed Al-Ajamy',
    id: 'ar.ahmedajamy',
    bitrate: 128,
    surahAudioId: 'ar.ahmedajamy',
    surahAudioBitrate: 128,
  ),
  Reciter(
    name: 'Ali Al-Hudhaify',
    id: 'ar.hudhaify',
    bitrate: 128,
    surahAudioId: 'ar.hudhaify',
    surahAudioBitrate: 128,
  ),
  Reciter(
    name: 'Minshawi',
    id: 'ar.minshawi',
    bitrate: 128,
    surahAudioId: 'ar.minshawi',
    surahAudioBitrate: 128,
  ),
];

const Set<String> popularReciterNameKeys = {
  'misharyrashidalafasy',
  'abdulbasetabdulsamad',
  'abdurrahmanassudais',
  'abubakrashshatri',
  'maheralmuaiqly',
  'mahmoudkhalilalhusary',
  'haniarrifai',
  'muhammadayyoub',
  'muhammadjibreel',
  'ahmedalajamy',
  'alialhudhaify',
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
