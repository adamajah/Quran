import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/quran_fonts.dart';

import '../../constants/app_colors.dart';
import '../../models/verse_ref.dart';
import '../../utils/quran_utils.dart';
import '../../utils/tajwid_utils.dart';
import './page_elements.dart';

class NormalPage extends StatelessWidget {
  final PageData data;
  final int playSurah, playVerse, tappedSurah, tappedVerse;
  final bool isPlayingPage, showTajwid;
  final double fontScale;
  final Set<String> bookmarkedVerses;
  final void Function(int, int) onTapVerse, onBookmarkVerse;

  const NormalPage({
    super.key,
    required this.data,
    required this.playSurah,
    required this.playVerse,
    required this.tappedSurah,
    required this.tappedVerse,
    required this.isPlayingPage,
    required this.fontScale,
    required this.showTajwid,
    required this.bookmarkedVerses,
    required this.onTapVerse,
    required this.onBookmarkVerse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        PageHeader(data: data),

        const MushafRule(thick: true),

        Expanded(
          child: NormalBody(
            data: data,
            playSurah: playSurah,
            playVerse: playVerse,
            tappedSurah: tappedSurah,

            tappedVerse: tappedVerse,

            isPlayingPage: isPlayingPage,

            fontScale: fontScale,

            showTajwid: showTajwid,

            bookmarkedVerses: bookmarkedVerses,

            onTapVerse: onTapVerse,

            onBookmarkVerse: onBookmarkVerse,
          ),
        ),

        const MushafRule(thick: true),

        PageNum(n: data.pageNum),
      ],
    );
  }
}

class NormalBody extends StatelessWidget {
  final PageData data;
  final int playSurah, playVerse, tappedSurah, tappedVerse;
  final bool isPlayingPage, showTajwid;
  final double fontScale;
  final Set<String> bookmarkedVerses;
  final void Function(int, int) onTapVerse, onBookmarkVerse;

  const NormalBody({
    super.key,
    required this.data,
    required this.playSurah,
    required this.playVerse,
    required this.tappedSurah,
    required this.tappedVerse,
    required this.isPlayingPage,
    required this.fontScale,
    required this.showTajwid,
    required this.bookmarkedVerses,
    required this.onTapVerse,
    required this.onBookmarkVerse,
  });

  static final Map<String, double> _fsCache = {};

  static String _ar(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  static double _measureH(
    List<VerseRef> vv,
    double fs,
    double lh,
    double maxW,
    Color inkColor,
  ) {
    final s = AppQuranFonts.hafsStyle.copyWith(
      fontSize: fs,
      height: lh,
      color: inkColor,
    );
    final spans =
        vv.map((v) {
          final t = QuranUtils.getCleanVerse(
            v.surah,
            v.verse,
            verseEndSymbol: false,
          );
          return TextSpan(text: '$t ${_ar(v.verse)} ', style: s);
        }).toList();
    final tp = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    )..layout(maxWidth: maxW);
    return tp.height;
  }

  static double _bestFs(
    int pageNum,
    List<VerseRef> vv,
    double maxW,
    double maxH,
    Color inkColor,
  ) {
    if (maxH <= 20) return 7.0;

    final cacheKey =
        '$pageNum|${maxW.toStringAsFixed(1)}|${maxH.toStringAsFixed(1)}|${inkColor.toARGB32()}';
    final cached = _fsCache[cacheKey];
    if (cached != null) return cached;

    double lo = 6.0;
    double hi = 22.0;
    double best = lo;
    for (int i = 0; i < 8; i++) {
      final mid = (lo + hi) / 2.0;
      if (_measureH(vv, mid, 1.85, maxW, inkColor) <= maxH) {
        best = mid;
        lo = mid;
      } else {
        hi = mid;
      }
    }

    final result = best.clamp(6.0, 22.0);
    _fsCache[cacheKey] = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, bc) {
        double reservedH = 0.0;

        for (final g in data.groups) {
          if (g.isFirstInMushaf) {
            reservedH += 54.0;

            if (g.surah != 9) {
              reservedH += 42.0;
            }
          }
        }

        final availH = bc.maxHeight - reservedH;

        final availW = bc.maxWidth - 28.0;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final inkColor = isDark ? Colors.white : AppColors.ink;

        final fs = _bestFs(data.pageNum, data.verses, availW, availH, inkColor);

        final List<Widget> children = [];

        for (final g in data.groups) {
          if (g.isFirstInMushaf) {
            children.add(
              SurahBanner(surahIndex: g.surah, surahNameAr: g.surahNameAr),
            );
          }

          if (g.isFirstInMushaf && g.surah != 9) {
            children.add(const Basmalah());
          }

          children.add(
            TappableVerseBlock(
              group: g,

              fs: fs,

              fontScale: fontScale,

              showTajwid: showTajwid,
              playSurah: playSurah,
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
      },
    );
  }
}

class TappableVerseBlock extends StatefulWidget {
  final SurahGroup group;
  final double fs, fontScale;
  final bool showTajwid, isPlayingPage;
  final int playSurah, playVerse, tappedSurah, tappedVerse;
  final Set<String> bookmarkedVerses;
  final void Function(int, int) onTapVerse, onBookmarkVerse;

  const TappableVerseBlock({
    super.key,
    required this.group,
    required this.fs,
    required this.fontScale,
    required this.showTajwid,
    required this.isPlayingPage,
    required this.playSurah,
    required this.playVerse,
    required this.tappedSurah,
    required this.tappedVerse,
    required this.bookmarkedVerses,
    required this.onTapVerse,
    required this.onBookmarkVerse,
  });

  @override
  State<TappableVerseBlock> createState() => _TappableVerseBlockState();
}

class _TappableVerseBlockState extends State<TappableVerseBlock> {
  int _hoveredVerse = 0;

  static String _ar(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  List<InlineSpan> _buildSpans(Color inkColor, bool isDark) {
    final out = <InlineSpan>[];
    final numFs = (widget.fs * 0.72).clamp(10.0, 16.0);

    for (final v in widget.group.verses) {
      final active =
          (widget.isPlayingPage &&
              v.surah == widget.playSurah &&
              v.verse == widget.playVerse) ||
          (widget.tappedSurah == v.surah && widget.tappedVerse == v.verse) ||
          _hoveredVerse == v.verse;

      // Always use verseEndSymbol: false — verse number is rendered separately below
      final text = QuranUtils.getCleanVerse(
        v.surah,
        v.verse,
        verseEndSymbol: false,
      );

      out.addAll(
        _buildTajwidSpans(
          text,
          widget.fs * widget.fontScale,
          1.85,
          active,
          widget.showTajwid,
          inkColor,
        ),
      );
      out.add(
        TextSpan(
          text: ' ',
          style: AppQuranFonts.hafsStyle.copyWith(
            fontSize: widget.fs * widget.fontScale,
            height: 1.85,
            color: inkColor,
          ),
        ),
      );

      // ONE verse number badge — the only source of the verse symbol
      out.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
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
                color:
                    active
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppColors.hl.withValues(alpha: 0.10))
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _ar(v.verse),
                style: AppQuranFonts.hafsStyle.copyWith(
                  fontSize: numFs * widget.fontScale,
                  color:
                      active
                          ? (isDark ? Colors.white : AppColors.hl)
                          : AppColors.gold,
                  fontWeight: FontWeight.bold,
                  height: 1.85,
                ),
              ),
            ),
          ),
        ),
      );
      out.add(
        TextSpan(
          text: ' ',
          style: AppQuranFonts.hafsStyle.copyWith(
            fontSize: widget.fs * widget.fontScale,
            height: 1.85,
            color: inkColor,
          ),
        ),
      );
    }
    return out;
  }

  void _showTajwidHint(String name, String desc, Color color) {
    if (name.isEmpty) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              '$name: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.dark.withValues(alpha: 0.9),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<InlineSpan> _buildTajwidSpans(
    String text,
    double fontSize,
    double height,
    bool active,
    bool showTajwid,
    Color inkColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!showTajwid) {
      return [
        TextSpan(
          text: text,
          style: AppQuranFonts.hafsStyle.copyWith(
            fontSize: fontSize,
            height: height,
            color: active ? (isDark ? Colors.white : AppColors.hl) : inkColor,
            backgroundColor:
                active
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.hl.withValues(alpha: 0.06))
                    : null,
          ),
        ),
      ];
    }

    final spans = <InlineSpan>[];
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final info = TajwidUtils.getTajwidInfo(text, i);
      final isDefaultColor = info.$1 == AppColors.tajwidColors['default'];
      final color =
          active
              ? (isDefaultColor
                  ? (isDark ? Colors.white : AppColors.hl)
                  : info.$1)
              : (isDefaultColor ? inkColor : info.$1);

      spans.add(
        TextSpan(
          text: char,
          recognizer:
              TapGestureRecognizer()
                ..onTap = () => _showTajwidHint(info.$2, info.$3, info.$1),
          style: AppQuranFonts.hafsStyle.copyWith(
            fontSize: fontSize,
            height: height,
            color: color,
            backgroundColor:
                active
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.hl.withValues(alpha: 0.06))
                    : null,
          ),
        ),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkColor = isDark ? Colors.white : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),

      child: Text.rich(
        TextSpan(children: _buildSpans(inkColor, isDark)),

        textAlign: TextAlign.justify,

        textDirection: TextDirection.rtl,

        overflow: TextOverflow.visible,

        softWrap: true,
      ),
    );
  }
}
