import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quranPkg;
import 'package:quran_library/quran_library.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/app_text_style.dart';
import '../screens/translation_dailog.dart';

class ReadingScreen extends StatefulWidget {
  final int surahIndex;
  const ReadingScreen({super.key, required this.surahIndex});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  int _currentPage = 1;
  int _currentSurahIndex = 1;
  int _playingVerse = 0;

  quranPkg.Translation _selectedTranslation = quranPkg.Translation.indonesian;
  List<Map<String, dynamic>> _translationVerses = [];
  String _selectedLanguageName = "Indonesian";

  static const String _reciterName = "Abu Baker Al-shatrei";
  static const int _totalPages = 604;

  static const Color _gold      = Color(0xFFB8966E);
  static const Color _goldLight = Color(0xFFD4B896);
  static const Color _darkBrown = Color(0xFF3B2A1A);
  static const Color _pageBg    = Color(0xFFF7F2E8);
  static const Color _frameBg   = Color(0xFFCDC0A0);

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentSurahIndex = widget.surahIndex;
    _currentPage = quranPkg.getPageNumber(widget.surahIndex, 1);
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadLastRead();

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onVerseCompleted();
      }
    });
  }

  int _getSurahFromPage(int pageNum) {
    for (int s = 114; s >= 1; s--) {
      if (quranPkg.getPageNumber(s, 1) <= pageNum) return s;
    }
    return _currentSurahIndex;
  }

  void _onVerseCompleted() {
    final verseCount = quranPkg.getVerseCount(_currentSurahIndex);
    if (_playingVerse < verseCount) {
      setState(() => _playingVerse++);
      _playVerse(_currentSurahIndex, _playingVerse);
    } else {
      setState(() { _isPlaying = false; _playingVerse = 0; });
    }
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

  void _playVerse(int surah, int verse) {
    try {
      _audioPlayer.setUrl(quranPkg.getAudioURLByVerse(surah, verse));
      _audioPlayer.play();
    } catch (e) { debugPrint("Audio: $e"); }
  }

  void _togglePlay() async {
    try {
      final r = await InternetAddress.lookup('example.com');
      if (r.isNotEmpty && r[0].rawAddress.isNotEmpty) {
        if (_isPlaying) {
          _audioPlayer.pause();
        } else {
          if (_playingVerse == 0) _playingVerse = 1;
          _playVerse(_currentSurahIndex, _playingVerse);
        }
        setState(() => _isPlaying = !_isPlaying);
      } else {
        _snack('Please Connect to Internet');
      }
    } on SocketException catch (_) { _snack('Please Connect to Internet'); }
  }

  void _loadTranslation() {
    final results = <Map<String, dynamic>>[];
    // Loop semua surah & ayat, cari yang ada di halaman ini
    for (int s = 1; s <= 114; s++) {
      final verseCount = quranPkg.getVerseCount(s);
      for (int v = 1; v <= verseCount; v++) {
        if (quranPkg.getPageNumber(s, v) == _currentPage) {
          final text = quranPkg.getVerseTranslation(
            s,
            v,
            translation: _selectedTranslation,
          );
          results.add({'surah': s, 'verse': v, 'text': text});
        }
      }
    }
    setState(() {
      _translationVerses = results;
    });
  }

  void _showTranslationDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialogBox(
        onSelect: (quranPkg.Translation selected) {
          final name = language.entries
              .firstWhere((e) => e.value == selected)
              .key;
          setState(() {
            _selectedTranslation = selected;
            _selectedLanguageName = name;
          });
          _loadTranslation();
        },
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), action: SnackBarAction(label: 'OK', onPressed: () {})));

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahNameAr = quranPkg.getSurahNameArabic(_currentSurahIndex);
    final juzNum = quranPkg.getJuzNumber(_currentSurahIndex, 1);

    return ScreenUtilInit(
      designSize: const Size(392, 800),
      minTextAdapt: true,
      enableScaleText: () => false,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFFEDE7D9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFEDE7D9),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: _darkBrown),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "سُورَةُ $surahNameAr",
            style: AppTextStyle.quranSurahNameStyle(fontSize: 22),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Text(
                  "Juz $juzNum",
                  style: AppTextStyle.quranPageInfoStyle(
                      fontSize: 13, color: _darkBrown),
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
                  setState(() {
                    _currentPage = pageNum;
                    _currentSurahIndex = _getSurahFromPage(pageNum);
                    _playingVerse = 0;
                    if (_isPlaying) { _audioPlayer.stop(); _isPlaying = false; }
                  });
                  _saveLastRead();
                  if (_translationVerses.isNotEmpty) {
                    _loadTranslation();
                  }
                },
                itemBuilder: (_, idx) => _MushafPageWrapper(
                  pageNum: idx + 1,
                  playingVerse: _playingVerse,
                  isPlayingPage: (idx + 1) == _currentPage && _isPlaying,
                  gold: _gold,
                  goldLight: _goldLight,
                  darkBrown: _darkBrown,
                  pageBg: _pageBg,
                  frameBg: _frameBg,
                ),
              ),
            ),

            if (_translationVerses.isNotEmpty)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 0.8),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedLanguageName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _translationVerses = []),
                            child: Icon(Icons.close_rounded, size: 14,
                                color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ..._translationVerses.map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20, height: 20,
                              margin: const EdgeInsets.only(top: 2, right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _gold, width: 1),
                                color: _gold.withOpacity(0.08),
                              ),
                              child: Center(
                                child: Text(
                                  '${v['verse']}',
                                  style: TextStyle(
                                    fontSize: 9, color: _gold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                v['text'],
                                style: const TextStyle(fontSize: 13, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),

            _BottomBar(
              isPlaying: _isPlaying,
              reciter: _reciterName,
              pageNumber: _currentPage,
              gold: _gold,
              darkBrown: _darkBrown,
              onPlay: _togglePlay,
              onStop: () => setState(() {
                _audioPlayer.stop();
                _isPlaying = false;
                _playingVerse = 0;
              }),
              onTranslate: _showTranslationDialog,
            ),
          ],
        ),
      ),
    );
  }
}

class _MushafPageWrapper extends StatelessWidget {
  final int pageNum;
  final int playingVerse;
  final bool isPlayingPage;
  final Color gold, goldLight, darkBrown, pageBg, frameBg;

  const _MushafPageWrapper({
    required this.pageNum,
    required this.playingVerse,
    required this.isPlayingPage,
    required this.gold,
    required this.goldLight,
    required this.darkBrown,
    required this.pageBg,
    required this.frameBg,
  });

  static String _toArabicNum(int n) {
    const d = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final juzNum = quranPkg.getJuzNumber(
        quranPkg.getSurahCountByPage(pageNum) > 0
            ? (quranPkg.getSurahAndVersesFromJuz(1).keys.first)
            : 1, 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: CustomPaint(
        painter: FramePainter(
            gold: gold, goldLight: goldLight, dark: darkBrown, frameBg: frameBg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: pageBg,
              border: Border.all(color: darkBrown.withOpacity(0.3), width: 0.8),
            ),
            child: Column(
              children: [
                _PageHeader(pageNum: pageNum, gold: gold, darkBrown: darkBrown),
                _Rule(gold: gold, dark: darkBrown),
                Expanded(
                  child: _HafsVerseArea(
                    pageNum: pageNum,
                    playingVerse: playingVerse,
                    isPlayingPage: isPlayingPage,
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
                        fontSize: 13, color: darkBrown),
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
  final int playingVerse;
  final bool isPlayingPage;
  final Color gold, darkBrown;

  static const Color _hl = Color(0xFF1A6B8A);
  static const double _lh = 2.1;

  const _HafsVerseArea({
    required this.pageNum,
    required this.playingVerse,
    required this.isPlayingPage,
    required this.gold,
    required this.darkBrown,
  });

  static String _toArabic(int n) {
    const d = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  List<InlineSpan> _buildSpans(double fs) {
    final spans = <InlineSpan>[];
    final hafsStyle = QuranLibrary().hafsStyle;
    final verseStyle = hafsStyle.copyWith(fontSize: fs, height: _lh);
    final cs = (fs * 1.1).clamp(16.0, 30.0);

    int surah = 1;
    for (int s = 114; s >= 1; s--) {
      if (quranPkg.getPageNumber(s, 1) <= pageNum) { surah = s; break; }
    }

    final versesOnPage = quranPkg.getVersesTextByPage(pageNum);
    for (int i = 0; i < versesOnPage.length; i++) {
      final verseText = versesOnPage[i];
      final verseIdx = i + 1;
      final active = isPlayingPage && verseIdx == playingVerse;

      spans.add(TextSpan(
        text: "$verseText ",
        style: verseStyle.copyWith(
          color: active ? _hl : const Color(0xFF1A1008),
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          backgroundColor: active ? _hl.withOpacity(0.07) : null,
        ),
      ));

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          width: cs, height: cs,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? _hl.withOpacity(0.12) : gold.withOpacity(0.10),
            border: Border.all(color: active ? _hl : gold, width: 1),
          ),
          child: Center(
            child: Text(
              _toArabic(verseIdx),
              style: QuranLibrary().hafsStyle.copyWith(
                fontSize: (fs * 0.42).clamp(7.0, 13.0),
                color: active ? _hl : darkBrown,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ));

      spans.add(const TextSpan(text: " "));
    }
    return spans;
  }

  double _measureHeight(double fs, double maxW) {
    final hafsStyle = QuranLibrary().hafsStyle;
    final tp = TextPainter(
      text: TextSpan(
        children: quranPkg.getVersesTextByPage(pageNum).map((t) =>
          TextSpan(text: "$t  ", style: hafsStyle.copyWith(fontSize: fs, height: _lh))
        ).toList(),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    )..layout(maxWidth: maxW);
    return tp.height;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, bc) {
      final maxW = bc.maxWidth - 24.0;
      final maxH = bc.maxHeight - 8.0;

      double lo = 10.0, hi = 36.0, best = 16.0;
      for (int i = 0; i < 16; i++) {
        final mid = (lo + hi) / 2.0;
        if (_measureHeight(mid, maxW) <= maxH) {
          best = mid; lo = mid + 0.25;
        } else {
          hi = mid - 0.25;
        }
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text.rich(
          TextSpan(children: _buildSpans(best)),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
          overflow: TextOverflow.clip,
        ),
      );
    });
  }
}

class _PageHeader extends StatelessWidget {
  final int pageNum;
  final Color gold, darkBrown;
  const _PageHeader({required this.pageNum, required this.gold, required this.darkBrown});

  String _juzArabic(int n) {
    const d = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    const prefix = 'الْجُزْءُ ';
    return prefix + n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    int surah = 1;
    for (int s = 114; s >= 1; s--) {
      if (quranPkg.getPageNumber(s, 1) <= pageNum) { surah = s; break; }
    }
    final juz = quranPkg.getJuzNumber(surah, 1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_juzArabic(juz),
              style: AppTextStyle.quranPageInfoStyle(fontSize: 12, color: darkBrown)),
          Icon(Icons.star, color: gold, size: 10),
          Text("سُورَةُ ${quranPkg.getSurahNameArabic(surah)}",
              style: AppTextStyle.quranPageInfoStyle(fontSize: 12, color: darkBrown)),
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
      gradient: LinearGradient(colors: [
        gold.withOpacity(0.1), gold, dark, gold, gold.withOpacity(0.1)
      ]),
    ),
  );
}

class FramePainter extends CustomPainter {
  final Color gold, goldLight, dark, frameBg;
  const FramePainter({required this.gold, required this.goldLight, required this.dark, required this.frameBg});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = frameBg);
    _r(canvas, 0, 0, w, h, dark, 3.5);
    _r(canvas, 4, 4, w-8, h-8, gold, 1.5);
    _r(canvas, 7, 7, w-14, h-14, dark.withOpacity(0.4), 1);
    _r(canvas, 10, 10, w-20, h-20, gold.withOpacity(0.5), 0.8);
    _strip(canvas, w, h);
    for (final c in [[4.0,4.0,0.0],[w-4,4.0,math.pi/2],[4.0,h-4,-math.pi/2],[w-4,h-4,math.pi]]) {
      canvas.save(); canvas.translate(c[0],c[1]); canvas.rotate(c[2]);
      _corner(canvas); canvas.restore();
    }
    _pend(canvas, w, h, true); _pend(canvas, w, h, false);
    _side(canvas, 0, h/2, false); _side(canvas, w, h/2, true);
  }

  void _r(Canvas c, double x, double y, double w, double h, Color col, double sw) =>
    c.drawRect(Rect.fromLTWH(x,y,w,h), Paint()..color=col..style=PaintingStyle.stroke..strokeWidth=sw);

  void _strip(Canvas canvas, double w, double h) {
    final f = Paint()..color=gold.withOpacity(0.25)..style=PaintingStyle.fill;
    final s = Paint()..color=dark.withOpacity(0.5)..style=PaintingStyle.stroke..strokeWidth=0.6;
    const st = 14.0; const sz = 7.0;
    void d(double cx, double cy) {
      final p = Path()..moveTo(cx,cy-sz/2)..lineTo(cx+sz/2,cy)..lineTo(cx,cy+sz/2)..lineTo(cx-sz/2,cy)..close();
      canvas.drawPath(p,f); canvas.drawPath(p,s);
    }
    for (double x=st; x<w-st; x+=st) { d(x,4+sz/2); d(x,h-4-sz/2); }
    for (double y=st; y<h-st; y+=st) { d(4+sz/2,y); d(w-4-sz/2,y); }
  }

  void _corner(Canvas canvas) {
    const r1=16.0, r2=10.0, r3=5.0;
    canvas.drawCircle(const Offset(r1,r1), r1, Paint()..color=gold);
    canvas.drawCircle(const Offset(r1,r1), r1, Paint()..color=dark..style=PaintingStyle.stroke..strokeWidth=1);
    canvas.drawCircle(const Offset(r1,r1), r2, Paint()..color=dark.withOpacity(0.4));
    canvas.drawCircle(const Offset(r1,r1), r3, Paint()..color=gold);
    final p = Paint()..color=dark.withOpacity(0.6)..strokeWidth=0.8..style=PaintingStyle.stroke;
    for (int i=0; i<8; i++) {
      final a = i*math.pi/4;
      canvas.drawLine(Offset(r1+math.cos(a)*r3, r1+math.sin(a)*r3),
                      Offset(r1+math.cos(a)*r1, r1+math.sin(a)*r1), p);
    }
  }

  void _pend(Canvas canvas, double w, double h, bool top) {
    final cx=w/2; final y=top?0.0:h; final sy=top?1.0:-1.0;
    final p = Path()
      ..moveTo(cx-20,y)..lineTo(cx-12,y+sy*12)
      ..arcToPoint(Offset(cx+12,y+sy*12), radius:const Radius.circular(12), clockwise:!top)
      ..lineTo(cx+20,y)..close();
    canvas.drawPath(p, Paint()..color=gold);
    canvas.drawPath(p, Paint()..color=dark..style=PaintingStyle.stroke..strokeWidth=1);
    canvas.drawCircle(Offset(cx,y+sy*8), 4, Paint()..color=dark.withOpacity(0.5));
  }

  void _side(Canvas canvas, double x, double y, bool right) {
    const sz=14.0; final ox=right?x-sz:x+sz;
    final p = Path()..moveTo(x,y-sz)..lineTo(ox,y)..lineTo(x,y+sz)..lineTo(right?x-sz*0.4:x+sz*0.4,y)..close();
    canvas.drawPath(p, Paint()..color=gold);
    canvas.drawPath(p, Paint()..color=dark..style=PaintingStyle.stroke..strokeWidth=0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _BottomBar extends StatelessWidget {
  final bool isPlaying;
  final String reciter;
  final int pageNumber;
  final Color gold, darkBrown;
  final VoidCallback onPlay, onStop;
  final VoidCallback onTranslate;

  const _BottomBar({
    required this.isPlaying, required this.reciter, required this.pageNumber,
    required this.gold, required this.darkBrown,
    required this.onPlay, required this.onStop,
    required this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0,-2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _Btn(icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, active: isPlaying, gold: gold, onTap: onPlay),
          const SizedBox(width: 8),
          _Btn(icon: Icons.stop_rounded, active: false, gold: gold, onTap: onStop),
          const SizedBox(width: 8),
          _Btn(icon: Icons.translate_rounded, active: false, gold: gold, onTap: onTranslate),
          const SizedBox(width: 14),
          Container(width: 1, height: 24, color: Colors.grey.shade300),
          const SizedBox(width: 14),
          Expanded(child: Text("Reciter: $reciter",
            style: AppTextStyle.quranPageInfoStyle(fontSize: 13, color: darkBrown),
            overflow: TextOverflow.ellipsis)),
          Text("Hal. $pageNumber",
            style: AppTextStyle.quranPageInfoStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon; final bool active; final Color gold; final VoidCallback onTap;
  const _Btn({required this.icon, required this.active, required this.gold, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: active ? gold.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? gold : Colors.grey.shade300, width: 1),
        ),
        child: Icon(icon, size: 22, color: active ? gold : Colors.grey.shade600),
      ),
    );
  }
}