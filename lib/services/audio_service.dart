import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

import 'audio_playback_coordinator.dart';

class AudioService {
  AudioPlayer? _player;
  final _playbackOwner = Object();
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
  StreamSubscription<PlayerState>? _playerStateSub;
  String? _currentPlayingPath;

  Stream<PlayerState> get onPlayerStateChanged =>
      _playerStateController.stream;

  Stream<Duration> get onPositionChanged =>
      _player?.onPositionChanged ?? const Stream<Duration>.empty();

  Stream<Duration> get onDurationChanged =>
      _player?.onDurationChanged ?? const Stream<Duration>.empty();

  Future<AudioPlayer> _ensurePlayer() async {
    _player ??= AudioPlayer();
    _playerStateSub ??= _player!.onPlayerStateChanged.listen(
      _playerStateController.add,
    );
    return _player!;
  }

  Future<void> playOffline(String path) async {
    final player = await _ensurePlayer();
    await AudioPlaybackCoordinator.instance.requestPlayback(
      _playbackOwner,
      stop,
    );
    if (_currentPlayingPath == path && player.state == PlayerState.playing) {
      await player.pause();
    } else if (_currentPlayingPath == path &&
        player.state == PlayerState.paused) {
      await player.resume();
    } else {
      await player.stop();
      _currentPlayingPath = path;
      try {
        await player.play(DeviceFileSource(path));
      } catch (_) {
        _currentPlayingPath = null;
        rethrow;
      }
    }
  }

  Future<void> pause() async {
    final player = _player;
    if (player == null) return;
    await player.pause();
  }

  Future<void> stop() async {
    final player = _player;
    if (player != null) {
      await player.stop();
    }
    _currentPlayingPath = null;
    AudioPlaybackCoordinator.instance.release(_playbackOwner);
  }

  void dispose() {
    AudioPlaybackCoordinator.instance.release(_playbackOwner);
    _playerStateSub?.cancel();
    _playerStateController.close();
    _player?.dispose();
  }
}
