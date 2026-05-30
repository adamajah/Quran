typedef StopPlayback = Future<void> Function();

class AudioPlaybackCoordinator {
  AudioPlaybackCoordinator._();

  static final instance = AudioPlaybackCoordinator._();

  Object? _owner;
  StopPlayback? _stopCurrent;
  Future<void> _queue = Future.value();

  Future<void> requestPlayback(Object owner, StopPlayback stopCurrent) {
    final request = _queue.then((_) async {
      if (identical(_owner, owner)) {
        _stopCurrent = stopCurrent;
        return;
      }

      final previousStop = _stopCurrent;
      _owner = null;
      _stopCurrent = null;
      if (previousStop != null) await previousStop();

      _owner = owner;
      _stopCurrent = stopCurrent;
    });
    _queue = request.catchError((_) {});
    return request;
  }

  void release(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _stopCurrent = null;
  }
}
