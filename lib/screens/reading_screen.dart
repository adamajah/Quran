import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran_pkg;
import '../constants/quran_fonts.dart';
import '../models/reciter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../constants/app_text_style.dart';
import '../services/audio_playback_coordinator.dart';
import '../utils/quran_utils.dart';
import '../utils/quran_page_index.dart';
import '../screens/translation_dialog.dart';
import '../controllers/settings_controller.dart';
import '../models/settings_model.dart';
import '../widgets/mushaf/translation_panel.dart';
import '../widgets/mushaf/verse_number_ornament.dart';
import '../services/reciter_audio_service.dart';

class ReadingScreen extends StatefulWidget {
  final int surahIndex;
  const ReadingScreen({super.key, required this.surahIndex});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _playbackOwner = Object();
  final _reciterAudioService = ReciterAudioService.instance;
  int _playRequestId = 0;

  bool _isPlaying = false;
  int _currentPage = 1;
  int _currentSurahIndex = 1;
  bool _isAutoAdvancing = false;
  int _playingVerse = 0;

  quran_pkg.Translation _selectedTranslation = quran_pkg.Translation.indonesian;
  List<Map<String, dynamic>> _translationVerses = [];
  String _selectedLanguageName = "Indonesian";
  double _translationPanelHeight = 180.h;
  static final double _minPanelH = 60.h;
  static final double _maxPanelH = 400.h;

  static const int _totalPages = 604;

  static const Color _gold = Color(0xFFB8966E);
  static const Color _goldLight = Color(0xFFD4B896);
  static const Color _darkBrown = Color(0xFF3B2A1A);

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentSurahIndex = widget.surahIndex;
    _currentPage = quran_pkg.getPageNumber(widget.surahIndex, 1);
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadLastRead();

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (!mounted) return;
        final settings = context.read<SettingsController>().settings;
        if (settings.autoPlay) {
          _onVerseCompleted();
        } else {
          AudioPlaybackCoordinator.instance.release(_playbackOwner);
          setState(() {
            _isPlaying = false;
            _playingVerse = 0;
          });
        }
      }
    });
  }

  int _getSurahFromPage(int pageNum) {
    for (int s = 114; s >= 1; s--) {
      if (quran_pkg.getPageNumber(s, 1) <= pageNum) return s;
    }
    return _currentSurahIndex;
  }

  void _onVerseCompleted() {
    int nextVerse = _playingVerse + 1;
    int nextSurah = _currentSurahIndex;

    if (nextVerse > quran_pkg.getVerseCount(nextSurah)) {
      if (nextSurah < 114) {
        nextSurah++;
        nextVerse = 1;
      } else {
        setState(() {
          _isPlaying = false;
          _playingVerse = 0;
        });
        return;
      }
    }

    final nextPage = quran_pkg.getPageNumber(nextSurah, nextVerse);

    if (nextPage != _currentPage) {
      setState(() {
        _currentPage = nextPage;
        _currentSurahIndex = nextSurah;
        _playingVerse = nextVerse;
      });

      if (_pageController.hasClients) {
        _isAutoAdvancing = true;
        _pageController
            .animateToPage(
              nextPage - 1,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            )
            .then((_) => _isAutoAdvancing = false);
      }
    } else {
      setState(() {
        _currentSurahIndex = nextSurah;
        _playingVerse = nextVerse;
      });
    }

    _playVerse(_currentSurahIndex, _playingVerse);
  }

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPage = prefs.getInt('lastReadPage') ?? _currentPage;
    if (!mounted) return;
    setState(() {
      _currentPage = lastPage.clamp(1, _totalPages);
      _currentSurahIndex = _getSurahFromPage(_currentPage);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage - 1);
      }
    });
  }

  Future<void> _saveLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastReadPage', _currentPage);
  }

  Future<void> _playVerse(int surah, int verse) async {
    final requestId = ++_playRequestId;
    final settings = context.read<SettingsController>().settings;
    final reciter = _resolveReciter(settings.defaultReciterId);
    try {
      await AudioPlaybackCoordinator.instance.requestPlayback(
        _playbackOwner,
        _stopForPlaybackHandoff,
      );
      if (requestId != _playRequestId) return;
      await _audioPlayer.setVolume(settings.defaultVolume);
      await _audioPlayer.setSpeed(settings.playbackSpeed);
      await _audioPlayer.setUrl(
        await _reciterAudioService.verseAudioUrl(reciter, surah, verse),
      );
      if (requestId != _playRequestId) return;
      unawaited(_audioPlayer.play());
    } catch (e) {
      AudioPlaybackCoordinator.instance.release(_playbackOwner);
      if (mounted) setState(() => _isPlaying = false);
      debugPrint("Audio error: $e");
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      ++_playRequestId;
      setState(() => _isPlaying = false);
      await _audioPlayer.pause();
      return;
    }

    setState(() => _isPlaying = true);
    if (_audioPlayer.processingState == ProcessingState.ready &&
        _playingVerse != 0) {
      await AudioPlaybackCoordinator.instance.requestPlayback(
        _playbackOwner,
        _stopForPlaybackHandoff,
      );
      unawaited(_audioPlayer.play());
      return;
    }

    if (_playingVerse == 0) _playingVerse = 1;
    await _playVerse(_currentSurahIndex, _playingVerse);
  }

  Future<void> _stopForPlaybackHandoff() async {
    ++_playRequestId;
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() => _isPlaying = false);
  }

  Future<void> _stopPlayback({bool resetVerse = false}) async {
    ++_playRequestId;
    await _audioPlayer.stop();
    AudioPlaybackCoordinator.instance.release(_playbackOwner);
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      if (resetVerse) _playingVerse = 0;
    });
  }

  Reciter _resolveReciter(String id) {
    return availableReciters.firstWhere(
      (reciter) => reciter.id == id,
      orElse: () => availableReciters.first,
    );
  }

  void _loadTranslation() {
    setState(() {
      _translationVerses = QuranPageIndex.translationsForPage(
        _currentPage,
        _selectedTranslation,
      );
    });
  }

  Future<void> _showTranslationDialog() async {
    if (_isPlaying) {
      await _stopPlayback(resetVerse: false);
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => TranslationDialog(
            onSelect: (quran_pkg.Translation selected) {
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

  @override
  void dispose() {
    AudioPlaybackCoordinator.instance.release(_playbackOwner);
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        final settings = controller.settings;
        final reciter = _resolveReciter(settings.defaultReciterId);
        final surahNameAr = quran_pkg.getSurahNameArabic(_currentSurahIndex);
        final juzNum = quran_pkg.getJuzNumber(_currentSurahIndex, 1);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor =
            isDark
                ? Colors.white
                : (Theme.of(context).textTheme.bodyLarge?.color ?? _darkBrown);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                size: 18,
                color: textColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "سُورَةُ $surahNameAr",
              style: AppTextStyle.quranSurahNameStyle(
                fontSize: 22,
              ).copyWith(color: textColor),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: Text(
                    "Juz $juzNum",
                    style: AppTextStyle.quranPageInfoStyle(
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  reverse: true,
                  itemCount: _totalPages,
                  onPageChanged: (idx) {
                    final pageNum = idx + 1;
                    if (_isPlaying && !_isAutoAdvancing) {
                      unawaited(_stopPlayback(resetVerse: true));
                    }
                    setState(() {
                      _currentPage = pageNum;
                      _currentSurahIndex = _getSurahFromPage(pageNum);
                      _playingVerse = 0;
                      if (!_isAutoAdvancing) _isPlaying = false;
                    });
                    _saveLastRead();
                    if (_translationVerses.isNotEmpty) {
                      _loadTranslation();
                    }
                  },
                  itemBuilder:
                      (_, idx) => _MushafPageWrapper(
                        pageNum: idx + 1,
                        playingSurah: _currentSurahIndex,
                        playingVerse: _playingVerse,
                        isPlayingPage: (idx + 1) == _currentPage && _isPlaying,
                        settings: settings,
                        gold: _gold,
                        goldLight: _goldLight,
                        darkBrown: textColor,
                      ),
                ),
              ),

              if (_translationVerses.isNotEmpty)
                TranslationPanel(
                  languageName: _selectedLanguageName,
                  verses: _translationVerses,
                  height: _translationPanelHeight,
                  minHeight: _minPanelH,
                  maxHeight: _maxPanelH,
                  onHeightChanged:
                      (h) => setState(() => _translationPanelHeight = h),
                  onClose: () => setState(() => _translationVerses = []),
                ),

              _BottomBar(
                isPlaying: _isPlaying,
                reciter: reciter.name,
                pageNumber: _currentPage,
                gold: _gold,
                textColor: textColor,
                onPlay: _togglePlay,
                onStop: () => _stopPlayback(resetVerse: true),
                onTranslate: () => unawaited(_showTranslationDialog()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MushafPageWrapper extends StatelessWidget {
  final int pageNum;
  final int playingSurah;
  final int playingVerse;
  final bool isPlayingPage;
  final AppSettings settings;
  final Color gold, goldLight, darkBrown;

  const _MushafPageWrapper({
    required this.pageNum,
    required this.playingSurah,
    required this.playingVerse,
    required this.isPlayingPage,
    required this.settings,
    required this.gold,
    required this.goldLight,
    required this.darkBrown,
  });

  static String _toArabicNum(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: CustomPaint(
        painter: FramePainter(
          gold: gold,
          goldLight: goldLight,
          dark: darkBrown,
          frameBg: Theme.of(context).cardColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(
                color: darkBrown.withValues(alpha: 0.1),
                width: 0.8,
              ),
            ),
            child: Column(
              children: [
                _PageHeader(pageNum: pageNum, gold: gold, darkBrown: darkBrown),
                _Rule(gold: gold, dark: darkBrown),
                Expanded(
                  child: _HafsVerseArea(
                    pageNum: pageNum,
                    playingSurah: playingSurah,
                    playingVerse: playingVerse,
                    isPlayingPage: isPlayingPage,
                    settings: settings,
                    gold: gold,
                    darkBrown: darkBrown,
                  ),
                ),
                _Rule(gold: gold, dark: darkBrown),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    _toArabicNum(pageNum),
                    textAlign: TextAlign.center,
                    style: AppTextStyle.quranPageInfoStyle(
                      fontSize: 13,
                      color: darkBrown,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HafsVerseArea extends StatelessWidget {
  final int pageNum;
  final int playingSurah;
  final int playingVerse;
  final bool isPlayingPage;
  final AppSettings settings;
  final Color gold, darkBrown;

  static const Color _hl = Color(0xFF1A6B8A);

  const _HafsVerseArea({
    required this.pageNum,
    required this.playingSurah,
    required this.playingVerse,
    required this.isPlayingPage,
    required this.settings,
    required this.gold,
    required this.darkBrown,
  });

  List<InlineSpan> _buildSpans(double fs) {
    final spans = <InlineSpan>[];
    final quranStyle = AppQuranFonts.styleFor(settings.mushafFont);
    final textScale = AppQuranFonts.textScaleFor(settings.mushafFont);
    final lineHeight =
        settings.lineSpacing *
        AppQuranFonts.readingLineHeightScaleFor(settings.mushafFont);
    final scaledFs = fs * textScale;
    final verseStyle = quranStyle.copyWith(
      fontSize: scaledFs,
      height: lineHeight,
    );

    final versesOnPage = quran_pkg.getVersesTextByPage(pageNum);
    for (int i = 0; i < versesOnPage.length; i++) {
      final verseText = QuranUtils.cleanText(versesOnPage[i]);
      final verseIdx = i + 1;
      final active = isPlayingPage && verseIdx == playingVerse;

      spans.add(
        TextSpan(
          text: "$verseText ",
          style: verseStyle.copyWith(
            color: active ? _hl : darkBrown,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            backgroundColor: active ? _hl.withValues(alpha: 0.07) : null,
          ),
        ),
      );

      if (settings.showVerseNumbers) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: VerseNumberOrnament(
                verse: verseIdx,
                mushafFont: settings.mushafFont,
                fontSize: (scaledFs * 0.90).clamp(14.0, 24.0),
                color: active ? _hl : gold,
                height: lineHeight,
              ),
            ),
          ),
        );
      }

      spans.add(const TextSpan(text: " "));
    }
    return spans;
  }

  double _measureHeight(double fs, double maxW) {
    final quranStyle = AppQuranFonts.styleFor(settings.mushafFont);
    final textScale = AppQuranFonts.textScaleFor(settings.mushafFont);
    final lineHeight =
        settings.lineSpacing *
        AppQuranFonts.readingLineHeightScaleFor(settings.mushafFont);
    final verses = quran_pkg.getVersesTextByPage(pageNum);
    final tp = TextPainter(
      text: TextSpan(
        children:
            verses
                .asMap()
                .entries
                .map(
                  (entry) => TextSpan(
                    text:
                        '${QuranUtils.cleanText(entry.value)} '
                        '${settings.showVerseNumbers ? VerseNumberOrnament.measurementTextFor(entry.key + 1, settings.mushafFont) : ''} ',
                    style: quranStyle.copyWith(
                      fontSize: fs * textScale,
                      height: lineHeight,
                    ),
                  ),
                )
                .toList(),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    )..layout(maxWidth: maxW);
    return tp.height;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, bc) {
        final maxW = bc.maxWidth - 24.0;
        final maxH = bc.maxHeight - 8.0;

        // Calculate the base font size based on settings.arabicFontSize
        // We still use the dynamic fitting but scale it relative to the user's preference
        double baseFS = settings.arabicFontSize;

        // Fitting logic
        double lo = 10.0, hi = 45.0, best = baseFS;
        for (int i = 0; i < 16; i++) {
          final mid = (lo + hi) / 2.0;
          if (_measureHeight(mid, maxW) <= maxH) {
            best = mid;
            lo = mid + 0.25;
          } else {
            hi = mid - 0.25;
          }
        }

        // Respect user's max font size preference as a ceiling
        final finalFS = best.clamp(18.0, settings.arabicFontSize);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text.rich(
            TextSpan(children: _buildSpans(finalFS)),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            overflow: TextOverflow.clip,
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  final int pageNum;
  final Color gold, darkBrown;
  const _PageHeader({
    required this.pageNum,
    required this.gold,
    required this.darkBrown,
  });

  String _juzArabic(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const prefix = 'الْجُزْءُ ';
    return prefix + n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    int surah = 1;
    for (int s = 114; s >= 1; s--) {
      if (quran_pkg.getPageNumber(s, 1) <= pageNum) {
        surah = s;
        break;
      }
    }
    final juz = quran_pkg.getJuzNumber(surah, 1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _juzArabic(juz),
            style: AppTextStyle.quranPageInfoStyle(
              fontSize: 12,
              color: darkBrown,
            ),
          ),
          Icon(Icons.star, color: gold, size: 10),
          Text(
            "سُورَةُ ${quran_pkg.getSurahNameArabic(surah)}",
            style: AppTextStyle.quranPageInfoStyle(
              fontSize: 12,
              color: darkBrown,
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final Color gold, dark;
  const _Rule({required this.gold, required this.dark});
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          gold.withValues(alpha: 0.1),
          gold,
          dark,
          gold,
          gold.withValues(alpha: 0.1),
        ],
      ),
    ),
  );
}

class FramePainter extends CustomPainter {
  final Color gold, goldLight, dark, frameBg;
  const FramePainter({
    required this.gold,
    required this.goldLight,
    required this.dark,
    required this.frameBg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = frameBg);
    _r(canvas, 0, 0, w, h, dark.withValues(alpha: 0.8), 3.5);
    _r(canvas, 4, 4, w - 8, h - 8, gold, 1.5);
    _r(canvas, 7, 7, w - 14, h - 14, dark.withValues(alpha: 0.3), 1);
    _r(canvas, 10, 10, w - 20, h - 20, gold.withValues(alpha: 0.5), 0.8);
    _strip(canvas, w, h);
    for (final c in [
      [4.0, 4.0, 0.0],
      [w - 4, 4.0, math.pi / 2],
      [4.0, h - 4, -math.pi / 2],
      [w - 4, h - 4, math.pi],
    ]) {
      canvas.save();
      canvas.translate(c[0], c[1]);
      canvas.rotate(c[2]);
      _corner(canvas);
      canvas.restore();
    }
    _pend(canvas, w, h, true);
    _pend(canvas, w, h, false);
    _side(canvas, 0, h / 2, false);
    _side(canvas, w, h / 2, true);
  }

  void _r(
    Canvas c,
    double x,
    double y,
    double w,
    double h,
    Color col,
    double sw,
  ) => c.drawRect(
    Rect.fromLTWH(x, y, w, h),
    Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw,
  );

  void _strip(Canvas canvas, double w, double h) {
    final f =
        Paint()
          ..color = gold.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
    final s =
        Paint()
          ..color = dark.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6;
    const st = 14.0;
    const sz = 7.0;
    void d(double cx, double cy) {
      final p =
          Path()
            ..moveTo(cx, cy - sz / 2)
            ..lineTo(cx + sz / 2, cy)
            ..lineTo(cx, cy + sz / 2)
            ..lineTo(cx - sz / 2, cy)
            ..close();
      canvas.drawPath(p, f);
      canvas.drawPath(p, s);
    }

    for (double x = st; x < w - st; x += st) {
      d(x, 4 + sz / 2);
      d(x, h - 4 - sz / 2);
    }
    for (double y = st; y < h - st; y += st) {
      d(4 + sz / 2, y);
      d(w - 4 - sz / 2, y);
    }
  }

  void _corner(Canvas canvas) {
    const r1 = 16.0, r2 = 10.0, r3 = 5.0;
    canvas.drawCircle(const Offset(r1, r1), r1, Paint()..color = gold);
    canvas.drawCircle(
      const Offset(r1, r1),
      r1,
      Paint()
        ..color = dark.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      const Offset(r1, r1),
      r2,
      Paint()..color = dark.withValues(alpha: 0.4),
    );
    canvas.drawCircle(const Offset(r1, r1), r3, Paint()..color = gold);
    final p =
        Paint()
          ..color = dark.withValues(alpha: 0.6)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(r1 + math.cos(a) * r3, r1 + math.sin(a) * r3),
        Offset(r1 + math.cos(a) * r1, r1 + math.sin(a) * r1),
        p,
      );
    }
  }

  void _pend(Canvas canvas, double w, double h, bool top) {
    final cx = w / 2;
    final y = top ? 0.0 : h;
    final sy = top ? 1.0 : -1.0;
    final p =
        Path()
          ..moveTo(cx - 20, y)
          ..lineTo(cx - 12, y + sy * 12)
          ..arcToPoint(
            Offset(cx + 12, y + sy * 12),
            radius: const Radius.circular(12),
            clockwise: !top,
          )
          ..lineTo(cx + 20, y)
          ..close();
    canvas.drawPath(p, Paint()..color = gold);
    canvas.drawPath(
      p,
      Paint()
        ..color = dark.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(cx, y + sy * 8),
      4,
      Paint()..color = dark.withValues(alpha: 0.5),
    );
  }

  void _side(Canvas canvas, double x, double y, bool right) {
    const sz = 14.0;
    final ox = right ? x - sz : x + sz;
    final p =
        Path()
          ..moveTo(x, y - sz)
          ..lineTo(ox, y)
          ..lineTo(x, y + sz)
          ..lineTo(right ? x - sz * 0.4 : x + sz * 0.4, y)
          ..close();
    canvas.drawPath(p, Paint()..color = gold);
    canvas.drawPath(
      p,
      Paint()
        ..color = dark.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}

class _BottomBar extends StatelessWidget {
  final bool isPlaying;
  final String reciter;
  final int pageNumber;
  final Color gold, textColor;
  final VoidCallback onPlay, onStop;
  final VoidCallback onTranslate;

  const _BottomBar({
    required this.isPlaying,
    required this.reciter,
    required this.pageNumber,
    required this.gold,
    required this.textColor,
    required this.onPlay,
    required this.onStop,
    required this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06,
            ),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _Btn(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            active: isPlaying,
            gold: gold,
            onTap: onPlay,
          ),
          const SizedBox(width: 8),
          _Btn(
            icon: Icons.stop_rounded,
            active: false,
            gold: gold,
            onTap: onStop,
          ),
          const SizedBox(width: 8),
          _Btn(
            icon: Icons.translate_rounded,
            active: false,
            gold: gold,
            onTap: onTranslate,
          ),
          const SizedBox(width: 14),
          Container(
            width: 1,
            height: 24,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.grey.shade300,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "Qari: $reciter",
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "Hal. $pageNumber",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color gold;
  final VoidCallback onTap;
  const _Btn({
    required this.icon,
    required this.active,
    required this.gold,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color:
              active
                  ? gold.withValues(alpha: 0.12)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                active
                    ? gold
                    : (isDark ? Colors.white10 : Colors.grey.shade300),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color:
              active ? gold : (isDark ? Colors.white70 : Colors.grey.shade600),
        ),
      ),
    );
  }
}
