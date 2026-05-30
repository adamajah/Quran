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
  Timer? _reconnectTimer;
  bool _restartInProgress = false;
  int _listenGeneration = 0;
  String _localeId = 'ar-SA';

  Function(String)? _onResult;
  Function(String)? _onStatus;
  Function(String)? _onError;

  Future<bool> init({
    Function(String)? onStatus,
    Function(String)? onError,
  }) async {
    if (_isInitialized) return true;

    if (onStatus != null) _onStatus = onStatus;
    if (onError != null) _onError = onError;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        // Plugin debug logging prints microphone RMS values several times per
        // second. Keep app-level status logs without flooding logcat.
        debugLogging: false,
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

    if (status.contains('done') || status == 'notListening') {
      _scheduleReconnect();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint(
      'Speech Error: ${error.errorMsg} - Permanent: ${error.permanent}',
    );
    _onError?.call(error.errorMsg);

    if (!_shouldBeListening) return;

    if (_isRecoverableError(error)) {
      _scheduleReconnect();
    } else if (error.permanent) {
      _shouldBeListening = false;
      _cancelReconnect();
    }
  }

  bool _isRecoverableError(SpeechRecognitionError error) {
    return !error.permanent ||
        error.errorMsg == 'error_no_match' ||
        error.errorMsg == 'error_speech_timeout';
  }

  void _scheduleReconnect() {
    if (!_shouldBeListening ||
        _restartInProgress ||
        _reconnectTimer != null ||
        _speech.isListening) {
      return;
    }

    if (_reconnectCount >= _maxReconnects) {
      debugPrint('Max reconnects reached ($_maxReconnects). Stopping.');
      _shouldBeListening = false;
      return;
    }

    final delay = Duration(
      milliseconds: 1800 + (_reconnectCount * 300).clamp(0, 3000),
    );
    _reconnectTimer = Timer(delay, _restartListening);
  }

  Future<void> _restartListening() async {
    _reconnectTimer = null;
    if (!_shouldBeListening || _restartInProgress) return;

    final generation = _listenGeneration;
    _restartInProgress = true;
    _reconnectCount++;
    debugPrint('Attempting auto-reconnect #$_reconnectCount / $_maxReconnects');
    try {
      await _speech.cancel();
      if (!_shouldBeListening || generation != _listenGeneration) return;
      await _startListeningInternal(localeId: _localeId);
    } finally {
      _restartInProgress = false;
    }
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'ar-SA',
  }) async {
    final generation = ++_listenGeneration;
    _onResult = (transcript) {
      _reconnectCount = 0; // Reset count on successful speech result
      onResult(transcript);
    };
    _shouldBeListening = true;
    _reconnectCount = 0;
    _localeId = localeId;
    _cancelReconnect();

    if (!_isInitialized) {
      await init();
    }

    _restartInProgress = true;
    try {
      await _speech.cancel();
      if (_shouldBeListening && generation == _listenGeneration) {
        await _startListeningInternal(localeId: localeId);
      }
    } finally {
      _restartInProgress = false;
    }
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
      _scheduleReconnect();
    }
  }

  Future<void> stopListening() async {
    _listenGeneration++;
    _shouldBeListening = false;
    _cancelReconnect();
    await _speech.stop();
  }

  Future<void> cancelListening() async {
    _listenGeneration++;
    _shouldBeListening = false;
    _cancelReconnect();
    await _speech.cancel();
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isInitialized;
}
