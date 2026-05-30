import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_quran_app/models/download_item.dart';
import 'package:flutter_quran_app/models/reciter.dart';
import 'package:flutter_quran_app/providers/download_provider.dart';
import 'package:flutter_quran_app/services/download_service.dart';
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
  @override
  Future<String> getDownloadPath() async => '/tmp';
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

    await provider.downloadSurah(36);
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

    provider.selectReciter(hani);
    await provider.downloadSurah(1);
    await Future<void>.delayed(Duration.zero);

    expect(downloadService.urls, [
      'https://cdn.islamic.network/quran/audio-surah/128/ar.haniarrifai/1.mp3',
    ]);
  });
}
