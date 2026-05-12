// ─────────────────────────────────────────────────────────────────────────────
// hafalan_screen.dart  —  Tahfidz / Hafalan Mode  (Al-Quran Digital)
// Features: Hide Ayat, Repeat Ayat, Highlight Status, Progress, Bookmark,
//           Quiz Sambung Ayat, Statistik, Jadwal Murojaah
// ─────────────────────────────────────────────────────────────────────────────
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as q;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../models/hafalan_models.dart';
import '../widgets/hafalan/hafalan_tab.dart';
import '../widgets/hafalan/hafalan_widgets.dart';
import '../widgets/hafalan/progress_tab.dart';
import '../widgets/hafalan/quiz_tab.dart';
import '../widgets/hafalan/statistik_tab.dart';

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
  int _tab = 0; // 0=hafalan, 1=progress, 2=quiz, 3=statistik

  // ── Surah selection
  late int _surah;
  late int _verseCount;

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
  bool _playing = false;
  int _playingVerse = 0;

  // ── Animation
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _tabCtrl;

  // ── Stats
  DailyStats _stats = DailyStats(lastStudied: DateTime.now());

  // ── Quiz
  int _quizSurah = 36; // default Yasin
  int _quizFromVerse = 1;
  int _quizToVerse   = 5;
  List<QuizQuestion> _quizQuestions = [];
  int _quizIndex = 0;
  int _quizScore = 0;
  bool _quizDone = false;
  String? _selectedQuizAnswer;
  bool? _quizAnswerCorrect;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _surah = widget.initialSurah;
    _verseCount = q.getVerseCount(_surah);
    _repeatCfg.toVerse = _verseCount.clamp(1, 7);

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _tabCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 250));

    _loadPrefs();
    _audioPlayer.playerStateStream.listen(_onAudioState);
  }

  // ─── Persistence ──────────────────────────────────────────────────────────
  String _prefKey(int s, int v, String suffix) => 'h_${s}_${v}_$suffix';

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _stats = DailyStats(
      totalSessions: p.getInt('h_totalSessions') ?? 0,
      streak: p.getInt('h_streak') ?? 0,
      todayVerses: p.getInt('h_todayVerses') ?? 0,
      lastStudied: DateTime.tryParse(p.getString('h_lastStudied') ?? '') ?? DateTime.now(),
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
      st.status = HafalanStatus.values[(st.status.index + 1) % 3];
      // count towards today's verses
      if (st.status == HafalanStatus.hafal) {
        _stats.todayVerses++;
        _saveStats();
      }
    });
    HapticFeedback.mediumImpact();
    _saveVerseState(s, v);
  }

  void _toggleBookmark(int s, int v) {
    setState(() => _getState(s, v).isBookmarked = !_getState(s, v).isBookmarked);
    HapticFeedback.lightImpact();
    _saveVerseState(s, v);
    _snack(_getState(s, v).isBookmarked ? 'Bookmark disimpan ✦' : 'Bookmark dihapus');
  }

  void _revealVerse(int s, int v) {
    setState(() => _getState(s, v).isRevealed = !_getState(s, v).isRevealed);
  }

  // ─── Audio / Repeat ────────────────────────────────────────────────────────
  void _onAudioState(PlayerState st) {
    if (st.processingState != ProcessingState.completed) return;
    if (!_repeatActive) {
      setState(() { _playing = false; _playingVerse = 0; });
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
        setState(() { _repeatActive = false; _playing = false; _playingVerse = 0; });
        _snack('Pengulangan selesai ✓');
      }
    }
  }

  void _playVerse(int verse) {
    try {
      _audioPlayer.setUrl(q.getAudioURLByVerse(_surah, verse));
      _audioPlayer.play();
      setState(() { _playingVerse = verse; _playing = true; });
    } catch (e) { debugPrint('Audio err: $e'); }
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
    _audioPlayer.stop();
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
    final from  = _quizFromVerse.clamp(1, total - 1);
    final to    = _quizToVerse.clamp(from + 1, total);
    final questions = <QuizQuestion>[];

    for (int v = from; v < to; v++) {
      final correctNext = q.getVerse(_quizSurah, v + 1, verseEndSymbol: false);
      // gather 3 wrong answers from other verses
      final wrongPool = <String>{};
      final rand = math.Random();
      while (wrongPool.length < 3) {
        final rv = rand.nextInt(total) + 1;
        if (rv != v + 1) wrongPool.add(q.getVerse(_quizSurah, rv, verseEndSymbol: false));
      }
      final options = [...wrongPool, correctNext]..shuffle(rand);
      questions.add(QuizQuestion(
        surah: _quizSurah,
        promptVerse: v,
        promptText: q.getVerse(_quizSurah, v, verseEndSymbol: false),
        correctAnswer: correctNext,
        options: options,
      ));
    }
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

  // ─── Progress helpers ─────────────────────────────────────────────────────
  int _versesByStatus(int s, HafalanStatus status) {
    final cnt = q.getVerseCount(s);
    int count = 0;
    for (int v = 1; v <= cnt; v++) {
      if (_getState(s, v).status == status) count++;
    }
    return count;
  }

  double _surahProgress(int s) {
    final total = q.getVerseCount(s);
    return _versesByStatus(s, HafalanStatus.hafal) / total;
  }

  int get _totalHafal {
    int t = 0;
    for (int s = 1; s <= q.totalSurahCount; s++) {
      t += _versesByStatus(s, HafalanStatus.hafal);
    }
    return t;
  }

  int get _totalVerses {
    int t = 0;
    for (int s = 1; s <= q.totalSurahCount; s++) t += q.getVerseCount(s);
    return t;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.dark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _changeSurah(int s) {
    setState(() {
      _surah = s;
      _verseCount = q.getVerseCount(s);
      _repeatCfg.fromVerse = 1;
      _repeatCfg.toVerse   = _verseCount.clamp(1, 7);
      _hideMode = HideMode.none;
      _stopRepeat();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _audioPlayer.dispose();
    _pulseCtrl.dispose();
    _tabCtrl.dispose();
    _repeatTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.outerBg,
      appBar: _buildAppBar(),
      body: Column(children: [
        _buildTabBar(),
        Expanded(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_tab),
            child: switch (_tab) {
              0 => HafalanTab(
                  surah: _surah,
                  verseCount: _verseCount,
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
                  onHideModeChanged: (m) => setState(() => _hideMode = m),
                  onCycleStatus: _cycleStatus,
                  onToggleBookmark: _toggleBookmark,
                  onRevealVerse: _revealVerse,
                  onRepeatCfgChanged: (cfg) => setState(() => _repeatCfg = cfg),
                  onStartRepeat: _startRepeat,
                  onStopRepeat: _stopRepeat,
                  onPlayVerse: _playVerse,
                ),
              1 => ProgressTab(
                  surah: _surah,
                  getState: _getState,
                  versesByStatus: _versesByStatus,
                  surahProgress: _surahProgress,
                  totalHafal: _totalHafal,
                  totalVerses: _totalVerses,
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
                  onQuizSurahChanged: (s) => setState(() {
                    _quizSurah = s;
                    _quizFromVerse = 1;
                    _quizToVerse   = q.getVerseCount(s).clamp(2, 7);
                  }),
                  onFromChanged: (v) => setState(() => _quizFromVerse = v),
                  onToChanged:   (v) => setState(() => _quizToVerse   = v),
                  onGenerate: _generateQuiz,
                  onAnswer: _answerQuiz,
                  onRestart: () => setState(() {
                    _quizDone = false;
                    _quizIndex = 0;
                    _quizScore = 0;
                    _selectedQuizAnswer = null;
                    _quizAnswerCorrect = null;
                  }),
                ),
              3 => StatistikTab(
                  stats: _stats,
                  totalHafal: _totalHafal,
                  totalVerses: _totalVerses,
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        )),
      ]),
    );
  }

  AppBar _buildAppBar() => AppBar(
    backgroundColor: AppColors.outerBg, elevation: 0, surfaceTintColor: Colors.transparent,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.dark, size: 20),
      onPressed: () => Navigator.pop(context),
    ),
    title: Column(children: [
      Text('Mode Hafalan', style: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark,
        letterSpacing: 0.3,
      )),
      Text('Tahfidz Al-Quran', style: TextStyle(
        fontSize: 10, color: AppColors.dark.withOpacity(0.5), letterSpacing: 0.8,
      )),
    ]),
    centerTitle: true,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1.5),
      child: Container(height: 1.5, decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.gold.withOpacity(0), AppColors.gold, AppColors.dark, AppColors.gold, AppColors.gold.withOpacity(0),
        ]),
      )),
    ),
  );

  Widget _buildTabBar() => Container(
    color: AppColors.outerBg,
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: Row(children: [
      TabBtn(label: 'Hafalan',   icon: Icons.menu_book_rounded,         active: _tab == 0, onTap: () => setState(() => _tab = 0)),
      const SizedBox(width: 6),
      TabBtn(label: 'Progres',   icon: Icons.bar_chart_rounded,         active: _tab == 1, onTap: () => setState(() => _tab = 1)),
      const SizedBox(width: 6),
      TabBtn(label: 'Quiz',      icon: Icons.quiz_rounded,              active: _tab == 2, onTap: () => setState(() => _tab = 2)),
      const SizedBox(width: 6),
      TabBtn(label: 'Statistik', icon: Icons.insert_chart_outlined_rounded, active: _tab == 3, onTap: () => setState(() => _tab = 3)),
    ]),
  );
}