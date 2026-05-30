// ─────────────────────────────────────────────────────────────────────────────
// hafalan_screen.dart  —  Tahfidz / Hafalan Mode  (Al-Quran Digital)
// Features: Hide Ayat, Repeat Ayat, Highlight Status, Progress, Bookmark,
//           Quiz Sambung Ayat, Statistik, Jadwal Murojaah
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as q;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_style.dart';
import '../models/hafalan_models.dart';
import '../models/reciter.dart';
import '../utils/quran_utils.dart';
import '../widgets/hafalan/hafalan_tab.dart';
import '../widgets/hafalan/hafalan_widgets.dart';
import '../widgets/hafalan/quiz_tab.dart';
import '../widgets/hafalan/realtime_ayah_view.dart';
import '../widgets/hafalan/recording_controls.dart';
import '../services/hafalan_engine.dart';
import '../services/audio_playback_coordinator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HafalanScreen  —  main entry point
// ─────────────────────────────────────────────────────────────────────────────
class HafalanScreen extends StatefulWidget {
  final int initialSurah;
  const HafalanScreen({super.key, this.initialSurah = 1});

  @override
  State<HafalanScreen> createState() => _HafalanScreenState();
}

class _HafalanScreenState extends State<HafalanScreen>
    with TickerProviderStateMixin {
  // ── Navigation
  int _tab = 0; // 0=hafalan, 1=tarteel, 2=quiz

  // ── Surah selection
  late int _hafalanSurah;
  late int _tarteelSurah;
  late int _hafalanVerseCount;
  late int _tarteelVerseCount;

  // ── Verse states (key: "surah:verse")
  final Map<String, VerseState> _states = {};

  // ── Hide mode
  HideMode _hideMode = HideMode.none;

  // ── Repeat
  bool _repeatActive = false;
  RepeatConfig _repeatCfg = RepeatConfig();
  int _repeatRemaining = 0;
  int _repeatCurrentVerse = 0;
  Timer? _repeatTimer;

  // ── Audio
  final _audioPlayer = AudioPlayer();
  final _playbackOwner = Object();
  int _playRequestId = 0;
  bool _playing = false;
  int _playingVerse = 0;
  Reciter _selectedReciter = availableReciters[0];

  // ── Animation
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _tabCtrl;

  // ── Stats
  DailyStats _stats = DailyStats(lastStudied: DateTime.now());

  // ── Quiz
  int _quizSurah = 36; // default Yasin
  int _quizFromVerse = 1;
  int _quizToVerse = 5;
  List<QuizQuestion> _quizQuestions = [];
  int _quizIndex = 0;
  int _quizScore = 0;
  bool _quizDone = false;
  String? _selectedQuizAnswer;
  bool? _quizAnswerCorrect;

  // ── Interactive (Tarteel) Mode
  final _engine = HafalanEngine();
  bool _isRecording = false;
  HafalanSessionData? _sessionData;
  Timer? _sessionTimer;
  int _seconds = 0;
  bool _isTextHidden = false;
  final ScrollController _tarteelScroll = ScrollController();

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _hafalanSurah = widget.initialSurah;
    _tarteelSurah = widget.initialSurah;
    _hafalanVerseCount = q.getVerseCount(_hafalanSurah);
    _tarteelVerseCount = q.getVerseCount(_tarteelSurah);
    _repeatCfg.toVerse = _hafalanVerseCount.clamp(1, 7);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _tabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _loadPrefs();
    _audioPlayer.playerStateStream.listen(_onAudioState);
  }

  // ─── Persistence ──────────────────────────────────────────────────────────
  String _prefKey(int s, int v, String suffix) => 'h_${s}_${v}_$suffix';

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();

    // Migration: reset default statuses to 'belum' by removing any saved status indices.
    // This cleans up any corrupted or default-hafal states from previous versions/runs.
    final migrated = p.getBool('h_migrated_belum_v2') ?? false;
    if (!migrated) {
      for (int s = 1; s <= q.totalSurahCount; s++) {
        final cnt = q.getVerseCount(s);
        for (int v = 1; v <= cnt; v++) {
          await p.remove(_prefKey(s, v, 'status'));
        }
      }
      await p.setBool('h_migrated_belum_v2', true);
    }

    _stats = DailyStats(
      totalSessions: p.getInt('h_totalSessions') ?? 0,
      streak: p.getInt('h_streak') ?? 0,
      todayVerses: p.getInt('h_todayVerses') ?? 0,
      lastStudied:
          DateTime.tryParse(p.getString('h_lastStudied') ?? '') ??
          DateTime.now(),
    );
    // load all stored verse states
    for (int s = 1; s <= q.totalSurahCount; s++) {
      final cnt = q.getVerseCount(s);
      for (int v = 1; v <= cnt; v++) {
        final statusIdx = p.getInt(_prefKey(s, v, 'status')) ?? 0;
        final bookmarked = p.getBool(_prefKey(s, v, 'bm')) ?? false;
        if (statusIdx != 0 || bookmarked) {
          _states['$s:$v'] = VerseState(
            status: HafalanStatus.values[statusIdx],
            isBookmarked: bookmarked,
          );
        }
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveVerseState(int s, int v) async {
    final p = await SharedPreferences.getInstance();
    final st = _getState(s, v);
    await p.setInt(_prefKey(s, v, 'status'), st.status.index);
    await p.setBool(_prefKey(s, v, 'bm'), st.isBookmarked);
  }

  Future<void> _saveStats() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('h_totalSessions', _stats.totalSessions);
    await p.setInt('h_streak', _stats.streak);
    await p.setInt('h_todayVerses', _stats.todayVerses);
    await p.setString('h_lastStudied', _stats.lastStudied.toIso8601String());
  }

  // ─── State helpers ────────────────────────────────────────────────────────
  VerseState _getState(int s, int v) {
    return _states.putIfAbsent('$s:$v', () => VerseState());
  }

  void _cycleStatus(int s, int v) {
    setState(() {
      final st = _getState(s, v);
      if (st.status == HafalanStatus.hafal) {
        st.status = HafalanStatus.belum;
      } else {
        st.status = HafalanStatus.hafal;
        // count towards today's verses
        _stats.todayVerses++;
        _saveStats();
      }
    });
    HapticFeedback.mediumImpact();
    _saveVerseState(s, v);
  }

  void _resetStatusForSurah(int s) {
    setState(() {
      final cnt = q.getVerseCount(s);
      for (int v = 1; v <= cnt; v++) {
        final st = _getState(s, v);
        st.status = HafalanStatus.belum;
        _saveVerseState(s, v);
      }
    });
    HapticFeedback.mediumImpact();
    _snack('Ceklis hafalan untuk Surah ini telah direset ✓');
  }

  void _toggleBookmark(int s, int v) {
    setState(
      () => _getState(s, v).isBookmarked = !_getState(s, v).isBookmarked,
    );
    HapticFeedback.lightImpact();
    _saveVerseState(s, v);
    _snack(
      _getState(s, v).isBookmarked ? 'Bookmark disimpan ✦' : 'Bookmark dihapus',
    );
  }

  void _revealVerse(int s, int v) {
    setState(() => _getState(s, v).isRevealed = !_getState(s, v).isRevealed);
  }

  // ─── Audio / Repeat ────────────────────────────────────────────────────────
  void _onAudioState(PlayerState st) {
    if (st.processingState != ProcessingState.completed) return;
    if (!_repeatActive) {
      AudioPlaybackCoordinator.instance.release(_playbackOwner);
      setState(() {
        _playing = false;
        _playingVerse = 0;
      });
      return;
    }
    _repeatRemaining--;
    if (_repeatRemaining > 0) {
      // pause then replay same verse
      _repeatTimer?.cancel();
      _repeatTimer = Timer(Duration(seconds: _repeatCfg.delaySeconds), () {
        if (_repeatActive) _playVerse(_repeatCurrentVerse);
      });
    } else {
      // move to next verse in range
      final next = _repeatCurrentVerse + 1;
      if (next <= _repeatCfg.toVerse) {
        setState(() => _repeatCurrentVerse = next);
        _repeatRemaining = _repeatCfg.count;
        _repeatTimer = Timer(Duration(seconds: _repeatCfg.delaySeconds), () {
          if (_repeatActive) _playVerse(next);
        });
      } else {
        // done
        AudioPlaybackCoordinator.instance.release(_playbackOwner);
        setState(() {
          _repeatActive = false;
          _playing = false;
          _playingVerse = 0;
        });
        _snack('Pengulangan selesai ✓');
      }
    }
  }

  Future<void> _playVerse(int verse) async {
    final requestId = ++_playRequestId;
    if (mounted) {
      setState(() {
        _playingVerse = verse;
        _playing = true;
      });
    }
    try {
      await AudioPlaybackCoordinator.instance.requestPlayback(
        _playbackOwner,
        _stopForPlaybackHandoff,
      );
      if (requestId != _playRequestId) return;

      // Calculate global verse number for the URL
      int globalVerse = 0;
      for (int i = 1; i < _hafalanSurah; i++) {
        globalVerse += q.getVerseCount(i);
      }
      globalVerse += verse;

      // Pattern: https://cdn.islamic.network/quran/audio/[bitrate]/[reciter_id]/[global_verse].mp3
      final url =
          'https://cdn.islamic.network/quran/audio/${_selectedReciter.bitrate}/${_selectedReciter.id}/$globalVerse.mp3';

      await _audioPlayer.setUrl(url);
      if (requestId != _playRequestId) return;
      unawaited(_audioPlayer.play());
    } catch (e) {
      AudioPlaybackCoordinator.instance.release(_playbackOwner);
      if (mounted) setState(() => _playing = false);
      debugPrint('Audio err: $e');
    }
  }

  Future<void> _stopForPlaybackHandoff() async {
    ++_playRequestId;
    _repeatTimer?.cancel();
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _repeatActive = false;
      _playing = false;
      _playingVerse = 0;
    });
  }

  Future<void> _resumePlayback() async {
    if (mounted) setState(() => _playing = true);
    await AudioPlaybackCoordinator.instance.requestPlayback(
      _playbackOwner,
      _stopForPlaybackHandoff,
    );
    unawaited(_audioPlayer.play());
  }

  void _startRepeat() {
    if (_repeatCfg.fromVerse > _repeatCfg.toVerse) {
      _snack('Rentang ayat tidak valid');
      return;
    }
    setState(() {
      _repeatActive = true;
      _repeatCurrentVerse = _repeatCfg.fromVerse;
      _repeatRemaining = _repeatCfg.count;
      _stats.totalSessions++;
    });
    _saveStats();
    _playVerse(_repeatCfg.fromVerse);
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    ++_playRequestId;
    _audioPlayer.stop();
    AudioPlaybackCoordinator.instance.release(_playbackOwner);
    setState(() {
      _repeatActive = false;
      _playing = false;
      _playingVerse = 0;
      _repeatCurrentVerse = 0;
      _repeatRemaining = 0;
    });
  }

  // ─── Quiz ─────────────────────────────────────────────────────────────────
  void _generateQuiz() {
    final total = q.getVerseCount(_quizSurah);
    final from = _quizFromVerse.clamp(1, total - 1);
    final to = _quizToVerse.clamp(from + 1, total);
    final questions = <QuizQuestion>[];

    for (int v = from; v < to; v++) {
      final correctNext = QuranUtils.getCleanVerse(
        _quizSurah,
        v + 1,
        verseEndSymbol: false,
      );
      // gather 3 wrong answers from other verses
      final wrongPool = <String>{};
      final rand = math.Random();
      while (wrongPool.length < 3) {
        final rv = rand.nextInt(total) + 1;
        if (rv != v + 1) {
          wrongPool.add(
            QuranUtils.getCleanVerse(_quizSurah, rv, verseEndSymbol: false),
          );
        }
      }
      final options = [...wrongPool, correctNext]..shuffle(rand);
      questions.add(
        QuizQuestion(
          surah: _quizSurah,
          promptVerse: v,
          promptText: QuranUtils.getCleanVerse(
            _quizSurah,
            v,
            verseEndSymbol: false,
          ),
          correctAnswer: correctNext,
          options: options,
        ),
      );
    }

    // Shuffle the questions so they are not in order
    questions.shuffle();
    setState(() {
      _quizQuestions = questions;
      _quizIndex = 0;
      _quizScore = 0;
      _quizDone = false;
      _selectedQuizAnswer = null;
      _quizAnswerCorrect = null;
    });
  }

  void _answerQuiz(String answer) {
    if (_selectedQuizAnswer != null) return; // already answered
    final correct = _quizQuestions[_quizIndex].correctAnswer == answer;
    setState(() {
      _selectedQuizAnswer = answer;
      _quizAnswerCorrect = correct;
      if (correct) _quizScore++;
    });
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _quizIndex++;
        _selectedQuizAnswer = null;
        _quizAnswerCorrect = null;
        if (_quizIndex >= _quizQuestions.length) _quizDone = true;
      });
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _changeSurah(int s) {
    setState(() {
      _hafalanSurah = s;
      _hafalanVerseCount = q.getVerseCount(s);
      _repeatCfg.fromVerse = 1;
      _repeatCfg.toVerse = _hafalanVerseCount.clamp(1, 7);
      _hideMode = HideMode.none;
      _stopRepeat();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    AudioPlaybackCoordinator.instance.release(_playbackOwner);
    _audioPlayer.dispose();
    _pulseCtrl.dispose();
    _tabCtrl.dispose();
    _repeatTimer?.cancel();
    _sessionTimer?.cancel();
    _tarteelScroll.dispose();
    _engine.dispose();
    super.dispose();
  }

  // ── Interactive (Tarteel) Logic ──────────────────────────────────────────
  int _tarteelFromVerse = 1;
  int _tarteelToVerse = 7;

  Future<void> _prepareForSpeechRecognition() async {
    _repeatTimer?.cancel();
    ++_playRequestId;
    await _audioPlayer.stop();
    AudioPlaybackCoordinator.instance.release(_playbackOwner);
    if (!mounted) return;
    setState(() {
      _repeatActive = false;
      _playing = false;
      _playingVerse = 0;
    });
  }

  Future<void> _startInteractive() async {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    await _prepareForSpeechRecognition();
    if (!mounted) return;

    setState(() {
      _isRecording = true;
      _seconds = 0;
    });

    await _engine.startSession(
      _tarteelSurah,
      _tarteelFromVerse,
      _tarteelToVerse,
    );

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _seconds++);
    });

    debugPrint(
      'Tarteel Session Started: Surah $_tarteelSurah, Verse $_tarteelFromVerse-$_tarteelToVerse',
    );
  }

  Future<void> _pauseInteractive() async {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    setState(() => _isRecording = false);
    await _engine.stopSession();
  }

  Future<void> _resumeInteractive() async {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    await _prepareForSpeechRecognition();
    if (!mounted) return;
    setState(() => _isRecording = true);
    await _engine.startSession(
      _tarteelSurah,
      _tarteelFromVerse,
      _tarteelToVerse,
    );
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _stopInteractive() async {
    await _engine.stopSession();
    _sessionTimer?.cancel();
    _sessionTimer = null;
    setState(() {
      _isRecording = false;
      _sessionData = null;
      _seconds = 0;
    });
  }

  void _scrollToCurrentWord() {
    if (!_tarteelScroll.hasClients || _sessionData == null) return;

    final currentIdx = _sessionData!.currentIndex;
    final totalWords = _sessionData!.words.length;
    if (totalWords == 0) return;

    // Smoother calculation: scroll based on word percentage
    double progress = currentIdx / totalWords;
    double maxScroll = _tarteelScroll.position.maxScrollExtent;

    // Add offset so current word is not at the very top
    double targetScroll = (progress * maxScroll) - 80;
    targetScroll = targetScroll.clamp(0.0, maxScroll);

    _tarteelScroll.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );

    // Debug Log
    debugPrint(
      'Sync Progress: ${(progress * 100).toStringAsFixed(1)}% | Current Word: $currentIdx/$totalWords',
    );
  }

  String _formatTime(int sec) {
    final m = (sec / 60).floor().toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder:
                  (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
              child: KeyedSubtree(
                key: ValueKey(_tab),
                child: switch (_tab) {
                  0 => Column(
                    children: [
                      Expanded(
                        child: HafalanTab(
                          surah: _hafalanSurah,
                          verseCount: _hafalanVerseCount,
                          hideMode: _hideMode,
                          repeatActive: _repeatActive,
                          repeatCfg: _repeatCfg,
                          repeatRemaining: _repeatRemaining,
                          repeatCurrentVerse: _repeatCurrentVerse,
                          playing: _playing,
                          playVerse: _playingVerse,
                          pulseAnim: _pulseAnim,
                          getState: _getState,
                          onChangeSurah: _changeSurah,
                          onHideModeChanged:
                              (m) => setState(() => _hideMode = m),
                          onCycleStatus: _cycleStatus,
                          onResetSurahStatus: _resetStatusForSurah,
                          onToggleBookmark: _toggleBookmark,
                          onRevealVerse: _revealVerse,
                          onRepeatCfgChanged:
                              (cfg) => setState(() => _repeatCfg = cfg),
                          onStartRepeat: _startRepeat,
                          onStopRepeat: _stopRepeat,
                          onPlayVerse: _playVerse,
                          selectedReciter: _selectedReciter,
                          onReciterChanged:
                              (r) => setState(() => _selectedReciter = r),
                        ),
                      ),
                      // Controls Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border(
                            top: BorderSide(
                              color:
                                  isDark
                                      ? Colors.white10
                                      : Colors.grey.shade300,
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ControlBtn(
                              icon: Icons.skip_previous_rounded,
                              onTap: () {
                                if (_playingVerse > 1) {
                                  _playVerse(_playingVerse - 1);
                                }
                              },
                            ),
                            _ControlBtn(
                              icon:
                                  _hideMode != HideMode.none
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                              onTap:
                                  () => setState(
                                    () =>
                                        _hideMode =
                                            _hideMode == HideMode.none
                                                ? HideMode.allText
                                                : HideMode.none,
                                  ),
                            ),
                            _ControlBtn(
                              icon:
                                  _playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                              isLarge: true,
                              onTap: () async {
                                if (_playing) {
                                  await _audioPlayer.pause();
                                  setState(() => _playing = false);
                                } else {
                                  if (_repeatActive) {
                                    await _resumePlayback();
                                  } else {
                                    await _playVerse(
                                      _playingVerse == 0 ? 1 : _playingVerse,
                                    );
                                  }
                                }
                              },
                            ),
                            _ControlBtn(
                              icon: Icons.repeat_rounded,
                              active: _repeatActive,
                              onTap:
                                  () =>
                                      _repeatActive
                                          ? _stopRepeat()
                                          : _startRepeat(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  1 => Column(
                    children: [
                      // Selection Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF1A1A1A)
                                  : Theme.of(context).cardColor,
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown<int>(
                                    value: _tarteelSurah,
                                    items: List.generate(114, (i) => i + 1),
                                    label: (s) => q.getSurahName(s),
                                    onChanged: (s) async {
                                      _sessionTimer?.cancel();
                                      _sessionTimer = null;
                                      await _engine.stopSession();
                                      setState(() {
                                        _tarteelSurah = s!;
                                        _tarteelVerseCount = q.getVerseCount(s);
                                        _tarteelFromVerse = 1;
                                        _tarteelToVerse = _tarteelVerseCount
                                            .clamp(1, 7);
                                        _isRecording = false;
                                        _seconds = 0;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 85,
                                  child: _buildDropdown<int>(
                                    value: q.getJuzNumber(
                                      _tarteelSurah,
                                      _tarteelFromVerse,
                                    ),
                                    items: List.generate(30, (i) => i + 1),
                                    label: (j) => 'Juz $j',
                                    onChanged: (j) {
                                      // Jump to first verse of this juz
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'Range Ayat:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: (isDark ? Colors.white : Colors.grey)
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDropdown<int>(
                                    value: _tarteelFromVerse,
                                    items: List.generate(
                                      _tarteelVerseCount,
                                      (i) => i + 1,
                                    ),
                                    label: (v) => 'Dari $v',
                                    onChanged: (v) async {
                                      final restart = _isRecording;
                                      setState(() {
                                        _tarteelFromVerse = v!;
                                      });
                                      if (restart) {
                                        await _engine.startSession(
                                          _tarteelSurah,
                                          _tarteelFromVerse,
                                          _tarteelToVerse,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '-',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                Expanded(
                                  child: _buildDropdown<int>(
                                    value: _tarteelToVerse,
                                    items: List.generate(
                                      _tarteelVerseCount -
                                          _tarteelFromVerse +
                                          1,
                                      (i) => i + _tarteelFromVerse,
                                    ),
                                    label: (v) => 'Sampai $v',
                                    onChanged: (v) async {
                                      final restart = _isRecording;
                                      setState(() {
                                        _tarteelToVerse = v!;
                                      });
                                      if (restart) {
                                        await _engine.startSession(
                                          _tarteelSurah,
                                          _tarteelFromVerse,
                                          _tarteelToVerse,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<HafalanSessionData>(
                          stream: _engine.sessionStream,
                          builder: (context, snapshot) {
                            final data = snapshot.data;
                            if (data != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && _sessionData != data) {
                                  setState(() => _sessionData = data);
                                  _scrollToCurrentWord();
                                }
                              });
                            }

                            return Stack(
                              children: [
                                ListView(
                                  controller: _tarteelScroll,
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    // Surah Header like mushaf
                                    if (data != null)
                                      _MushafHeader(surah: _tarteelSurah),
                                    const SizedBox(height: 12),
                                    if (data == null)
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 100,
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.mic_none_rounded,
                                                size: 64,
                                                color: AppColors.gold
                                                    .withValues(alpha: 0.3),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Siap Memulai Tarteel\nKetuk tombol Putar di bawah',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: (isDark
                                                          ? Colors.white
                                                          : Colors.grey)
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      RealtimeAyahView(
                                        words: data.words,
                                        hideMode:
                                            _isTextHidden
                                                ? HideMode.allText
                                                : HideMode.none,
                                        isRecording: _isRecording,
                                        currentIndex: data.currentIndex,
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      RecordingControls(
                        isRecording: _isRecording,
                        mistakes: _sessionData?.mistakes ?? 0,
                        timer: _formatTime(_seconds),
                        onToggle: () async {
                          if (_isRecording) {
                            await _pauseInteractive();
                          } else if (_seconds > 0) {
                            await _resumeInteractive();
                          } else {
                            await _startInteractive();
                          }
                        },
                        onStop: () => _stopInteractive(),
                        onNext: () => _engine.nextAyah(),
                        onPrev: () => _engine.prevAyah(),
                        onToggleHide:
                            () =>
                                setState(() => _isTextHidden = !_isTextHidden),
                        isHidden: _isTextHidden,
                      ),
                    ],
                  ),
                  2 => QuizTab(
                    quizSurah: _quizSurah,
                    quizFromVerse: _quizFromVerse,
                    quizToVerse: _quizToVerse,
                    questions: _quizQuestions,
                    quizIndex: _quizIndex,
                    quizScore: _quizScore,
                    quizDone: _quizDone,
                    selectedAnswer: _selectedQuizAnswer,
                    answerCorrect: _quizAnswerCorrect,
                    onQuizSurahChanged:
                        (s) => setState(() {
                          _quizSurah = s;
                          _quizFromVerse = 1;
                          _quizToVerse = q.getVerseCount(s).clamp(2, 7);
                        }),
                    onFromChanged: (v) => setState(() => _quizFromVerse = v),
                    onToChanged: (v) => setState(() => _quizToVerse = v),
                    onGenerate: _generateQuiz,
                    onAnswer: _answerQuiz,
                    onRestart:
                        () => setState(() {
                          _quizQuestions = [];
                          _quizDone = false;
                          _quizIndex = 0;
                          _quizScore = 0;
                          _selectedQuizAnswer = null;
                          _quizAnswerCorrect = null;
                        }),
                  ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : AppColors.dark,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          Text(
            'Mode Hafalan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.dark,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            'Tahfidz Al-Quran',
            style: TextStyle(
              fontSize: 10,
              color: (isDark ? Colors.white : AppColors.dark).withValues(
                alpha: 0.5,
              ),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.5),
        child: Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0),
                AppColors.gold,
                isDark ? Colors.white24 : AppColors.dark,
                AppColors.gold,
                AppColors.gold.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          TabBtn(
            label: 'Hafalan',
            icon: Icons.menu_book_rounded,
            active: _tab == 0,
            onTap: () => setState(() => _tab = 0),
          ),
          const SizedBox(width: 4),
          TabBtn(
            label: 'Tarteel',
            icon: Icons.mic_rounded,
            active: _tab == 1,
            onTap: () => setState(() => _tab = 1),
          ),
          const SizedBox(width: 4),
          TabBtn(
            label: 'Quiz',
            icon: Icons.quiz_rounded,
            active: _tab == 2,
            onTap: () => setState(() => _tab = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required void Function(T?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          items:
              items
                  .map(
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(
                        label(i),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white : AppColors.dark,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLarge;
  final bool active;

  const _ControlBtn({
    required this.icon,
    required this.onTap,
    this.isLarge = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 12 : 10),
        decoration: BoxDecoration(
          color:
              active
                  ? AppColors.hl
                  : (isLarge
                      ? AppColors.gold
                      : AppColors.gold.withValues(alpha: 0.1)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: (isLarge || active) ? Colors.white : AppColors.gold,
          size: isLarge ? 28 : 22,
        ),
      ),
    );
  }
}

class _MushafHeader extends StatelessWidget {
  final int surah;
  const _MushafHeader({required this.surah});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.pageBg,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          q.getSurahNameArabic(surah),
          style: AppTextStyle.quranSurahNameStyle(
            fontSize: 22,
            color: isDark ? Colors.white : AppColors.dark,
          ),
        ),
      ),
    );
  }
}
