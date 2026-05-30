import 'package:audioplayers/audioplayers.dart';

import 'audio_playback_coordinator.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final _playbackOwner = Object();
  String? _currentPlayingPath;

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  Future<void> playOffline(String path) async {
    await AudioPlaybackCoordinator.instance.requestPlayback(
      _playbackOwner,
      stop,
    );
    if (_currentPlayingPath == path && _player.state == PlayerState.playing) {
      await _player.pause();
    } else if (_currentPlayingPath == path &&
        _player.state == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.stop();
      _currentPlayingPath = path;
      try {
        await _player.play(DeviceFileSource(path));
      } catch (_) {
        _currentPlayingPath = null;
        rethrow;
      }
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentPlayingPath = null;
    AudioPlaybackCoordinator.instance.release(_playbackOwner);
  }

  void dispose() {
    AudioPlaybackCoordinator.instance.release(_playbackOwner);
    _player.dispose();
  }
}
