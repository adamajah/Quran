// ─────────────────────────────────────────────────────────────────────────────
// home_screen.dart  –  Mushaf Al-Quran Digital  (modularized)
// ─────────────────────────────────────────────────────────────────────────────
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as q;
import 'package:quran_library/quran_library.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_style.dart';
import '../models/verse_ref.dart';
import '../utils/mushaf_builder.dart';
import '../widgets/common/bottom_bar.dart';
import '../widgets/common/tajwid_legend.dart';
import '../widgets/mushaf/fatihah_page.dart';
import '../widgets/mushaf/normal_page.dart';
import '../widgets/mushaf/page_elements.dart';
import 'hafalan_screen.dart';
import 'translation_dailog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final List<PageData> _pages;
  late final PageController _pageCtrl;
  int _curPage = 0;

  // Audio
  final _audioPlayer = AudioPlayer();
  bool _playing = false;
  int _playSurah = 0, _playVerse = 0;
  String _reciter = 'Mishary Rashid Alafasy';

  // Translation
  bool _showTranslation = false;
  int _transLangIdx = 0;

  // Tajwid
  bool _showTajwid = true;

  // Font scale
  double _fontScale = 1.0;

  // Tap tracking
  int _tappedSurah = 0, _tappedVerse = 0;

  // Page flip animation
  bool _flipping = false;
  double _flipAngle = 0;
  int _flipFromPage = 0;

  // Bookmarks
  final List<BookmarkEntry> _bookmarks = [];
  final Set<String> _bookmarkedVerses = {};

  @override
  void initState() {
    super.initState();
    _pages = buildMushafPages();
    _pageCtrl = PageController(initialPage: _curPage);
    _audioPlayer.playerStateStream.listen(_onAudioState);
    _loadBookmarks();
  }

  @override void dispose() { _audioPlayer.dispose(); _pageCtrl.dispose(); super.dispose(); }

  // ─── Bookmarks ────────────────────────────────────────────────────────────
  Future<void> _loadBookmarks() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('mushaf_bookmarks') ?? [];
    for (final s in raw) {
      try {
        final bm = BookmarkEntry.fromJson(jsonDecode(s));
        _bookmarks.add(bm);
        _bookmarkedVerses.add('${bm.surah}:${bm.verse}');
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveBookmarks() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('mushaf_bookmarks',
        _bookmarks.map((b) => jsonEncode(b.toJson())).toList());
  }

  void _toggleBookmark(int surah, int verse) {
    final key = '$surah:$verse';
    setState(() {
      if (_bookmarkedVerses.contains(key)) {
        _bookmarkedVerses.remove(key);
        _bookmarks.removeWhere((b) => b.surah == surah && b.verse == verse);
        _snack('Bookmark dihapus');
      } else {
        final pgIdx = _pages.indexWhere((p) =>
            p.verses.any((v) => v.surah == surah && v.verse == verse));
        _bookmarks.insert(0, BookmarkEntry(
          surah: surah, verse: verse, pageIdx: pgIdx,
          surahName: q.getSurahName(surah), surahNameAr: q.getSurahNameArabic(surah),
        ));
        _bookmarkedVerses.add(key);
        _snack('Bookmark disimpan ✦ ${q.getSurahName(surah)} : $verse');
      }
    });
    _saveBookmarks();
    HapticFeedback.lightImpact();
  }

  // ─── Audio ────────────────────────────────────────────────────────────────
  void _onAudioState(PlayerState st) {
    if (st.processingState != ProcessingState.completed) return;
    final pg = _pages[_curPage];
    final idx = pg.verses.indexWhere((v) => v.surah == _playSurah && v.verse == _playVerse);
    if (idx < 0 || idx >= pg.verses.length - 1) {
      setState(() { _playing = false; _playVerse = 0; });
      return;
    }
    final next = pg.verses[idx + 1];
    _playSurah = next.surah; _playVerse = next.verse;
    _audioPlayer.setUrl(q.getAudioURLByVerse(_playSurah, _playVerse));
    _audioPlayer.play();
    setState(() {});
  }

  void _play() {
    if (_playing) { _audioPlayer.pause(); setState(() => _playing = false); return; }
    final pg = _pages[_curPage];
    _playSurah = pg.surah; _playVerse = pg.verses.first.verse;
    _audioPlayer.setUrl(q.getAudioURLByVerse(_playSurah, _playVerse));
    _audioPlayer.play();
    setState(() => _playing = true);
  }

  void _stop() { _audioPlayer.stop(); setState(() { _playing = false; _playVerse = 0; }); }

  // ─── Taps ──────────────────────────────────────────────────────────────────
  void _onTapVerse(int surah, int verse) {
    setState(() { _tappedSurah = surah; _tappedVerse = verse; });
    if (_playing) {
      _playSurah = surah; _playVerse = verse;
      _audioPlayer.setUrl(q.getAudioURLByVerse(surah, verse));
      _audioPlayer.play();
    }
  }

  // ─── Page flip animation ──────────────────────────────────────────────────
  void _goToPage(int idx) {
    if (idx == _curPage || idx < 0 || idx >= _pages.length) return;
    setState(() { _flipping = true; _flipFromPage = _curPage; _flipAngle = 0; });
    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    final anim = Tween(begin: 0.0, end: math.pi).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
    bool jumped = false;
    anim.addListener(() {
      setState(() => _flipAngle = anim.value);
      if (anim.value > math.pi / 2 && !jumped) {
        jumped = true; _pageCtrl.jumpToPage(idx); _curPage = idx;
      }
    });
    ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) { ctrl.dispose(); setState(() => _flipping = false); }
    });
    ctrl.forward();
  }

  // ─── Navigation helpers ───────────────────────────────────────────────────
  void _goToSurah(int surah) {
    final idx = _pages.indexWhere((p) => p.surah == surah);
    if (idx >= 0) { Navigator.pop(context); _goToPage(idx); }
  }

  void _goToJuz(int juz) {
    for (int s = 1; s <= q.totalSurahCount; s++) {
      for (int v = 1; v <= q.getVerseCount(s); v++) {
        if (q.getJuzNumber(s, v) == juz) {
          final idx = _pages.indexWhere((p) => p.verses.any((vr) => vr.surah == s && vr.verse == v));
          if (idx >= 0) { Navigator.pop(context); _goToPage(idx); return; }
        }
      }
    }
  }

  void _goToBookmark(BookmarkEntry bm) {
    Navigator.pop(context);
    if (bm.pageIdx >= 0 && bm.pageIdx < _pages.length) _goToPage(bm.pageIdx);
  }

  // ─── Font scale ───────────────────────────────────────────────────────────
  void _zoomIn()    => setState(() => _fontScale = (_fontScale + 0.05).clamp(0.7, 1.5));
  void _zoomOut()   => setState(() => _fontScale = (_fontScale - 0.05).clamp(0.7, 1.5));
  void _zoomReset() => setState(() => _fontScale = 1.0);

  // ─── Tajwid ───────────────────────────────────────────────────────────────
  void _toggleTajwid() => setState(() => _showTajwid = !_showTajwid);
  void _showTajwidLegend() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const TajwidLegend(),
    );
  }

  // ─── Utils ────────────────────────────────────────────────────────────────
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.dark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pg = _pages[_curPage];
    return Scaffold(
      backgroundColor: AppColors.outerBg,
      drawer: _Drawer(
        pages: _pages, curSurah: pg.surah, curPageIdx: _curPage,
        bookmarks: _bookmarks,
        onSurah: _goToSurah, onJuz: _goToJuz,
        onPage: (idx) { Navigator.pop(context); _goToPage(idx); },
        onBookmark: _goToBookmark,
        onTranslate: () {
          showDialog(context: context, builder: (_) => TranslationDialog(
            currentIndex: _transLangIdx,
            onSelected: (idx) => setState(() { _transLangIdx = idx; _showTranslation = true; }),
          ));
        },
      ),
      body: Column(children: [
        Expanded(child: _PageFlipWrapper(
          flipping: _flipping, angle: _flipAngle,
          child: GestureDetector(
            onHorizontalDragEnd: (d) {
              if (d.primaryVelocity == null) return;
              if (d.primaryVelocity! < -200 && _curPage < _pages.length - 1) _goToPage(_curPage + 1);
              if (d.primaryVelocity! > 200 && _curPage > 0) _goToPage(_curPage - 1);
            },
            child: PageView.builder(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() { _curPage = i; _tappedSurah = 0; _tappedVerse = 0; }),
              itemBuilder: (_, i) => _MushafPage(
                data: _pages[i],
                playVerse: _playSurah == _pages[i].surah ? _playVerse : 0,
                tappedSurah: _tappedSurah, tappedVerse: _tappedVerse,
                isPlayingPage: _playing && _playSurah == _pages[i].surah,
                fontScale: _fontScale, showTajwid: _showTajwid,
                bookmarkedVerses: _bookmarkedVerses,
                onTapVerse: _onTapVerse, onBookmarkVerse: _toggleBookmark,
              ),
            ),
          ),
        )),
        if (_showTranslation)
          _TranslationPanel(
            surah: pg.surah, verses: pg.verses,
            langIdx: _transLangIdx,
            tappedVerse: _tappedVerse,
            onClose: () => setState(() => _showTranslation = false),
          ),
        SafeArea(top: false, child: BottomBar(
          playing: _playing, reciter: _reciter, surahName: pg.surahName,
          pageNum: pg.pageNum, playVerse: _playVerse,
          onPlay: _play, onStop: _stop,
          fontScale: _fontScale,
          onZoomIn: _zoomIn, onZoomOut: _zoomOut, onZoomReset: _zoomReset,
          showTajwid: _showTajwid, onToggleTajwid: _toggleTajwid,
          onTajwidLongPress: _showTajwidLegend,
        )),
      ]),
    );
  }
}
// ─── MushafPage  (page shell) ────────────────────────────────────────────────
class _MushafPage extends StatelessWidget {
  final PageData data;
  final int playVerse, tappedSurah, tappedVerse;
  final bool isPlayingPage, showTajwid;
  final double fontScale;
  final Set<String> bookmarkedVerses;
  final void Function(int, int) onTapVerse, onBookmarkVerse;

  const _MushafPage({
    required this.data, required this.playVerse,
    required this.tappedSurah, required this.tappedVerse,
    required this.isPlayingPage, required this.fontScale,
    required this.showTajwid, required this.bookmarkedVerses,
    required this.onTapVerse, required this.onBookmarkVerse,
  });

  @override
  Widget build(BuildContext context) {
    final isFatihah = data.pageNum == 1;
    final inner = isFatihah
      ? FatihahPage(
          data: data, playVerse: playVerse,
          tappedSurah: tappedSurah, tappedVerse: tappedVerse,
          isPlayingPage: isPlayingPage, fontScale: fontScale,
          showTajwid: showTajwid, bookmarkedVerses: bookmarkedVerses,
          onTapVerse: onTapVerse, onBookmarkVerse: onBookmarkVerse)
      : NormalPage(
          data: data, playVerse: playVerse,
          tappedSurah: tappedSurah, tappedVerse: tappedVerse,
          isPlayingPage: isPlayingPage, fontScale: fontScale,
          showTajwid: showTajwid, bookmarkedVerses: bookmarkedVerses,
          onTapVerse: onTapVerse, onBookmarkVerse: onBookmarkVerse);

    return Container(
      margin: const EdgeInsets.all(6),
      child: CustomPaint(
        painter: FramePainter(
          gold: AppColors.gold, goldLt: AppColors.goldLt,
          dark: AppColors.dark, bg: AppColors.frameBg),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.5),
            ),
            child: inner,
          ),
        ),
      ),
    );
  }
}

// ─── PageFlipWrapper ─────────────────────────────────────────────────────────
class _PageFlipWrapper extends StatelessWidget {
  final bool flipping; final double angle; final Widget child;
  const _PageFlipWrapper({required this.flipping, required this.angle, required this.child});
  @override
  Widget build(BuildContext context) {
    if (!flipping) return child;
    return Transform(
      alignment: Alignment.centerRight,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(angle),
      child: child,
    );
  }
}

// ─── TranslationPanel ────────────────────────────────────────────────────────
class _TranslationPanel extends StatelessWidget {
  final int surah, langIdx, tappedVerse;
  final List<VerseRef> verses;
  final VoidCallback onClose;
  const _TranslationPanel({
    required this.surah, required this.verses, required this.langIdx,
    required this.tappedVerse, required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final types = QuranLibrary().translationTypes;
    final lang = types.isNotEmpty && langIdx < types.length ? types[langIdx] : null;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        border: Border(top: BorderSide(color: AppColors.gold.withOpacity(0.4))),
      ),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
          child: Row(children: [
            Text('Terjemah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark)),
            if (lang != null) ...[const SizedBox(width: 6),
              Text('(${lang.name})', style: TextStyle(fontSize: 10, color: AppColors.dark.withOpacity(0.5)))],
            const Spacer(),
            IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: onClose),
          ])),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          itemCount: verses.length,
          itemBuilder: (_, i) {
            final v = verses[i];
            final isActive = v.verse == tappedVerse;
            String transText;
            try { transText = lang != null
                ? QuranLibrary().getTranslation(lang, v.surah, v.verse)
                : q.getVerse(v.surah, v.verse); }
            catch (_) { transText = q.getVerse(v.surah, v.verse); }
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? AppColors.hl.withOpacity(0.07) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: RichText(text: TextSpan(children: [
                TextSpan(text: '${v.verse}. ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.hl : AppColors.gold)),
                TextSpan(text: transText,
                  style: TextStyle(fontSize: 12, color: AppColors.dark.withOpacity(0.8), height: 1.5)),
              ])),
            );
          },
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawer
// ─────────────────────────────────────────────────────────────────────────────
class _Drawer extends StatefulWidget {
  final List<PageData> pages; final int curSurah, curPageIdx;
  final List<BookmarkEntry> bookmarks;
  final Function(int) onSurah, onJuz, onPage;
  final Function(BookmarkEntry) onBookmark;
  final VoidCallback onTranslate;
  const _Drawer({
    required this.pages, required this.curSurah, required this.curPageIdx,
    required this.bookmarks,
    required this.onSurah, required this.onJuz, required this.onPage,
    required this.onBookmark, required this.onTranslate,
  });
  @override State<_Drawer> createState() => _DrawerState();
}

class _DrawerState extends State<_Drawer> {
  int _panel = 0;
  final _ctrl = TextEditingController();
  String _q = '';

  static Map<int,int> _buildJuzFirstSurah() {
    final map = <int,int>{};
    for (int s = 1; s <= q.totalSurahCount; s++) {
      final cnt = q.getVerseCount(s);
      for (int v = 1; v <= cnt; v++) {
        final juz = q.getJuzNumber(s, v);
        if (!map.containsKey(juz)) map[juz] = s;
      }
    }
    return map;
  }
  static final Map<int,int> _juzFirstSurah = _buildJuzFirstSurah();

  String _type(int s) {
    const m = [1,6,7,10,11,12,13,14,15,16,17,18,19,20,21,23,25,26,27,28,
      29,30,31,32,34,35,36,37,38,39,40,41,42,43,44,45,46,50,51,52,53,54,
      56,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,
      88,89,90,91,92,93,94,95,96,97,100,101,102,103,104,105,106,107,108,
      109,111,112,113,114];
    return m.contains(s) ? 'Makkiyyah' : 'Madaniyyah';
  }

  List<int> get _surahs => List.generate(q.totalSurahCount,(i)=>i+1)
    .where((i) => _q.isEmpty
      || q.getSurahName(i).toLowerCase().contains(_q.toLowerCase())
      || q.getSurahNameArabic(i).contains(_q)).toList();

  List<int> get _juzs => List.generate(30,(i)=>i+1)
    .where((j) {
      if (_q.isEmpty) return true;
      final surah = _juzFirstSurah[j] ?? 1;
      return '$j'.contains(_q) ||
        q.getSurahName(surah).toLowerCase().contains(_q.toLowerCase()) ||
        q.getSurahNameArabic(surah).contains(_q);
    }).toList();

  void _setPanel(int p) => setState(() { _panel=(_panel==p)?0:p; _q=''; _ctrl.clear(); });
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Drawer(
    backgroundColor: AppColors.drawerBg,
    width: MediaQuery.of(context).size.width * 0.85,
    child: Column(children: [
      SafeArea(bottom: false, child: _hdr()),
      Container(height:2, decoration:BoxDecoration(gradient:LinearGradient(
        colors:[AppColors.gold.withOpacity(0.1),AppColors.gold,AppColors.dark,AppColors.gold,AppColors.gold.withOpacity(0.1)]))),
      Padding(padding:const EdgeInsets.fromLTRB(12,10,12,8),
        child:Row(children:[
          NBtn(label:'Surah', icon:Icons.format_list_bulleted_rounded, active:_panel==1, onTap:()=>_setPanel(1)),
          const SizedBox(width:8),
          NBtn(label:'Juz',   icon:Icons.grid_view_rounded,            active:_panel==2, onTap:()=>_setPanel(2)),
          const SizedBox(width:8),
          NBtn(label:'Hal',   icon:Icons.auto_stories_rounded,         active:_panel==3, onTap:()=>_setPanel(3)),
        ])),
      Expanded(child: _body()),
      const SafeArea(top:false, child:SizedBox(height:8)),
    ]),
  );

  Widget _hdr() => CustomPaint(
    painter: _DHP(),
    child: SizedBox(width:double.infinity, height:110,
      child: Padding(padding:const EdgeInsets.fromLTRB(18,0,18,14),
        child: Column(mainAxisAlignment:MainAxisAlignment.end,
          crossAxisAlignment:CrossAxisAlignment.start, children:[
          Text('القرآن الكريم', style:AppTextStyle.quranSurahNameStyle(fontSize:24,color:Colors.white)),
          Text('Al-Quran Al-Karim', style:TextStyle(fontSize:11,color:Colors.white.withOpacity(0.65))),
        ]))));

  Widget _body() {
    if (_panel == 0) return _menu();
    String hintText = _panel == 1 ? 'Cari Surah...'
        : _panel == 2 ? 'Cari Juz...' : 'Cari halaman 1 - 604';
    return Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(12,0,12,6),
        child:Container(
          decoration:BoxDecoration(color:const Color(0xFFF7F2E8),
            borderRadius:BorderRadius.circular(10),
            border:Border.all(color:AppColors.gold.withOpacity(0.4))),
          child:TextField(
            controller:_ctrl,
            onChanged:(v)=>setState(()=>_q=v),
            keyboardType: _panel == 3 ? TextInputType.number : TextInputType.text,
            style:TextStyle(fontSize:13,color:AppColors.dark),
            decoration:InputDecoration(
              hintText: hintText,
              hintStyle:TextStyle(color:AppColors.dark.withOpacity(0.35),fontSize:13),
              prefixIcon:Icon(Icons.search_rounded,color:AppColors.gold,size:19),
              suffixIcon:_q.isNotEmpty?IconButton(
                icon:Icon(Icons.close_rounded,size:16,color:AppColors.dark.withOpacity(0.5)),
                onPressed:(){_ctrl.clear();setState(()=>_q='');}):null,
              border:InputBorder.none,
              contentPadding:const EdgeInsets.symmetric(vertical:11))))),
      Expanded(child: _list()),
    ]);
  }

  Widget _list() {
    if (_panel==1) return _SurahList(surahs:_surahs, cur:widget.curSurah, type:_type, onTap:widget.onSurah);
    if (_panel==2) return _JuzList(juzs:_juzs, juzFirstSurah:_juzFirstSurah, onTap:widget.onJuz);
    if (_panel==3) {
      final filtered = _q.isEmpty ? widget.pages
          : widget.pages.where((p) => '${p.pageNum}'.contains(_q)).toList();
      return _PageList(pages:filtered, curIdx:widget.curPageIdx, onTap:widget.onPage);
    }
    return const SizedBox.shrink();
  }

  Widget _menu() => ListView(padding:const EdgeInsets.only(top:4), children:[
    if (widget.bookmarks.isNotEmpty) ...[
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text('Penanda', style: TextStyle(
            fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w700, letterSpacing: 0.8))),
      ...widget.bookmarks.take(5).map((bm) => InkWell(
        onTap: () => widget.onBookmark(bm),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Icon(Icons.bookmark_rounded, size: 18, color: AppColors.gold),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${bm.surahName} : ${bm.verse}',
                  style: TextStyle(fontSize: 13, color: AppColors.dark)),
              Text(bm.surahNameAr,
                  style: AppTextStyle.quranSurahNameStyle(fontSize: 14, color: AppColors.dark.withOpacity(0.6))),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.dark.withOpacity(0.3)),
          ]))),
      ),
      Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.gold.withOpacity(0.3)),
      const SizedBox(height: 4),
    ],
    _MT(icon:Icons.bookmark_rounded,   label:'Semua Penanda',      onTap:()=>Navigator.pop(context)),
    _MT(icon:Icons.translate_rounded,  label:'Terjemah & Tafsir',  onTap:() {
      final nav = Navigator.of(context);
      final onTranslate = widget.onTranslate;
      nav.pop();
      Future.delayed(const Duration(milliseconds: 300), () { onTranslate(); });
    }),
    _MT(icon:Icons.headphones_rounded, label:'Murattal & Hafalan', onTap:() {
      final nav = Navigator.of(context);
      nav.pop();
      Future.delayed(const Duration(milliseconds: 300), () {
        nav.push(MaterialPageRoute(builder: (_) => const HafalanScreen()));
      });
    }),
    _MT(icon:Icons.download_rounded,   label:'Unduh Konten',       onTap:()=>Navigator.pop(context)),
    _MT(icon:Icons.settings_outlined,  label:'Pengaturan',         onTap:()=>Navigator.pop(context)),
    const SizedBox(height:24),
    Center(child:Text('Al-Quran Digital',
        style:TextStyle(fontSize:11,color:AppColors.dark.withOpacity(0.35)))),
  ]);
}

// ─── Drawer sub-widgets ──────────────────────────────────────────────────────
class _SurahList extends StatelessWidget {
  final List<int> surahs; final int cur;
  final String Function(int) type; final Function(int) onTap;
  const _SurahList({required this.surahs,required this.cur,required this.type,required this.onTap});
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding:EdgeInsets.zero, itemCount:surahs.length,
    separatorBuilder:(_,__)=>Divider(height:1,indent:12,endIndent:12,color:AppColors.gold.withOpacity(0.2)),
    itemBuilder:(_,i) {
      final s=surahs[i]; final active=s==cur;
      return InkWell(onTap:()=>onTap(s),
        child:Container(
          color:active?AppColors.gold.withOpacity(0.12):Colors.transparent,
          padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),
          child:Row(children:[
            DB(n:s,active:active), const SizedBox(width:10),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(q.getSurahName(s),style:TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:AppColors.dark)),
              Text('${q.getVerseCount(s)} Ayat · ${type(s)}',
                  style:TextStyle(fontSize:10,color:AppColors.dark.withOpacity(0.5))),
            ])),
            Text(q.getSurahNameArabic(s),
              style:AppTextStyle.quranSurahNameStyle(fontSize:18,color:active?AppColors.gold:AppColors.dark.withOpacity(0.75))),
          ])));
    });
}

class _JuzList extends StatelessWidget {
  final List<int> juzs; final Map<int,int> juzFirstSurah; final Function(int) onTap;
  const _JuzList({required this.juzs, required this.juzFirstSurah, required this.onTap});
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding:EdgeInsets.zero, itemCount:juzs.length,
    separatorBuilder:(_,__)=>Divider(height:1,indent:12,endIndent:12,color:AppColors.gold.withOpacity(0.2)),
    itemBuilder:(_,i) {
      final juz = juzs[i]; final s = juzFirstSurah[juz] ?? 1;
      return InkWell(onTap: () => onTap(juz),
        child:Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:10),
          child:Row(children:[
            DB(n:juz,active:false), const SizedBox(width:10),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Juz $juz',style:TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:AppColors.dark)),
              Text('Dari ${q.getSurahName(s)}',style:TextStyle(fontSize:10,color:AppColors.dark.withOpacity(0.5))),
            ])),
            Text(q.getSurahNameArabic(s),
              style:AppTextStyle.quranSurahNameStyle(fontSize:16,color:AppColors.dark.withOpacity(0.65))),
          ])));
    });
}

class _PageList extends StatelessWidget {
  final List<PageData> pages; final int curIdx; final Function(int) onTap;
  const _PageList({required this.pages,required this.curIdx,required this.onTap});
  String _prev(PageData p) {
    final t=q.getVerse(p.verses.first.surah,p.verses.first.verse,verseEndSymbol:false);
    return t.length>45?'${t.substring(0,45)}...':t;
  }
  bool _newSurah(int i) => i==0 || pages[i].surah != pages[i-1].surah;
  bool _isLast(int i) => i==pages.length-1 || pages[i+1].surah != pages[i].surah;
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding:const EdgeInsets.only(bottom:8), itemCount:pages.length,
    itemBuilder:(_,i) {
      final pg=pages[i]; final isCur=i==curIdx;
      return Column(crossAxisAlignment:CrossAxisAlignment.stretch, children:[
        if (_newSurah(i))
          Container(
            margin:const EdgeInsets.fromLTRB(12,8,12,0),
            padding:const EdgeInsets.symmetric(horizontal:12,vertical:5),
            decoration:BoxDecoration(color:AppColors.dark.withOpacity(0.85),
              borderRadius:const BorderRadius.vertical(top:Radius.circular(8))),
            child:Row(children:[
              Text(pg.surahName,style:const TextStyle(fontSize:12,fontWeight:FontWeight.bold,color:Colors.white)),
              const Spacer(),
              Text(pg.surahNameAr,style:AppTextStyle.quranSurahNameStyle(fontSize:14,color:Colors.white70)),
            ])),
        InkWell(onTap:()=>onTap(pg.pageNum - 1),
          child:Container(
            margin:EdgeInsets.fromLTRB(12,0,12,_isLast(i)?0:1),
            padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
            decoration:BoxDecoration(
              color:isCur?AppColors.gold.withOpacity(0.15):const Color(0xFFF7F2E8).withOpacity(0.5),
              border:isCur?Border.all(color:AppColors.gold,width:1):null,
              borderRadius:_isLast(i)?const BorderRadius.vertical(bottom:Radius.circular(8)):BorderRadius.zero),
            child:Row(children:[
              Container(width:26,height:26,
                decoration:BoxDecoration(shape:BoxShape.circle,
                  color:isCur?AppColors.gold:AppColors.gold.withOpacity(0.15),
                  border:Border.all(color:AppColors.gold.withOpacity(0.5),width:1)),
                child:Center(child:Text('${pg.pageNum}',
                  style:TextStyle(fontSize:9,fontWeight:FontWeight.bold,color:isCur?Colors.white:AppColors.dark)))),
              const SizedBox(width:8),
              Expanded(child:Text(_prev(pg),
                style:AppTextStyle.quranPageInfoStyle(fontSize:12,color:AppColors.dark),
                textDirection:TextDirection.rtl,maxLines:1,overflow:TextOverflow.ellipsis)),
              const SizedBox(width:4),
              Text('${pg.verses.first.verse}–${pg.verses.last.verse}',
                style:TextStyle(fontSize:9,color:AppColors.dark.withOpacity(0.4))),
            ]))),
      ]);
    });
}

class _MT extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _MT({required this.icon,required this.label,required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap:onTap,
    child:Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:13),
      child:Row(children:[
        Icon(icon,size:20,color:AppColors.gold), const SizedBox(width:14),
        Text(label,style:TextStyle(fontSize:14,color:AppColors.dark)),
      ])));
}

class _DHP extends CustomPainter {
  const _DHP();
  @override
  void paint(Canvas canvas, Size size) {
    final w=size.width; final h=size.height;
    canvas.drawRect(Rect.fromLTWH(0,0,w,h),Paint()
      ..shader=LinearGradient(colors:[AppColors.dark,AppColors.dark.withOpacity(0.82)],
        begin:Alignment.topLeft,end:Alignment.bottomRight)
        .createShader(Rect.fromLTWH(0,0,w,h)));
    final p=Paint()..color=AppColors.gold.withOpacity(0.08)..style=PaintingStyle.fill;
    const step=22.0;
    for (double x=0; x<w; x+=step)
      for (double y=0; y<h; y+=step) {
        final path=Path()..moveTo(x+step/2,y)..lineTo(x+step,y+step/2)
          ..lineTo(x+step/2,y+step)..lineTo(x,y+step/2)..close();
        canvas.drawPath(path,p);
      }
    canvas.drawLine(Offset(0,h-1),Offset(w,h-1),Paint()..color=AppColors.gold..strokeWidth=1.5);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}
