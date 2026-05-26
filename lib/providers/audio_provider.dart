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

  Future<void> playToggle(String path) async {
    _currentPath = path;
    await _audioService.playOffline(path);
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioService.stop();
    _currentPath = null;
    notifyListeners();
  }
}
