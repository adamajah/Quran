import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/quran_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_style.dart';
import '../../models/verse_ref.dart';
import '../../utils/quran_utils.dart';
import '../../utils/tajwid_utils.dart';
import './page_elements.dart';

class FatihahPage extends StatefulWidget {
  final PageData data;
  final int playSurah, playVerse, tappedSurah, tappedVerse;
  final bool isPlayingPage, showTajwid;
  final double fontScale;
  final Set<String> bookmarkedVerses;
  final void Function(int, int) onTapVerse, onBookmarkVerse;

  const FatihahPage({
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
  State<FatihahPage> createState() => _FatihahPageState();
}

class _FatihahPageState extends State<FatihahPage> {
  static String _ar(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(data: widget.data),
        const MushafRule(thick: true),
        const FatihahSurahBanner(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children:
                  widget.data.verses.map((v) => _buildVerseRow(v)).toList(),
            ),
          ),
        ),
        const MushafRule(thick: true),
        PageNum(n: widget.data.pageNum),
      ],
    );
  }

  Widget _buildVerseRow(VerseRef v) {
    final active =
        (widget.isPlayingPage &&
            v.surah == widget.playSurah &&
            v.verse == widget.playVerse) ||
        (widget.tappedSurah == v.surah && widget.tappedVerse == v.verse);
    final key = '${v.surah}:${v.verse}';
    final isBookmarked = widget.bookmarkedVerses.contains(key);
    final text = QuranUtils.getCleanVerse(
      v.surah,
      v.verse,
      verseEndSymbol: false,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkColor = isDark ? Colors.white : AppColors.ink;

    return GestureDetector(
      onTap: () => widget.onTapVerse(v.surah, v.verse),
      onLongPress: () => widget.onBookmarkVerse(v.surah, v.verse),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color:
              active
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.hl.withValues(alpha: 0.06))
                  : isBookmarked
                  ? AppColors.gold.withValues(alpha: 0.08)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border:
              isBookmarked
                  ? Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    width: 0.8,
                  )
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isBookmarked)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.bookmark_rounded,
                  size: 10,
                  color: AppColors.gold,
                ),
              ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    ..._buildTajwidSpans(
                      text,
                      23 * widget.fontScale,
                      2.2,
                      active,
                      widget.showTajwid,
                      inkColor,
                    ),
                    TextSpan(
                      text: ' ${_ar(v.verse)}',
                      style: AppQuranFonts.hafsStyle.copyWith(
                        fontSize: 15 * widget.fontScale,
                        color:
                            active
                                ? (isDark ? Colors.white : AppColors.hl)
                                : AppColors.gold,
                        fontWeight: FontWeight.bold,
                        height: 2.2,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
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
                        ? Colors.white.withValues(alpha: 0.12)
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
              ? (isDark ? Colors.white : AppColors.hl)
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
                        ? Colors.white.withValues(alpha: 0.12)
                        : AppColors.hl.withValues(alpha: 0.06))
                    : null,
          ),
        ),
      );
    }
    return spans;
  }
}

class FatihahSurahBanner extends StatelessWidget {
  const FatihahSurahBanner({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(6, 4, 6, 2),
      child: Row(
        children: [
          const Expanded(child: OrnamentSide(mirror: false)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : const Color(0xFFF0E8D8),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: Text(
              'سُورَةُ ٱلْفَاتِحَةِ',
              style: AppTextStyle.quranSurahNameStyle(
                fontSize: 18,
                color: textColor,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const Expanded(child: OrnamentSide(mirror: true)),
        ],
      ),
    );
  }
}

class OrnamentSide extends StatelessWidget {
  final bool mirror;
  const OrnamentSide({super.key, required this.mirror});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkColor = isDark ? Colors.white : AppColors.dark;
    return Transform.scale(
      scaleX: mirror ? -1 : 1,
      child: CustomPaint(
        painter: OrnamentPainter(gold: AppColors.gold, dark: darkColor),
        child: const SizedBox(height: 36),
      ),
    );
  }
}

class OrnamentPainter extends CustomPainter {
  final Color gold, dark;
  const OrnamentPainter({required this.gold, required this.dark});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fillPaint =
        Paint()
          ..color = gold.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;
    final strokePaint =
        Paint()
          ..color = gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
    const sz = 8.0;
    const step = 14.0;
    for (double x = sz; x < w - sz / 2; x += step) {
      final p =
          Path()
            ..moveTo(x, h / 2 - sz / 2)
            ..lineTo(x + sz / 2, h / 2)
            ..lineTo(x, h / 2 + sz / 2)
            ..lineTo(x - sz / 2, h / 2)
            ..close();
      canvas.drawPath(p, fillPaint);
      canvas.drawPath(p, strokePaint);
    }
    canvas.drawLine(
      Offset(0, h * 0.25),
      Offset(w, h * 0.25),
      Paint()
        ..color = gold.withValues(alpha: 0.5)
        ..strokeWidth = 0.6,
    );
    canvas.drawLine(
      Offset(0, h * 0.75),
      Offset(w, h * 0.75),
      Paint()
        ..color = gold.withValues(alpha: 0.5)
        ..strokeWidth = 0.6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
