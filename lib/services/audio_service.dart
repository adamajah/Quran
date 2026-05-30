import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentPlayingPath;

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  Future<void> playOffline(String path) async {
    if (_currentPlayingPath == path && _player.state == PlayerState.playing) {
      await _player.pause();
    } else if (_currentPlayingPath == path &&
        _player.state == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.stop();
      _currentPlayingPath = path;
      await _player.play(DeviceFileSource(path));
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentPlayingPath = null;
  }

  void dispose() {
    _player.dispose();
  }
}
