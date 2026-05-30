import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_service.dart';

class AudioProvider with ChangeNotifier {
  final AudioService _audioService;
  PlayerState _playerState = PlayerState.stopped;
  String? _currentPath;

  AudioProvider(this._audioService) {
    _audioService.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    });
  }

  PlayerState get playerState => _playerState;
  String? get currentPath => _currentPath;

  Future<String?> playToggle(String path) async {
    _currentPath = path;
    try {
      await _audioService.playOffline(path);
      notifyListeners();
      return null;
    } catch (_) {
      _currentPath = null;
      notifyListeners();
      return 'File audio tidak dapat diputar. Silakan download ulang.';
    }
  }

  Future<void> stop() async {
    await _audioService.stop();
    _currentPath = null;
    notifyListeners();
  }
}
