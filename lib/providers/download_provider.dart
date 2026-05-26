import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:quran/quran.dart' as q;
import '../models/download_item.dart';
import '../models/reciter.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class DownloadProvider with ChangeNotifier {
  final DownloadService _downloadService;
  final StorageService _storageService;
  final SharedPreferences _prefs;
  final Battery _battery = Battery();

  List<DownloadItem> _items = [];
  bool _wifiOnly = false;
  bool _pauseLowBattery = true;
  final List<String> _queue = [];

  DownloadProvider(this._downloadService, this._storageService, this._prefs) {
    _loadSettings();
    _loadItems();
    _listenToBattery();
  }

  List<DownloadItem> get items => _items;
  bool get wifiOnly => _wifiOnly;
  bool get pauseLowBattery => _pauseLowBattery;

  void _loadSettings() {
    _wifiOnly = _prefs.getBool('wifi_only') ?? false;
    _pauseLowBattery = _prefs.getBool('pause_low_battery') ?? true;
  }

  void _loadItems() {
    final String? itemsJson = _prefs.getString('download_items');
    if (itemsJson != null) {
      final List<dynamic> decoded = jsonDecode(itemsJson);
      _items = decoded.map((item) => DownloadItem.fromJson(item)).toList();
      _syncDefaultSurahItems();
    } else {
      _items = _buildDefaultSurahItems();
      _saveItems();
    }
  }

  List<DownloadItem> _buildDefaultSurahItems() {
    final defaultReciter = availableReciters.first;
    return List.generate(q.totalSurahCount, (index) {
      final surah = index + 1;
      return _buildSurahItem(surah, defaultReciter);
    });
  }

  DownloadItem _buildSurahItem(int surah, Reciter reciter) {
    final paddedId = surah.toString().padLeft(3, '0');
    final id =
        reciter.id == availableReciters.first.id
            ? paddedId
            : '${reciter.id}-$paddedId';

    return DownloadItem(
      id: id,
      title: q.getSurahName(surah),
      subtitle: reciter.name,
      url: _surahAudioUrl(surah, reciter),
    );
  }

  String _surahAudioUrl(int surah, Reciter reciter) {
    return 'https://cdn.islamic.network/quran/audio-surah/'
        '${reciter.bitrate}/${reciter.id}/$surah.mp3';
  }

  void _syncDefaultSurahItems() {
    var changed = false;
    for (final item in _buildDefaultSurahItems()) {
      if (_items.indexWhere((existing) => existing.id == item.id) == -1) {
        _items.add(item);
        changed = true;
      }
    }
    if (changed) _saveItems();
  }

  DownloadStatus statusForSurah(int surah) {
    final id = surah.toString().padLeft(3, '0');
    final index = _items.indexWhere((item) => item.id == id);
    return index == -1 ? DownloadStatus.notDownloaded : _items[index].status;
  }

  int completedSurahCountForReciter(String reciterId) {
    final defaultReciterId = availableReciters.first.id;
    return List.generate(q.totalSurahCount, (index) {
      final surahId = (index + 1).toString().padLeft(3, '0');
      return reciterId == defaultReciterId ? surahId : '$reciterId-$surahId';
    }).where((id) {
      final index = _items.indexWhere((item) => item.id == id);
      return index != -1 && _items[index].status == DownloadStatus.completed;
    }).length;
  }

  void _saveItems() {
    final String encoded = jsonEncode(
      _items.map((item) => item.toJson()).toList(),
    );
    _prefs.setString('download_items', encoded);
  }

  void setWifiOnly(bool value) {
    _wifiOnly = value;
    _prefs.setBool('wifi_only', value);
    notifyListeners();
  }

  void setPauseLowBattery(bool value) {
    _pauseLowBattery = value;
    _prefs.setBool('pause_low_battery', value);
    notifyListeners();
  }

  Future<void> startDownload(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    // Check WiFi
    if (_wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.wifi)) {
        _items[index].status = DownloadStatus.failed;
        _items[index].lastError = "Download tertunda (Hanya WiFi aktif)";
        notifyListeners();
        return;
      }
    }

    // Check Battery
    if (_pauseLowBattery) {
      try {
        final batteryLevel = await _battery.batteryLevel;
        if (batteryLevel < 20) {
          _items[index].status = DownloadStatus.paused;
          notifyListeners();
          return;
        }
      } catch (e) {
        // Battery info unavailable (e.g. Simulator), ignore check
      }
    }

    if (!_queue.contains(id)) {
      _queue.add(id);
    }

    if (_queue.first == id) {
      _processDownload(id);
    } else {
      _items[index].status = DownloadStatus.downloading; // Show as in queue
      notifyListeners();
    }
  }

  Future<void> _processDownload(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = _items[index];
    final downloadPath = await _storageService.getDownloadPath();
    final savePath = '$downloadPath/${item.id}.mp3';

    _items[index].status = DownloadStatus.downloading;
    notifyListeners();

    await _downloadService.downloadFile(
      url: item.url,
      savePath: savePath,
      id: item.id,
      onProgress: (count, total) {
        if (total != -1) {
          _items[index].progress = count / total;
          _items[index].totalSize = total;

          // Throttled notification update (every 10%)
          final progressPercent = (_items[index].progress * 100).toInt();
          if (progressPercent % 10 == 0) {
            NotificationService.showDownloadProgress(
              id: item.id.hashCode,
              title: item.title,
              progress: progressPercent,
              maxProgress: 100,
            );
          }
          notifyListeners();
        }
      },
      onCompleted: () {
        _items[index].status = DownloadStatus.completed;
        _items[index].savePath = savePath;
        _items[index].progress = 1.0;
        _queue.remove(id);
        _saveItems();

        NotificationService.showDownloadCompleted(
          id: item.id.hashCode,
          title: item.title,
        );

        notifyListeners();
        _processNext();
      },
      onError: (error) {
        if (error == "PAUSED") {
          _items[index].status = DownloadStatus.paused;
          NotificationService.cancel(item.id.hashCode);
        } else {
          _items[index].status = DownloadStatus.failed;
          _items[index].lastError = error;
          NotificationService.showDownloadError(
            id: item.id.hashCode,
            title: item.title,
            error: error,
          );
        }
        _queue.remove(id);
        notifyListeners();
        _processNext();
      },
    );
  }

  void _processNext() {
    if (_queue.isNotEmpty) {
      _processDownload(_queue.first);
    }
  }

  void pauseDownload(String id) {
    _downloadService.pauseDownload(id);
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].status = DownloadStatus.paused;
      _queue.remove(id);
      notifyListeners();
    }
  }

  Future<void> deleteDownload(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      if (_items[index].savePath != null) {
        await _storageService.deleteFile(_items[index].savePath!);
      }
      _items[index].status = DownloadStatus.notDownloaded;
      _items[index].progress = 0.0;
      _items[index].savePath = null;
      _saveItems();
      notifyListeners();
    }
  }

  void _listenToBattery() {
    _battery.onBatteryStateChanged.listen((state) async {
      if (_pauseLowBattery) {
        try {
          final level = await _battery.batteryLevel;
          if (level < 20) {
            // Pause all active downloads
            for (var item in _items) {
              if (item.status == DownloadStatus.downloading) {
                pauseDownload(item.id);
              }
            }
          }
        } catch (e) {
          // Ignore if battery info unavailable
        }
      }
    });
  }

  Future<void> downloadAll() async {
    _syncDefaultSurahItems();
    for (var surah = 1; surah <= q.totalSurahCount; surah++) {
      final id = surah.toString().padLeft(3, '0');
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1 && _items[index].status != DownloadStatus.completed) {
        startDownload(id);
      }
    }
  }

  Future<void> downloadReciter(Reciter reciter) async {
    for (var surah = 1; surah <= q.totalSurahCount; surah++) {
      final item = _buildSurahItem(surah, reciter);
      final index = _items.indexWhere((existing) => existing.id == item.id);
      if (index == -1) {
        _items.add(item);
      }
    }
    _saveItems();
    notifyListeners();

    for (var surah = 1; surah <= q.totalSurahCount; surah++) {
      final paddedId = surah.toString().padLeft(3, '0');
      final id =
          reciter.id == availableReciters.first.id
              ? paddedId
              : '${reciter.id}-$paddedId';
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1 && _items[index].status != DownloadStatus.completed) {
        startDownload(id);
      }
    }
  }
}
