import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as q;
import 'package:quran/quran.dart' show Translation;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../services/bookmark_service.dart';
import '../services/audio_playback_coordinator.dart';
import '../services/offline_reciter_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_style.dart';
import '../models/verse_ref.dart';
import '../screens/translation_dialog.dart';
import '../models/reciter.dart';
import '../screens/reciter_dialog.dart';
import '../widgets/common/bottom_bar.dart';
import '../widgets/common/mushaf_drawer.dart';
import '../widgets/mushaf/mushaf_page.dart';
import '../widgets/mushaf/tajwid_guide.dart';
import '../widgets/mushaf/translation_panel.dart';
import '../controllers/settings_controller.dart';
import '../utils/quran_page_index.dart';
import '../services/reciter_audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  AudioPlayer? _audio;
  final _playbackOwner = Object();
  final _reciterService = OfflineReciterService();
  final _reciterAudioService = ReciterAudioService.instance;
  late PageController _pageCtrl;

  // Playback
  bool _playing = false;
  int _pgIdx = 0;
  int _playV = 0;
  int _curS = 1;
  Reciter _selectedReciter = availableReciters.first;
  List<AyahTiming> _streamAyahTimings = const [];
  Duration? _streamDuration;
  int? _streamSurah;
  StreamSubscription<Duration>? _positionSubscription;
  int _playRequestId = 0;
  StreamSubscription<PlayerState>? _audioStateSubscription;

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

  late final QuranPageCatalog _pages;
  bool _isAutoAdvancing = false;
  int? _pendingPageSurah;
  int? _pendingPageSurahIdx;
  double _pageZoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pages = QuranPageCatalog();
    _pageCtrl = PageController(initialPage: QuranPageCatalog.totalPages * 500);
    _loadPrefs();
  }

  Future<AudioPlayer> _ensureAudioPlayer() async {
    if (_audio != null) return _audio!;

    final player = AudioPlayer();
    _audio = player;
    _positionSubscription ??= player.positionStream.listen(_syncStreamAyah);
    _audioStateSubscription = player.playerStateStream.listen(_onAudioState);
    return player;
  }

  void _onAudioState(PlayerState s) {
    if (s.processingState != ProcessingState.completed) return;
    if (!mounted) return;

    if (_selectedReciter.usesSurahAudioStream) {
      setState(() {
        _playing = false;
        _playV = 0;
        _tappedSurah = 0;
        _tappedVerse = 0;
      });
      _clearStreamPlayback();
      AudioPlaybackCoordinator.instance.release(_playbackOwner);
      return;
    }

    final settings = context.read<SettingsController>().settings;
    if (!settings.autoPlay) {
      setState(() => _playing = false);
      AudioPlaybackCoordinator.instance.release(_playbackOwner);
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
        _setPendingPageSurah(nextPgIdx, nextV.surah);

        if (_pageCtrl.hasClients) {
          final currentVirtual =
              _pageCtrl.page?.round() ?? (QuranPageCatalog.totalPages * 500);
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
        AudioPlaybackCoordinator.instance.release(_playbackOwner);
      }
    }
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final lastSurah = p.getInt('lastSurah') ?? 1;
    final bookmarks = await BookmarkService.getBookmarks();

    if (!mounted) return;
    final idx = q.getPageNumber(lastSurah, 1) - 1;
    setState(() {
      _curS = lastSurah;
      _pgIdx = idx;
      _bookmarks = bookmarks;
    });
    _setPendingPageSurah(idx, lastSurah);
    _restoreSelectedReciter(lastSurah);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageCtrl.hasClients) {
        _pageCtrl.jumpToPage(QuranPageCatalog.totalPages * 500 + idx);
      }
    });
  }

  void _togglePageZoom() {
    HapticFeedback.selectionClick();
    setState(() {
      _pageZoomScale = _pageZoomScale == 1.0 ? 1.18 : 1.0;
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('lastSurah', _curS);
    await p.setInt('lastPage', _pgIdx);
  }

  Future<void> _restoreSelectedReciter(int surah) async {
    final id = context.read<SettingsController>().settings.defaultReciterId;
    final reciter = await _reciterService.findReciterForSurah(id, surah);
    if (!mounted || reciter == null) return;
    setState(() => _selectedReciter = reciter);
  }

  Future<void> _doPlay(VerseRef r) async {
    final requestId = ++_playRequestId;
    final settings = context.read<SettingsController>().settings;
    try {
      final audio = await _ensureAudioPlayer();
      await AudioPlaybackCoordinator.instance.requestPlayback(
        _playbackOwner,
        _stopForPlaybackHandoff,
      );
      if (requestId != _playRequestId) return;

      final reciter =
          await _reciterService.findReciterForSurah(
            settings.defaultReciterId,
            r.surah,
          ) ??
          _selectedReciter;
      if (reciter.usesSurahAudioStream &&
          !reciter.supportsSurahDownload(r.surah)) {
        AudioPlaybackCoordinator.instance.release(_playbackOwner);
        if (mounted) setState(() => _playing = false);
        _snack('Qari ini belum menyediakan audio untuk surat tersebut');
        return;
      }

      if (mounted && reciter.id != _selectedReciter.id) {
        setState(() => _selectedReciter = reciter);
      }

      await audio.setVolume(settings.defaultVolume);
      await audio.setSpeed(settings.playbackSpeed);
      if (reciter.usesSurahAudioStream) {
        final duration = await audio.setUrl(reciter.surahAudioUrl(r.surah));
        if (requestId != _playRequestId) return;
        final timings = await _reciterService.getAyahTimings(reciter, r.surah);
        if (requestId != _playRequestId) return;
        _streamSurah = r.surah;
        _streamDuration = duration;
        _streamAyahTimings = timings;
        if (r.verse > 1) {
          final position =
              _startPositionForAyah(timings, r.verse) ??
              _estimateAyahPosition(duration, r.surah, r.verse);
          if (position != null) await audio.seek(position);
        }
      } else {
        _clearStreamPlayback();
        await audio.setUrl(
          await _reciterAudioService.verseAudioUrl(reciter, r.surah, r.verse),
        );
        if (requestId != _playRequestId) return;
      }
      unawaited(audio.play());
      if (mounted) {
        setState(() {
          _playing = true;
          _tappedSurah = 0;
          _tappedVerse = 0;
        });
      }
    } catch (e) {
      AudioPlaybackCoordinator.instance.release(_playbackOwner);
      debugPrint('Audio: $e');
      if (mounted) setState(() => _playing = false);
      _snack('Audio gagal diputar. Silakan coba lagi.');
    }
  }

  Duration? _estimateAyahPosition(Duration? duration, int surah, int ayah) {
    if (duration == null || ayah <= 1) return null;
    final verseCount = q.getVerseCount(surah);
    return Duration(
      milliseconds: (duration.inMilliseconds * (ayah - 1) / verseCount).round(),
    );
  }

  Duration? _startPositionForAyah(List<AyahTiming> timings, int ayah) {
    for (final timing in timings) {
      if (timing.ayah == ayah) return timing.start;
    }
    return null;
  }

  void _syncStreamAyah(Duration position) {
    final surah = _streamSurah;
    if (!_playing || surah == null || !_selectedReciter.usesSurahAudioStream) {
      return;
    }

    final ayah =
        OfflineReciterService.findAyahForPosition(
          _streamAyahTimings,
          position,
        ) ??
        _estimateAyahForPosition(position, _streamDuration, surah);
    if (ayah == null || (_curS == surah && _playV == ayah)) return;

    setState(() {
      _curS = surah;
      _playV = ayah;
      _tappedSurah = 0;
      _tappedVerse = 0;
    });
    _showPlayingAyahPage(surah, ayah);
  }

  int? _estimateAyahForPosition(
    Duration position,
    Duration? duration,
    int surah,
  ) {
    if (duration == null || duration.inMilliseconds <= 0) return null;
    final verseCount = q.getVerseCount(surah);
    return (position.inMilliseconds * verseCount / duration.inMilliseconds)
            .floor()
            .clamp(0, verseCount - 1) +
        1;
  }

  void _showPlayingAyahPage(int surah, int ayah) {
    final pageIdx = q.getPageNumber(surah, ayah) - 1;
    if (pageIdx == _pgIdx || !_pageCtrl.hasClients) return;

    setState(() => _pgIdx = pageIdx);
    _setPendingPageSurah(pageIdx, surah);
    final currentVirtual =
        _pageCtrl.page?.round() ?? (QuranPageCatalog.totalPages * 500);
    final currentReal = currentVirtual % _pages.length;
    _isAutoAdvancing = true;
    _pageCtrl
        .animateToPage(
          currentVirtual + pageIdx - currentReal,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        )
        .whenComplete(() => _isAutoAdvancing = false);
  }

  void _clearStreamPlayback() {
    _streamSurah = null;
    _streamDuration = null;
    _streamAyahTimings = const [];
  }

  Future<void> _stopForPlaybackHandoff() async {
    ++_playRequestId;
    final audio = _audio;
    if (audio != null) await audio.stop();
    _clearStreamPlayback();
    if (!mounted) return;
    setState(() => _playing = false);
  }

  Future<void> _stopPlayback({bool resetVerse = false}) async {
    ++_playRequestId;
    final audio = _audio;
    if (audio != null) await audio.stop();
    AudioPlaybackCoordinator.instance.release(_playbackOwner);
    _clearStreamPlayback();
    if (!mounted) return;
    setState(() {
      _playing = false;
      if (resetVerse) {
        _playV = 0;
        _tappedSurah = 0;
        _tappedVerse = 0;
      }
    });
  }

  void _cancelPlaybackRequest() {
    ++_playRequestId;
    AudioPlaybackCoordinator.instance.release(_playbackOwner);
    _clearStreamPlayback();
    final audio = _audio;
    if (audio != null) unawaited(audio.stop());
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      ++_playRequestId;
      if (mounted) setState(() => _playing = false);
      final audio = _audio;
      if (audio != null) await audio.pause();
      return;
    }

    if (mounted) setState(() => _playing = true);
    final audio = await _ensureAudioPlayer();
    if (audio.processingState == ProcessingState.ready && _playV != 0) {
      await AudioPlaybackCoordinator.instance.requestPlayback(
        _playbackOwner,
        _stopForPlaybackHandoff,
      );
      unawaited(audio.play());
      return;
    }

    final pg = _pages[_pgIdx];
    if (_playV == 0) _playV = pg.verses.first.verse;
    await _doPlay(
      pg.verses.firstWhere(
        (r) => r.verse == _playV,
        orElse: () => pg.verses.first,
      ),
    );
  }

  Future<void> _tapVerse(int surah, int verse) async {
    setState(() {
      _tappedSurah = surah;
      _tappedVerse = verse;
      _playV = verse;
      _curS = surah;
      _playing = true;
    });
    await _doPlay(VerseRef(surah, verse));
  }

  void _loadTranslation() {
    setState(() {
      _translationVerses = QuranPageIndex.translationsForPage(
        _pages[_pgIdx].pageNum,
        _selectedTranslation,
      );
    });
  }

  Future<void> _showTranslationDialog() async {
    if (!mounted) return;
    if (_playing) {
      await _stopPlayback(resetVerse: false);
    }
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
    _apply(q.getPageNumber(s, 1) - 1, preferredSurah: s);
  }

  void _goSurah(int s) {
    _jumpToSurah(s);
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _jumpToJuz(int juz) {
    for (int s = 1; s <= q.totalSurahCount; s++) {
      final cnt = q.getVerseCount(s);
      for (int v = 1; v <= cnt; v++) {
        if (q.getJuzNumber(s, v) == juz) {
          _apply(q.getPageNumber(s, v) - 1, preferredSurah: s);
          return;
        }
      }
    }
    _apply(0);
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
    _apply(bm.pageIdx, preferredSurah: bm.surah);
  }

  void _goBookmark(BookmarkEntry bm) {
    _jumpToBookmark(bm);
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  int _resolvePageSurah(int pageIdx, {int? preferredSurah}) {
    return QuranPageIndex.resolveSurahForPage(
      _pages[pageIdx].verses,
      preferredSurah: preferredSurah,
    );
  }

  void _setPendingPageSurah(int pageIdx, int? preferredSurah) {
    _pendingPageSurahIdx = pageIdx;
    _pendingPageSurah = _resolvePageSurah(
      pageIdx,
      preferredSurah: preferredSurah,
    );
  }

  void _apply(int pageIdx, {int? preferredSurah}) {
    _cancelPlaybackRequest();
    _setPendingPageSurah(pageIdx, preferredSurah);
    setState(() {
      _pgIdx = pageIdx;
      _curS = _pendingPageSurah!;
      _playV = 0;
      _tappedSurah = 0;
      _tappedVerse = 0;
      _playing = false;
    });
    final currentVirtual =
        _pageCtrl.page?.round() ?? (QuranPageCatalog.totalPages * 500);
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
    showDialog(
      context: context,
      builder:
          (context) => ReciterDialog(
            currentReciter: _selectedReciter,
            surah: _curS,
            onSelect: (Reciter selected) {
              context.read<SettingsController>().updateDefaultReciter(
                selected.id,
              );
              setState(() => _selectedReciter = selected);
              if (_playing) {
                _cancelPlaybackRequest();
                _playing = false;
              }
            },
          ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _audioStateSubscription?.cancel();
    AudioPlaybackCoordinator.instance.release(_playbackOwner);
    _audio?.dispose();
    _pageCtrl.dispose();
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
        final fontScale = (settings.arabicFontSize / 24.0) * _pageZoomScale;

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
            onTranslate: () => unawaited(_showTranslationDialog()),
          ),
          appBar: _appBar(pg, textColor),
          body: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onDoubleTap: _togglePageZoom,
                  child: RepaintBoundary(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      reverse: true,
                      itemCount: null,
                      allowImplicitScrolling: false,
                      onPageChanged: (virtualIdx) {
                        final idx = virtualIdx % _pages.length;
                        final preferredSurah =
                            idx == _pendingPageSurahIdx
                                ? _pendingPageSurah
                                : null;
                        final surah = _resolvePageSurah(
                          idx,
                          preferredSurah: preferredSurah,
                        );
                        _pendingPageSurah = null;
                        _pendingPageSurahIdx = null;
                        if (!_isAutoAdvancing) _cancelPlaybackRequest();
                        setState(() {
                          _pgIdx = idx;
                          _curS = surah;
                          _tappedSurah = 0;
                          _tappedVerse = 0;

                          if (!_isAutoAdvancing) {
                            _playV = 0;
                            _playing = false;
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
                          isPlayingPage: idx == _pgIdx && _playV != 0,
                          fontScale: fontScale,
                          mushafFont: settings.mushafFont,
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
                reciter: _selectedReciter.name,
                pageNum: pg.pageNum,
                surahName: pg.surahName,
                playVerse: _playV,
                onPlay: _togglePlay,
                onStop: () => _stopPlayback(resetVerse: true),
                zoomScale: _pageZoomScale,
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
