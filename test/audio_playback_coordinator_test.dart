import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quran_app/services/audio_playback_coordinator.dart';

void main() {
  test('stops the previous audio owner before handing playback over', () async {
    final coordinator = AudioPlaybackCoordinator.instance;
    final firstOwner = Object();
    final secondOwner = Object();
    var firstStopCount = 0;

    await coordinator.requestPlayback(firstOwner, () async {
      firstStopCount++;
    });
    await coordinator.requestPlayback(secondOwner, () async {});

    expect(firstStopCount, 1);
    coordinator.release(secondOwner);
  });

  test('does not stop audio when the same owner continues playback', () async {
    final coordinator = AudioPlaybackCoordinator.instance;
    final owner = Object();
    var stopCount = 0;

    await coordinator.requestPlayback(owner, () async {
      stopCount++;
    });
    await coordinator.requestPlayback(owner, () async {
      stopCount++;
    });

    expect(stopCount, 0);
    coordinator.release(owner);
  });
}
