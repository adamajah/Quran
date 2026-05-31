import 'dart:math' as math;

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
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: FatihahFramePainter())),
        Column(
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
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : const Color(0xFFF4EBDD),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
                width: 0.6,
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
    return Transform.scale(
      scaleX: mirror ? -1 : 1,
      child: SizedBox(
        height: 28,
        child: CustomPaint(
          painter: OrnamentPainter(
            gold: AppColors.gold,
            dark: isDark ? Colors.white : AppColors.dark,
          ),
        ),
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
    final y = h / 2;
    final accent = gold.withValues(alpha: 0.7);
    final ink = dark.withValues(alpha: 0.45);

    canvas.drawLine(
      Offset(2, y),
      Offset(w - 2, y),
      Paint()
        ..color = accent.withValues(alpha: 0.55)
        ..strokeWidth = 0.8,
    );

    for (final x in [w * 0.2, w * 0.38, w * 0.62, w * 0.8]) {
      final path = Path()
        ..moveTo(x, y - 4)
        ..lineTo(x + 4, y)
        ..lineTo(x, y + 4)
        ..lineTo(x - 4, y)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = accent.withValues(alpha: 0.18),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6,
      );
    }

    canvas.drawCircle(
      Offset(w / 2, y),
      2.5,
      Paint()..color = ink,
    );
    canvas.drawCircle(
      Offset(w / 2, y),
      1.2,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FatihahFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bg = const Color(0xFFF3E4C6);
    final gold = const Color(0xFF9A6B34);
    final blue = const Color(0xFF274E8A);
    final red = const Color(0xFF8B2A2A);
    final teal = const Color(0xFF2E7C72);

    canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    // outer and inner borders
    canvas.drawRect(
      Rect.fromLTWH(6, 6, w - 12, h - 12),
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawRect(
      Rect.fromLTWH(11, 11, w - 22, h - 22),
      Paint()
        ..color = gold.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    _drawTopBottomBand(canvas, w, gold, blue, teal, red);
    _drawSideBand(canvas, h, gold, blue, red, teal, left: true);
    _drawSideBand(canvas, h, gold, blue, red, teal, left: false);
    _drawCorners(canvas, w, h, gold, blue, teal, red);
    _drawCenterMedallion(canvas, w, gold, blue, red, teal);
  }

  void _drawTopBottomBand(
    Canvas canvas,
    double w,
    Color gold,
    Color blue,
    Color teal,
    Color red,
  ) {
    for (final y in [4.0, 52.0]) {
      canvas.drawRect(
        Rect.fromLTWH(18, y, w - 36, 18),
        Paint()..color = blue.withValues(alpha: 0.95),
      );
      canvas.drawRect(
        Rect.fromLTWH(18, y + 18, w - 36, 6),
        Paint()..color = gold.withValues(alpha: 0.4),
      );

      // woven loops
      final loopPaint = Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      for (double x = 24; x < w - 24; x += 28) {
        final p = Path()
          ..moveTo(x, y + 9)
          ..quadraticBezierTo(x + 7, y - 2, x + 14, y + 9)
          ..quadraticBezierTo(x + 21, y + 20, x + 28, y + 9);
        canvas.drawPath(p, loopPaint);
        canvas.drawCircle(
          Offset(x + 14, y + 9),
          2.2,
          Paint()..color = [teal, red, blue][((x / 28).round()) % 3],
        );
      }
      // center medallion
      canvas.drawCircle(Offset(w / 2, y + 9), 14, Paint()..color = gold);
      canvas.drawCircle(
        Offset(w / 2, y + 9),
        12,
        Paint()..color = blue,
      );
      canvas.drawCircle(
        Offset(w / 2, y + 9),
        7,
        Paint()..color = bgColor(y),
      );
      canvas.drawLine(
        Offset(w / 2 - 10, y + 9),
        Offset(w / 2 + 10, y + 9),
        Paint()
          ..color = red
          ..strokeWidth = 1.0,
      );
      canvas.drawLine(
        Offset(w / 2, y - 1),
        Offset(w / 2, y + 19),
        Paint()
          ..color = teal
          ..strokeWidth = 1.0,
      );
    }
  }

  void _drawSideBand(
    Canvas canvas,
    double h,
    Color gold,
    Color blue,
    Color red,
    Color teal, {
    required bool left,
  }) {
    final x = left ? 4.0 : 18.0;
    final w = 14.0;
    final colors = [blue, red, teal, gold, blue, red, teal, gold];
    for (int i = 0; i < colors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(x, 74.0 + i * 52.0, w, 52.0),
        Paint()..color = colors[i].withValues(alpha: 0.92),
      );
      canvas.drawRect(
        Rect.fromLTWH(x, 74.0 + i * 52.0, w, 52.0),
        Paint()
          ..color = gold.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      final cy = 100.0 + i * 52.0;
      final path = Path()
        ..moveTo(left ? x + 2 : x + w - 2, cy - 16)
        ..quadraticBezierTo(
          left ? x + 12 : x + 2,
          cy,
          left ? x + 2 : x + w - 2,
          cy + 16,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = gold.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      canvas.drawCircle(
        Offset(left ? x + 7 : x + 7, cy),
        2.2,
        Paint()..color = [teal, red, blue][i % 3],
      );
    }
  }

  void _drawCorners(
    Canvas canvas,
    double w,
    double h,
    Color gold,
    Color blue,
    Color teal,
    Color red,
  ) {
    final corners = [
      const Offset(16, 16),
      Offset(w - 16, 16),
      Offset(16, h - 16),
      Offset(w - 16, h - 16),
    ];
    for (int i = 0; i < corners.length; i++) {
      final o = corners[i];
      canvas.drawCircle(o, 13, Paint()..color = gold);
      canvas.drawCircle(o, 10, Paint()..color = blue);
      canvas.drawCircle(o, 5, Paint()..color = Colors.white.withValues(alpha: 0.7));
      final p = Path()
        ..moveTo(o.dx - 12, o.dy)
        ..quadraticBezierTo(o.dx, o.dy - 12, o.dx + 12, o.dy)
        ..quadraticBezierTo(o.dx, o.dy + 12, o.dx - 12, o.dy);
      canvas.drawPath(
        p,
        Paint()
          ..color = [teal, red, blue][i % 3]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  void _drawCenterMedallion(
    Canvas canvas,
    double w,
    Color gold,
    Color blue,
    Color red,
    Color teal,
  ) {
    final cx = w / 2;
    final cy = 31.0;
    canvas.drawCircle(Offset(cx, cy), 18, Paint()..color = gold);
    canvas.drawCircle(Offset(cx, cy), 15, Paint()..color = blue);
    canvas.drawCircle(
      Offset(cx, cy),
      8,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    final star = Path();
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final r = i.isEven ? 7.0 : 3.2;
      final x = cx + math.cos(a) * r;
      final y = cy + math.sin(a) * r;
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = teal);
    canvas.drawCircle(Offset(cx, cy), 2.4, Paint()..color = red);
  }

  Color bgColor(double y) {
    return y < 40 ? const Color(0xFFF3E4C6) : const Color(0xFFF1E1BF);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
