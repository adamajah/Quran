import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_quran_app/models/download_item.dart';
import 'package:flutter_quran_app/models/reciter.dart';
import 'package:flutter_quran_app/providers/download_provider.dart';
import 'package:flutter_quran_app/services/download_service.dart';
import 'package:flutter_quran_app/services/offline_reciter_service.dart';
import 'package:flutter_quran_app/services/storage_service.dart';

class _FakeDownloadService extends DownloadService {
  final List<String> urls = [];

  @override
  Future<void> downloadFile({
    required String url,
    required String savePath,
    required Function(int count, int total) onProgress,
    required Function() onCompleted,
    required Function(String error) onError,
    required String id,
  }) async {
    urls.add(url);
  }
}

class _FakeStorageService extends StorageService {
  _FakeStorageService([this.path = '/tmp']);

  final String path;

  @override
  Future<String> getDownloadPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('downloading one surah starts only one download', () async {
    SharedPreferences.setMockInitialValues({'pause_low_battery': false});
    final prefs = await SharedPreferences.getInstance();
    final downloadService = _FakeDownloadService();
    final provider = DownloadProvider(
      downloadService,
      _FakeStorageService(),
      prefs,
    );

    await provider.downloadSurah(36, reciter: availableReciters.first);
    await Future<void>.delayed(Duration.zero);

    expect(downloadService.urls, [
      'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/36.mp3',
    ]);
    expect(
      provider.items
          .where((item) => item.status == DownloadStatus.downloading)
          .length,
      1,
    );
  });

  test('offline reciter uses its supported surah audio alias', () async {
    SharedPreferences.setMockInitialValues({'pause_low_battery': false});
    final prefs = await SharedPreferences.getInstance();
    final downloadService = _FakeDownloadService();
    final provider = DownloadProvider(
      downloadService,
      _FakeStorageService(),
      prefs,
    );
    final hani = availableReciters.firstWhere(
      (reciter) => reciter.id == 'ar.hanirifai',
    );

    await provider.downloadSurah(1, reciter: hani);
    await Future<void>.delayed(Duration.zero);

    expect(downloadService.urls, [
      'https://cdn.islamic.network/quran/audio-surah/128/ar.hanirifai/1.mp3',
    ]);
  });

  test('completed downloads relocate to the current iOS container', () async {
    final downloadDir = await Directory.systemTemp.createTemp(
      'quran-downloads-',
    );
    addTearDown(() => downloadDir.delete(recursive: true));
    final currentPath = '${downloadDir.path}/001.mp3';
    await File(currentPath).writeAsBytes([0x49, 0x44, 0x33]);
    SharedPreferences.setMockInitialValues({
      'pause_low_battery': false,
      'download_items': jsonEncode([
        DownloadItem(
          id: '001',
          title: 'Al-Faatiha',
          subtitle: 'Mishary Rashid Alafasy',
          url:
              'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/1.mp3',
          savePath: '/old-ios-container/Documents/downloads/001.mp3',
          progress: 1,
          status: DownloadStatus.completed,
        ).toJson(),
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final provider = DownloadProvider(
      _FakeDownloadService(),
      _FakeStorageService(downloadDir.path),
      prefs,
    );

    final resolvedPath = await provider.localAudioPathForSurah(1);

    expect(resolvedPath, currentPath);
    expect(provider.itemForSurah(1)?.savePath, currentPath);
  });

  test('interrupted bulk queue does not resume automatically', () async {
    SharedPreferences.setMockInitialValues({
      'pause_low_battery': false,
      'download_items': jsonEncode([
        DownloadItem(
          id: '027',
          title: 'An-Naml',
          subtitle: 'Mishary Rashid Alafasy',
          url:
              'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/27.mp3',
          progress: 0.5,
          status: DownloadStatus.downloading,
        ).toJson(),
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final downloadService = _FakeDownloadService();
    final provider = DownloadProvider(
      downloadService,
      _FakeStorageService(),
      prefs,
    );

    await Future<void>.delayed(Duration.zero);

    expect(provider.statusForSurah(27), DownloadStatus.notDownloaded);
    expect(downloadService.urls, isEmpty);
  });

  test('offline catalog keeps valid qari collections and surah URLs', () {
    final reciters = OfflineReciterService.parseCatalog(
      {
        'reciters': [
          {
            'name': 'Example Qari',
            'moshaf': [
              {
                'id': 7,
                'name': 'Hafs',
                'server': 'https://audio.example/',
                'surah_list': '1,36',
              },
              {
                'id': 8,
                'name': 'Invalid server',
                'server': '',
                'surah_list': '1',
              },
            ],
          },
        ],
      },
      timingReadIds: {'audio.example/': 12},
    );

    expect(reciters, hasLength(1));
    expect(reciters.single.id, 'mp3quran.7');
    expect(reciters.single.collectionName, 'Hafs');
    expect(reciters.single.usesSurahAudioStream, isTrue);
    expect(reciters.single.timingReadId, 12);
    expect(reciters.single.supportsSurahDownload(36), isTrue);
    expect(reciters.single.supportsSurahDownload(2), isFalse);
    expect(reciters.single.surahAudioUrl(36), 'https://audio.example/036.mp3');
  });

  test('offline catalog parses official ayah timing metadata', () {
    final reads = OfflineReciterService.parseTimingReadIds([
      {'id': 5, 'folder_url': 'https://server10.mp3quran.net/ajm/'},
    ]);
    final position = OfflineReciterService.parseAyahStartPosition([
      {'ayah': 4, 'start_time': 29219, 'end_time': 42210},
    ], 4);

    expect(reads, {'server10.mp3quran.net/ajm/': 5});
    expect(position, const Duration(milliseconds: 29219));
  });

  test('offline timing resolves the active ayah as playback moves', () {
    final timings = OfflineReciterService.parseAyahTimings([
      {'ayah': 4, 'start_time': 29219, 'end_time': 42210},
      {'ayah': 5, 'start_time': 42210, 'end_time': 54884},
    ]);

    expect(
      OfflineReciterService.findAyahForPosition(
        timings,
        const Duration(milliseconds: 40000),
      ),
      4,
    );
    expect(
      OfflineReciterService.findAyahForPosition(
        timings,
        const Duration(milliseconds: 45000),
      ),
      5,
    );
  });
}
