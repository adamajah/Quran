import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as q;
import '../models/hafalan_models.dart';
import '../utils/quran_utils.dart';
import 'quran_matching_service.dart';
import 'speech_service.dart';

class HafalanSessionData {
  final int surah;
  final int verse;
  final List<InteractiveWord> words;
  final int mistakes;
  final int currentIndex;
  final String lastRecognized;

  HafalanSessionData({
    required this.surah,
    required this.verse,
    required this.words,
    required this.mistakes,
    required this.currentIndex,
    this.lastRecognized = "",
  });
}

class HafalanEngine {
  final SpeechService _speechService = SpeechService();
  
  int _currentSurah = 1;
  int _startVerse = 1;
  int _endVerse = 7;
  int _mistakesCount = 0;
  List<InteractiveWord> _allWords = [];
  int _currentWordIndex = 0;
  String _lastTranscript = "";

  final _sessionController = StreamController<HafalanSessionData>.broadcast();
  Stream<HafalanSessionData> get sessionStream => _sessionController.stream;

  Future<void> startSession(int surah, int from, int to) async {
    _currentSurah = surah;
    _startVerse = from;
    _endVerse = to;
    _mistakesCount = 0;
    _lastTranscript = "";
    _loadRange(surah, from, to);
    
    await _speechService.init(
      onStatus: (status) => _notify(),
      onError: (error) => _notify(),
    );
    
    await _listen();
  }

  void _loadRange(int surah, int from, int to) {
    _allWords = [];
    for (int v = from; v <= to; v++) {
      String rawText = QuranUtils.getCleanVerse(surah, v, verseEndSymbol: false);
      
      List<String> words = rawText.split(RegExp(r'\s+'))
          .where((w) => w.trim().isNotEmpty)
          .toList();
      
      for (var w in words) {
        _allWords.add(InteractiveWord(
          text: w,
          cleanText: QuranMatchingService.normalizeArabic(w),
          status: WordStatus.pending,
        ));
      }

      // Verse marker
      _allWords.add(InteractiveWord(
        text: _toArabicDigit(v),
        cleanText: '',
        status: WordStatus.correct,
        isVerseMarker: true,
      ));
    }
    _currentWordIndex = 0;
    _notify();
  }

  static String _toArabicDigit(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  Future<void> _listen() async {
    await _speechService.startListening(
      onResult: (transcript) {
        if (transcript != _lastTranscript) {
          _lastTranscript = transcript;
          _processTranscript(transcript);
        }
      },
    );
  }

  void _processTranscript(String transcript) {
    // 1. Normalize the full transcript
    List<String> recognizedWords = transcript.split(RegExp(r'\s+'))
        .map((w) => QuranMatchingService.normalizeArabic(w))
        .where((w) => w.isNotEmpty)
        .toList();

    if (recognizedWords.isEmpty) return;

    // 2. Adaptive Window Matching
    // We look at the last 3 recognized words to handle STT re-corrections
    int lookbackCount = math.min(recognizedWords.length, 3);
    List<String> recentRecognized = recognizedWords.sublist(recognizedWords.length - lookbackCount);

    for (String recognized in recentRecognized) {
      // 3. Sliding Search Window (Look ahead 2 words)
      int searchWindow = 2;
      int start = _currentWordIndex;
      int end = math.min(_allWords.length, _currentWordIndex + searchWindow + 1);

      bool foundMatch = false;

      for (int i = start; i < end; i++) {
        final target = _allWords[i];
        if (target.isVerseMarker || target.status == WordStatus.correct) continue;

        double similarity = QuranMatchingService.getSimilarity(recognized, target.cleanText);

        // Production Thresholds:
        // > 0.8: High Confidence (Correct)
        // > 0.5: Medium Confidence (Almost/Tracking)
        if (similarity >= 0.75) {
          target.status = WordStatus.correct;
          
          // Handle skipped words (User jumped ahead)
          if (i > _currentWordIndex) {
            for (int k = _currentWordIndex; k < i; k++) {
              if (!_allWords[k].isVerseMarker && _allWords[k].status == WordStatus.pending) {
                _allWords[k].status = WordStatus.wrong;
                _mistakesCount++;
                _vibrate();
              }
            }
          }
          
          _currentWordIndex = i + 1;
          foundMatch = true;
          break;
        } else if (similarity > 0.5 && i == _currentWordIndex) {
          // Visual tracking hint (Orange)
          target.status = WordStatus.almost;
          foundMatch = true;
          // Don't advance index yet, wait for clearer match or next word
        }
      }

      // 4. Misread Detection
      // If word is spoken but doesn't match current or next targets
      if (!foundMatch && recognized.length > 3 && _currentWordIndex < _allWords.length) {
        final currentTarget = _allWords[_currentWordIndex];
        if (!currentTarget.isVerseMarker && currentTarget.status == WordStatus.pending) {
           double sim = QuranMatchingService.getSimilarity(recognized, currentTarget.cleanText);
           if (sim < 0.2) { // Clear mismatch
              currentTarget.status = WordStatus.wrong;
              _mistakesCount++;
              _vibrate();
              // Don't advance, let user retry or continue
           }
        }
      }
    }
    
    _notify();
  }

  void _vibrate() => HapticFeedback.mediumImpact();

  void _notify() {
    if (_sessionController.isClosed) return;
    _sessionController.add(HafalanSessionData(
      surah: _currentSurah,
      verse: _startVerse,
      words: _allWords,
      mistakes: _mistakesCount,
      currentIndex: _currentWordIndex,
      lastRecognized: _lastTranscript,
    ));
  }

  Future<void> stopSession() async {
    _lastTranscript = "";
    await _speechService.stopListening();
    _notify();
  }

  void nextAyah() {
    if (_endVerse < q.getVerseCount(_currentSurah)) {
      _startVerse++; 
      _endVerse++;
      _loadRange(_currentSurah, _startVerse, _endVerse);
    }
  }

  void prevAyah() {
    if (_startVerse > 1) {
      _startVerse--; 
      _endVerse--;
      _loadRange(_currentSurah, _startVerse, _endVerse);
    }
  }

  void dispose() {
    _speechService.stopListening();
    _sessionController.close();
  }
}