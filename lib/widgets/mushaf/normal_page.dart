// ─────────────────────────────────────────────────────────────────────────────
// NormalPage  (extracted from home_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as q;
import 'package:quran_library/quran_library.dart';
import '../../constants/app_colors.dart';
import '../../models/verse_ref.dart';
import '../../utils/tajwid_utils.dart';
import 'page_elements.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NormalPage
// ─────────────────────────────────────────────────────────────────────────────
class NormalPage extends StatelessWidget {
  final PageData data;
  final int playVerse, tappedSurah, tappedVerse;
  final bool isPlayingPage, showTajwid;
  final double fontScale;
  final Set<String> bookmarkedVerses;
  final void Function(int, int) onTapVerse, onBookmarkVerse;

  const NormalPage({
    super.key,
    required this.data, required this.playVerse,
    required this.tappedSurah, required this.tappedVerse,
    required this.isPlayingPage, required this.fontScale,
    required this.showTajwid, required this.bookmarkedVerses,
    required this.onTapVerse, required this.onBookmarkVerse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHeader(data: data),
      const Rule(thick: true),
      Expanded(
        child: NormalBody(
          data: data, playVerse: playVerse,
          tappedSurah: tappedSurah, tappedVerse: tappedVerse,
          isPlayingPage: isPlayingPage, fontScale: fontScale,
          showTajwid: showTajwid, bookmarkedVerses: bookmarkedVerses,
          onTapVerse: onTapVerse, onBookmarkVerse: onBookmarkVerse,
        ),
      ),
      const Rule(thick: true),
      PageNum(n: data.pageNum),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NormalBody
// ─────────────────────────────────────────────────────────────────────────────
class NormalBody extends StatelessWidget {
  final PageData data;
  final int playVerse, tappedSurah, tappedVerse;
  final bool isPlayingPage, showTajwid;
  final double fontScale;
  final Set<String> bookmarkedVerses;
  final void Function(int, int) onTapVerse, onBookmarkVerse;

  const NormalBody({
    super.key,
    required this.data, required this.playVerse,
    required this.tappedSurah, required this.tappedVerse,
    required this.isPlayingPage, required this.fontScale,
    required this.showTajwid, required this.bookmarkedVerses,
    required this.onTapVerse, required this.onBookmarkVerse,
  });

  static String _ar(int n) {
    const d = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  static double _measureH(List<VerseRef> vv, double fs, double lh, double maxW) {
    final s = QuranLibrary().hafsStyle.copyWith(fontSize: fs, height: lh, color: AppColors.ink);
    final spans = vv.map((v) {
      final t = q.getVerse(v.surah, v.verse, verseEndSymbol: false);
      return TextSpan(text: '$t ${_ar(v.verse)} ', style: s);
    }).toList();
    final tp = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    )..layout(maxWidth: maxW);
    return tp.height;
  }

  static double _bestFs(List<VerseRef> vv, double maxW, double maxH) {
    if (maxH <= 20) return 7.0;
    for (double fs = 22.0; fs >= 6.0; fs -= 0.2) {
      if (_measureH(vv, fs, 1.85, maxW) <= maxH) return fs;
    }
    return 6.0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, bc) {
      double reservedH = 0.0;
      for (final g in data.groups) {
        if (g.isFirstInMushaf) {
          reservedH += 54.0;
          if (g.surah != 9) reservedH += 42.0;
        }
      }
      final availH = bc.maxHeight - reservedH;
      final availW = bc.maxWidth - 28.0;
      final fs = _bestFs(data.verses, availW, availH);

      final List<Widget> children = [];
      for (final g in data.groups) {
        if (g.isFirstInMushaf)
          children.add(SurahBanner(surahIndex: g.surah, surahNameAr: g.surahNameAr));
        if (g.isFirstInMushaf && g.surah != 9) children.add(const Basmalah());
        children.add(
          TappableVerseBlock(
            group: g,
            fs: fs,
            fontScale: fontScale,
            showTajwid: showTajwid,
            playVerse: playVerse,
            tappedSurah: tappedSurah,
            tappedVerse: tappedVerse,
            isPlayingPage: isPlayingPage,
            bookmarkedVerses: bookmarkedVerses,
            onTapVerse: onTapVerse,
            onBookmarkVerse: onBookmarkVerse,
          ),
        );
      }

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TappableVerseBlock
// ─────────────────────────────────────────────────────────────────────────────
class TappableVerseBlock extends StatefulWidget {
  final SurahGroup group;
  final double fs, fontScale;
  final bool showTajwid, isPlayingPage;
  final int playVerse, tappedSurah, tappedVerse;
  final Set<String> bookmarkedVerses;
  final void Function(int, int) onTapVerse, onBookmarkVerse;

  const TappableVerseBlock({
    super.key,
    required this.group, required this.fs, required this.fontScale,
    required this.showTajwid, required this.isPlayingPage,
    required this.playVerse, required this.tappedSurah, required this.tappedVerse,
    required this.bookmarkedVerses,
    required this.onTapVerse, required this.onBookmarkVerse,
  });

  @override
  State<TappableVerseBlock> createState() => _TappableVerseBlockState();
}

class _TappableVerseBlockState extends State<TappableVerseBlock> {
  int _hoveredVerse = 0;

  static String _ar(int n) {
    const d = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  List<InlineSpan> _buildSpans() {
    final out = <InlineSpan>[];
    final numFs = (widget.fs * 0.72).clamp(10.0, 16.0);
    for (final v in widget.group.verses) {
      final active = (widget.isPlayingPage && v.verse == widget.playVerse) ||
          (widget.tappedSurah == v.surah && widget.tappedVerse == v.verse) ||
          _hoveredVerse == v.verse;
      final text = q.getVerse(v.surah, v.verse, verseEndSymbol: false);
      out.addAll(buildTajwidSpans(
          text, widget.fs * widget.fontScale, 1.85, active, widget.showTajwid));
      out.add(TextSpan(
          text: ' ',
          style: QuranLibrary().hafsStyle.copyWith(
              fontSize: widget.fs * widget.fontScale, height: 1.85)));
      out.add(WidgetSpan(
        child: GestureDetector(
          onTap: () => widget.onTapVerse(v.surah, v.verse),
          onLongPress: () => widget.onBookmarkVerse(v.surah, v.verse),
          onTapDown: (_) => setState(() => _hoveredVerse = v.verse),
          onTapUp: (_) => setState(() => _hoveredVerse = 0),
          onTapCancel: () => setState(() => _hoveredVerse = 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: active ? AppColors.hl.withOpacity(0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _ar(v.verse),
              style: QuranLibrary().hafsStyle.copyWith(
                fontSize: numFs * widget.fontScale,
                color: active ? AppColors.hl : AppColors.gold,
                fontWeight: FontWeight.bold,
                height: 1.85,
              ),
            ),
          ),
        ),
        alignment: PlaceholderAlignment.middle,
      ));
      out.add(TextSpan(
          text: ' ',
          style: QuranLibrary().hafsStyle.copyWith(
              fontSize: widget.fs * widget.fontScale, height: 1.85)));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text.rich(
        TextSpan(children: _buildSpans()),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        overflow: TextOverflow.visible,
        softWrap: true,
      ),
    );
  }
}
