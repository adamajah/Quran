import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _shouldBeListening = false;
  int _reconnectCount = 0;
  final int _maxReconnects = 50;
  DateTime? _lastReconnectTime;

  Function(String)? _onResult;
  Function(String)? _onStatus;
  Function(String)? _onError;

  Future<bool> init({
    Function(String)? onStatus,
    Function(String)? onError,
  }) async {
    if (_isInitialized) return true;

    _onStatus = onStatus;
    _onError = onError;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: kDebugMode,
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Speech Init Error: $e');
      return false;
    }
  }

  void _handleStatus(String status) {
    debugPrint('Speech Status: $status');
    _onStatus?.call(status);

    // AUTO RECONNECT LOGIC
    // Some plugins send 'doneNoResult' or 'done' or 'notListening'
    if (status.contains('done') || status == 'notListening') {
      if (_shouldBeListening) {
        _attemptReconnect();
      }
    }
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint(
      'Speech Error: ${error.errorMsg} - Permanent: ${error.permanent}',
    );
    _onError?.call(error.errorMsg);

    if (_shouldBeListening && !error.permanent) {
      _attemptReconnect();
    }
  }

  Future<void> _attemptReconnect() async {
    if (_reconnectCount >= _maxReconnects) {
      debugPrint('Max reconnects reached ($_maxReconnects). Stopping.');
      _shouldBeListening = false;
      return;
    }

    // Rate limit reconnects to once every 1.2 seconds (loosened from 2s)
    final now = DateTime.now();
    if (_lastReconnectTime != null &&
        now.difference(_lastReconnectTime!).inMilliseconds < 1200) {
      return;
    }
    _lastReconnectTime = now;

    _reconnectCount++;
    debugPrint('Attempting auto-reconnect #$_reconnectCount / $_maxReconnects');

    // Slightly longer delay before restarting to allow OS to clean up
    await Future.delayed(const Duration(milliseconds: 2000));

    if (_shouldBeListening) {
      // Self-healing: if it's been many retries, try to re-initialize
      if (_reconnectCount % 5 == 0) {
        debugPrint('Multiple failures, re-initializing engine...');
        _isInitialized = false;
        await init();
      }
      await _startListeningInternal();
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'ar-SA',
  }) async {
    _onResult = (transcript) {
      _reconnectCount = 0; // Reset count on successful speech result
      onResult(transcript);
    };
    _shouldBeListening = true;
    _reconnectCount = 0;

    if (!_isInitialized) {
      await init();
    }

    await _startListeningInternal(localeId: localeId);
  }

  Future<void> _startListeningInternal({String localeId = 'ar-SA'}) async {
    try {
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _onResult?.call(result.recognizedWords);
          }
        },
        listenFor: const Duration(minutes: 20),
        pauseFor: const Duration(seconds: 60),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
        localeId: localeId,
      );
    } catch (e) {
      debugPrint('Listen Internal Error: $e');
    }
  }

  Future<void> stopListening() async {
    _shouldBeListening = false;
    await _speech.stop();
  }

  Future<void> cancelListening() async {
    _shouldBeListening = false;
    await _speech.cancel();
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isInitialized;
}
