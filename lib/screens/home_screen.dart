import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as q;
import 'package:quran/quran.dart' show Translation;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../services/bookmark_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_style.dart';
import '../models/verse_ref.dart';
import '../screens/translation_dialog.dart';
import '../models/reciter.dart';
import '../screens/reciter_dialog.dart';
import '../utils/audio_utils.dart';
import '../utils/mushaf_builder.dart';
import '../widgets/common/bottom_bar.dart';
import '../widgets/common/mushaf_drawer.dart';
import '../widgets/mushaf/mushaf_page.dart';
import '../widgets/mushaf/tajwid_guide.dart';
import '../widgets/mushaf/translation_panel.dart';
import '../controllers/settings_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _audio = AudioPlayer();
  late PageController _pageCtrl;
  late AnimationController _flipCtrl;

  // Playback
  bool _playing = false;
  int _pgIdx = 0;
  int _playV = 0;
  int _curS = 1;

  // Tap-to-play: which verse was tapped
  int _tappedSurah = 0;
  int _tappedVerse = 0;

  // Bookmarks
  List<BookmarkEntry> _bookmarks = [];

  // Translation
  Translation _selectedTranslation = Translation.indonesian;
  List<Map<String, dynamic>> _translationVerses = [];
  String _selectedLanguageName = "Indonesian";
  double _translationPanelHeight = 160.0;
  static const double _minPanelH = 56.0;
  static const double _maxPanelH = 420.0;

  late final List<PageData> _pages;

  // ── Page flip animation
  bool _isAutoAdvancing = false;
  double _flipAngle = 0.0;
  final int _flipDir = 1;

  @override
  void initState() {
    super.initState();
    _pages = buildMushafPages();
    _pageCtrl = PageController(initialPage: _pages.length * 500);
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _flipCtrl.addListener(() => setState(() => _flipAngle = _flipCtrl.value));
    _flipCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() {
          _flipAngle = 0;
        });
        _flipCtrl.reset();
      }
    });
    _loadPrefs();
    _audio.playerStateStream.listen((s) {
      if (s.processingState != ProcessingState.completed) return;
      if (!mounted) return;

      final settings = context.read<SettingsController>().settings;
      if (!settings.autoPlay) {
        setState(() => _playing = false);
        return;
      }

      if (_pgIdx >= _pages.length) return;

      final pg = _pages[_pgIdx];
      final currentVerseIdx = pg.verses.indexWhere(
        (v) => v.surah == _curS && v.verse == _playV,
      );

      if (currentVerseIdx != -1 && currentVerseIdx < pg.verses.length - 1) {
        final nextV = pg.verses[currentVerseIdx + 1];
        setState(() {
          _playV = nextV.verse;
          _curS = nextV.surah;
        });
        _doPlay(nextV);
      } else {
        if (_pgIdx + 1 < _pages.length) {
          final nextPgIdx = _pgIdx + 1;
          final nextPg = _pages[nextPgIdx];
          final nextV = nextPg.verses.first;

          setState(() {
            _pgIdx = nextPgIdx;
            _playV = nextV.verse;
            _curS = nextV.surah;
          });

          _isAutoAdvancing = true;

          if (_pageCtrl.hasClients) {
            final currentVirtual =
                _pageCtrl.page?.round() ?? (_pages.length * 500);
            _pageCtrl
                .animateToPage(
                  currentVirtual + 1,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                )
                .then((_) => _isAutoAdvancing = false);
          }

          _doPlay(nextV);
        } else {
          setState(() {
            _playing = false;
            _playV = 0;
          });
        }
      }
    });
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final lastSurah = p.getInt('lastSurah') ?? 1;
    final bookmarks = await BookmarkService.getBookmarks();

    if (!mounted) return;
    int idx = 0;
    for (int i = 0; i < _pages.length; i++) {
      if (_pages[i].verses.any((v) => v.surah == lastSurah && v.verse == 1)) {
        idx = i;
        break;
      }
    }
    setState(() {
      _curS = lastSurah;
      _pgIdx = idx;
      _bookmarks = bookmarks;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageCtrl.hasClients) {
        _pageCtrl.jumpToPage(_pages.length * 500 + idx);
      }
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('lastSurah', _curS);
    await p.setInt('lastPage', _pgIdx);
  }

  void _doPlay(VerseRef r) {
    final settings = context.read<SettingsController>().settings;
    try {
      _audio.setVolume(settings.defaultVolume);
      _audio.setSpeed(settings.playbackSpeed);
      final reciterId =
          settings.defaultReciterId.isNotEmpty
              ? settings.defaultReciterId
              : availableReciters[0].id;
      _audio.setUrl(
        AudioUtils.getVerseAudioUrl(r.surah, r.verse, reciterId, 128),
      );
      _audio.play();
    } catch (e) {
      debugPrint('Audio: $e');
    }
  }

  void _togglePlay() async {
    try {
      final r = await InternetAddress.lookup('example.com');
      if (r.isNotEmpty && r[0].rawAddress.isNotEmpty) {
        if (_playing) {
          _audio.pause();
        } else {
          final pg = _pages[_pgIdx];
          if (_playV == 0) _playV = pg.verses.first.verse;
          _doPlay(
            pg.verses.firstWhere(
              (r) => r.verse == _playV,
              orElse: () => pg.verses.first,
            ),
          );
        }
        setState(() => _playing = !_playing);
      } else {
        _snack('Sambungkan ke Internet');
      }
    } on SocketException {
      _snack('Sambungkan ke Internet');
    }
  }

  void _tapVerse(int surah, int verse) async {
    try {
      final r = await InternetAddress.lookup('example.com');
      if (r.isNotEmpty && r[0].rawAddress.isNotEmpty) {
        setState(() {
          _tappedSurah = surah;
          _tappedVerse = verse;
          _playV = verse;
          _curS = surah;
          _playing = true;
        });
        _doPlay(VerseRef(surah, verse));
      } else {
        _snack('Sambungkan ke Internet');
      }
    } on SocketException {
      _snack('Sambungkan ke Internet');
    }
  }

  void _loadTranslation() {
    final pg = _pages[_pgIdx];
    final results = <Map<String, dynamic>>[];
    for (final v in pg.verses) {
      final text = q.getVerseTranslation(
        v.surah,
        v.verse,
        translation: _selectedTranslation,
      );
      results.add({'surah': v.surah, 'verse': v.verse, 'text': text});
    }
    setState(() => _translationVerses = results);
  }

  void _showTranslationDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => TranslationDialog(
            onSelect: (Translation selected) {
              final name =
                  language.entries.firstWhere((e) => e.value == selected).key;
              setState(() {
                _selectedTranslation = selected;
                _selectedLanguageName = name;
              });
              _loadTranslation();
            },
          ),
    );
  }

  void _showTajwidLegend() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TajwidLegend(),
    );
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.gold,
          onPressed: () {},
        ),
      ),
    );
  }

  void _jumpToSurah(int s) {
    int idx = 0;
    for (int i = 0; i < _pages.length; i++) {
      if (_pages[i].verses.any((v) => v.surah == s && v.verse == 1)) {
        idx = i;
        break;
      }
    }
    _apply(idx);
  }

  void _goSurah(int s) {
    _jumpToSurah(s);
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _jumpToJuz(int juz) {
    int idx = 0;
    for (int i = 0; i < _pages.length; i++) {
      if (_pages[i].verses.any(
        (v) => q.getJuzNumber(v.surah, v.verse) == juz,
      )) {
        idx = i;
        break;
      }
    }
    _apply(idx);
  }

  void _goJuz(int juz) {
    _jumpToJuz(juz);
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _jumpToPage(int idx) {
    _apply(idx.clamp(0, _pages.length - 1));
  }

  void _goPage(int idx) {
    _jumpToPage(idx);
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _jumpToBookmark(BookmarkEntry bm) {
    _apply(bm.pageIdx);
  }

  void _goBookmark(BookmarkEntry bm) {
    _jumpToBookmark(bm);
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _apply(int pageIdx) {
    setState(() {
      _pgIdx = pageIdx;
      _curS = _pages[pageIdx].surah;
      _playV = 0;
      _tappedSurah = 0;
      _tappedVerse = 0;
      if (_playing) {
        _audio.stop();
        _playing = false;
      }
    });
    final currentVirtual = _pageCtrl.page?.round() ?? (_pages.length * 500);
    final currentReal = currentVirtual % _pages.length;
    final diff = pageIdx - currentReal;
    _pageCtrl.jumpToPage(currentVirtual + diff);
    _savePrefs();
    if (_translationVerses.isNotEmpty) _loadTranslation();
  }

  void _toggleBookmark(int surah, int verse) async {
    if (_isBookmarked(surah, verse)) {
      await BookmarkService.removeBookmark(surah, verse);
      setState(
        () =>
            _bookmarks.removeWhere((b) => b.surah == surah && b.verse == verse),
      );
      _snack('Penanda dihapus');
    } else {
      final entry = BookmarkEntry(
        surah: surah,
        verse: verse,
        pageIdx: _pgIdx,
        surahName: q.getSurahName(surah),
        surahNameAr: q.getSurahNameArabic(surah),
        timestamp: DateTime.now(),
      );
      await BookmarkService.addBookmark(entry);
      setState(() => _bookmarks.insert(0, entry));
      HapticFeedback.lightImpact();
      _snack('Penanda disimpan ✦');
    }
    _savePrefs();
  }

  bool _isBookmarked(int surah, int verse) =>
      _bookmarks.any((b) => b.surah == surah && b.verse == verse);

  void _showReciterDialog() {
    final settings = context.read<SettingsController>().settings;
    final currentReciter = availableReciters.firstWhere(
      (r) => r.id == settings.defaultReciterId,
      orElse: () => availableReciters[0],
    );

    showDialog(
      context: context,
      builder:
          (context) => ReciterDialog(
            currentReciter: currentReciter,
            onSelect: (Reciter selected) {
              context.read<SettingsController>().updateDefaultReciter(
                selected.id,
              );
              if (_playing) {
                _audio.stop();
                _playing = false;
              }
            },
          ),
    );
  }

  @override
  void dispose() {
    _audio.dispose();
    _pageCtrl.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        final settings = controller.settings;
        final pg = _pages[_pgIdx];
        final textColor =
            Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.dark;
        final fontScale = settings.arabicFontSize / 24.0;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: MushafDrawer(
            curSurah: _curS,
            curPageIdx: _pgIdx,
            pages: _pages,
            bookmarks: _bookmarks,
            onSurah: _goSurah,
            onJuz: _goJuz,
            onPage: _goPage,
            onPageJump: _jumpToPage,
            onBookmark: _goBookmark,
            onTranslate: _showTranslationDialog,
          ),
          appBar: _appBar(pg, textColor),
          body: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onScaleUpdate: (details) {
                    if (details.pointerCount >= 2) {
                      controller.updateArabicFontSize(
                        (settings.arabicFontSize * details.scale).clamp(
                          18.0,
                          40.0,
                        ),
                      );
                    }
                  },
                  child: _PageFlipWrapper(
                    flipAngle: _flipAngle * math.pi,
                    flipDir: _flipDir,
                    child: PageView.builder(
                      controller: _pageCtrl,
                      reverse: true,
                      itemCount: null,
                      onPageChanged: (virtualIdx) {
                        final idx = virtualIdx % _pages.length;
                        setState(() {
                          _pgIdx = idx;
                          _curS = _pages[idx].surah;
                          _tappedSurah = 0;
                          _tappedVerse = 0;

                          if (!_isAutoAdvancing) {
                            _playV = 0;
                            if (_playing) {
                              _audio.stop();
                              _playing = false;
                            }
                          }
                        });
                        _savePrefs();
                        if (_translationVerses.isNotEmpty) _loadTranslation();
                      },
                      itemBuilder: (_, virtualIdx) {
                        final idx = virtualIdx % _pages.length;
                        return MushafPage(
                          data: _pages[idx],
                          playSurah: _curS,
                          playVerse: _playV,
                          tappedSurah: _tappedSurah,
                          tappedVerse: _tappedVerse,
                          isPlayingPage: idx == _pgIdx && _playing,
                          fontScale: fontScale,
                          showTajwid: settings.showTajwid,
                          bookmarkedVerses:
                              _bookmarks
                                  .where(
                                    (b) => _pages[idx].verses.any(
                                      (v) =>
                                          v.surah == b.surah &&
                                          v.verse == b.verse,
                                    ),
                                  )
                                  .map((b) => '${b.surah}:${b.verse}')
                                  .toSet(),
                          onTapVerse: _tapVerse,
                          onBookmarkVerse: _toggleBookmark,
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (_translationVerses.isNotEmpty)
                TranslationPanel(
                  verses: _translationVerses,
                  languageName: _selectedLanguageName,
                  height: _translationPanelHeight,
                  minHeight: _minPanelH,
                  maxHeight: _maxPanelH,
                  onHeightChanged:
                      (h) => setState(() => _translationPanelHeight = h),
                  onClose: () => setState(() => _translationVerses = []),
                ),
              BottomBar(
                playing: _playing,
                reciter: settings.defaultReciterId,
                pageNum: pg.pageNum,
                surahName: pg.surahName,
                playVerse: _playV,
                onPlay: _togglePlay,
                onStop:
                    () => setState(() {
                      _audio.stop();
                      _playing = false;
                      _playV = 0;
                      _tappedSurah = 0;
                      _tappedVerse = 0;
                    }),
                fontScale: fontScale,
                onZoomIn:
                    () => controller.updateArabicFontSize(
                      (settings.arabicFontSize + 2).clamp(18.0, 40.0),
                    ),
                onZoomOut:
                    () => controller.updateArabicFontSize(
                      (settings.arabicFontSize - 2).clamp(18.0, 40.0),
                    ),
                onZoomReset: () => controller.updateArabicFontSize(24.0),
                showTajwid: settings.showTajwid,
                onToggleTajwid:
                    () => controller.toggleTajwid(!settings.showTajwid),
                onTajwidLongPress: _showTajwidLegend,
                onReciterTap: _showReciterDialog,
              ),
            ],
          ),
        );
      },
    );
  }

  AppBar _appBar(PageData pg, Color textColor) => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: IconButton(
      icon: Icon(Icons.menu_rounded, color: textColor, size: 22),
      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
    ),
    title: Column(
      children: [
        Text(
          pg.surahNameAr,
          style: AppTextStyle.quranSurahNameStyle(
            fontSize: 18,
            color: textColor,
          ),
        ),
        Text(
          pg.surahName,
          style: TextStyle(
            fontSize: 10,
            color: textColor.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
    centerTitle: true,
    actions: [
      if (_bookmarks.any(
        (b) => _pages[_pgIdx].verses.any(
          (v) => v.surah == b.surah && v.verse == b.verse,
        ),
      ))
        const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(Icons.bookmark_rounded, color: AppColors.gold, size: 18),
        ),
      Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(5),
            color: AppColors.gold.withValues(alpha: 0.08),
          ),
          child: Text(
            'Juz ${pg.juz}',
            style: AppTextStyle.quranPageInfoStyle(
              fontSize: 11,
              color: textColor,
            ),
          ),
        ),
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1.5),
      child: Container(
        height: 1.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gold.withValues(alpha: 0),
              AppColors.gold,
              textColor.withValues(alpha: 0.8),
              AppColors.gold,
              AppColors.gold.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PageFlipWrapper extends StatelessWidget {
  final double flipAngle;
  final int flipDir;
  final Widget child;
  const _PageFlipWrapper({
    required this.flipAngle,
    required this.flipDir,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([]),
      builder: (context, _) {
        return Transform(
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(flipAngle * flipDir),
          alignment: Alignment.center,
          child: child,
        );
      },
    );
  }
}
