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

  Widget _buildTopLine(PageData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFF4E3A28) : const Color(0xFF5A432D);
    final accent = const Color(0xFF8C6A3E);

    String juzText(int n) {
      const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      return 'الجزء ${n.toString().split('').map((c) => d[int.parse(c)]).join()}';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            data.surahNameAr,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.quranPageInfoStyle(
              fontSize: 12,
              color: textColor,
            ).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.75),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            juzText(data.juz),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.quranPageInfoStyle(
              fontSize: 12,
              color: textColor,
            ).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
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
        Positioned.fill(
          child: Image.asset(
            'assets/fatihah/fatihah_frame.jpeg',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
          child: Column(
            children: [
              const SizedBox(height: 2),
              _buildTopLine(widget.data),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              widget.data.verses
                                  .map((v) => _buildVerseRow(v))
                                  .toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              PageNum(n: widget.data.pageNum),
            ],
          ),
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
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
                      22 * widget.fontScale,
                      2.0,
                      active,
                      widget.showTajwid,
                      inkColor,
                    ),
                    TextSpan(
                      text: ' ${_ar(v.verse)}',
                      style: AppQuranFonts.hafsStyle.copyWith(
                        fontSize: 14.5 * widget.fontScale,
                        color:
                            active
                                ? (isDark ? Colors.white : AppColors.hl)
                                : AppColors.gold,
                        fontWeight: FontWeight.bold,
                        height: 2.0,
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
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Row(
        children: [
          const Expanded(child: OrnamentSide(mirror: false)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242424) : const Color(0xFFF6EEE0),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.22),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'سُورَةُ ٱلْفَاتِحَةِ',
              style: AppTextStyle.quranSurahNameStyle(
                fontSize: 17,
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
        height: 30,
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
    final bg = const Color(0xFFF3E8D0);
    final gold = const Color(0xFFB38A54);
    final brown = const Color(0xFF7D5B36);
    final green = const Color(0xFF7F9A5A);
    final pink = const Color(0xFFC8A18A);
    final rose = const Color(0xFFB77B74);

    canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    // Outer frame
    canvas.drawRect(
      Rect.fromLTWH(7, 7, w - 14, h - 14),
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawRect(
      Rect.fromLTWH(12, 12, w - 24, h - 24),
      Paint()
        ..color = brown.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    _drawFloralBorder(canvas, Rect.fromLTWH(16, 16, w - 32, h - 32), gold, brown, green, pink, rose);
    _drawInnerArch(canvas, Rect.fromLTWH(30, 30, w - 60, h - 60), gold, brown);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  void _drawFloralBorder(
    Canvas canvas,
    Rect rect,
    Color gold,
    Color brown,
    Color green,
    Color pink,
    Color rose,
  ) {
    final left = rect.left;
    final top = rect.top;
    final right = rect.right;
    final bottom = rect.bottom;

    // top/bottom vine strips
    _drawVineRow(canvas, left, top, rect.width, gold, brown, green, pink, rose, true);
    _drawVineRow(canvas, left, bottom, rect.width, gold, brown, green, pink, rose, false);

    // side floral columns
    _drawVineColumn(canvas, left, top, rect.height, gold, brown, green, pink, rose, true);
    _drawVineColumn(canvas, right, top, rect.height, gold, brown, green, pink, rose, false);

    // corner blossoms
    for (final o in [
      Offset(left, top),
      Offset(right, top),
      Offset(left, bottom),
      Offset(right, bottom),
    ]) {
      _drawCornerRosette(canvas, o, gold, brown, green, pink, rose);
    }
  }

  void _drawVineRow(
    Canvas canvas,
    double x,
    double y,
    double width,
    Color gold,
    Color brown,
    Color green,
    Color pink,
    Color rose,
    bool topRow,
  ) {
    final stroke = Paint()
      ..color = brown.withValues(alpha: 0.75)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final accent = Paint()
      ..color = gold.withValues(alpha: 0.55)
      ..strokeWidth = 0.8;
    final colors = [green, pink, rose, brown];
    for (double dx = 18; dx < width - 18; dx += 24) {
      final cx = x + dx;
      final cy = topRow ? y : y;
      final wave = Path()
        ..moveTo(cx - 10, cy)
        ..quadraticBezierTo(cx - 4, cy - 6, cx, cy)
        ..quadraticBezierTo(cx + 4, cy + 6, cx + 10, cy);
      canvas.drawPath(wave, stroke);
      canvas.drawCircle(Offset(cx - 3, cy + (topRow ? 2 : -2)), 2.4, Paint()..color = colors[(dx ~/ 24) % colors.length]);
      _drawLeaf(canvas, Offset(cx + 5, cy + (topRow ? -2 : 2)), topRow ? -0.8 : 0.8, green);
      _drawFlower(canvas, Offset(cx, cy), 2.8, colors[(dx ~/ 24) % colors.length], brown);
      canvas.drawLine(
        Offset(cx - 12, cy),
        Offset(cx + 12, cy),
        accent,
      );
    }
  }

  void _drawVineColumn(
    Canvas canvas,
    double x,
    double y,
    double height,
    Color gold,
    Color brown,
    Color green,
    Color pink,
    Color rose,
    bool leftSide,
  ) {
    final stroke = Paint()
      ..color = brown.withValues(alpha: 0.75)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final colors = [green, pink, rose, gold];
    for (double dy = 20; dy < height - 20; dy += 26) {
      final cx = x;
      final cy = y + dy;
      final wave = Path()
        ..moveTo(cx, cy - 10)
        ..quadraticBezierTo(cx + (leftSide ? 6 : -6), cy - 4, cx, cy)
        ..quadraticBezierTo(cx + (leftSide ? -6 : 6), cy + 4, cx, cy + 10);
      canvas.drawPath(wave, stroke);
      _drawLeaf(canvas, Offset(cx + (leftSide ? 4 : -4), cy - 4), leftSide ? 0.2 : math.pi - 0.2, green);
      _drawFlower(canvas, Offset(cx, cy), 2.7, colors[(dy ~/ 26) % colors.length], brown);
      canvas.drawCircle(Offset(cx, cy), 1.1, Paint()..color = gold.withValues(alpha: 0.7));
    }
  }

  void _drawCornerRosette(
    Canvas canvas,
    Offset origin,
    Color gold,
    Color brown,
    Color green,
    Color pink,
    Color rose,
  ) {
    final p = Paint()..style = PaintingStyle.stroke;
    final fill = Paint()..style = PaintingStyle.fill;
    final dx = origin.dx;
    final dy = origin.dy;
    final rosetteColors = [gold, pink, rose, green];
    for (int i = 0; i < 4; i++) {
      final offset = 8.0 + i * 2.5;
      p
        ..color = rosetteColors[i].withValues(alpha: 0.85)
        ..strokeWidth = 0.8;
      fill.color = rosetteColors[i].withValues(alpha: 0.12);
      final leafPath = Path()
        ..moveTo(dx + offset, dy)
        ..quadraticBezierTo(dx + offset + 3, dy - 4, dx + offset + 6, dy)
        ..quadraticBezierTo(dx + offset + 3, dy + 4, dx + offset, dy);
      canvas.drawPath(leafPath, fill);
      canvas.drawPath(leafPath, p);
    }
    canvas.drawCircle(Offset(dx, dy), 5.2, Paint()..color = gold);
    canvas.drawCircle(Offset(dx, dy), 3.0, Paint()..color = brown);
    canvas.drawCircle(Offset(dx, dy), 1.2, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  void _drawFlower(
    Canvas canvas,
    Offset center,
    double r,
    Color petal,
    Color stroke,
  ) {
    final petals = Paint()..color = petal.withValues(alpha: 0.18);
    final outline = Paint()
      ..color = stroke.withValues(alpha: 0.65)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5;
      final px = center.dx + math.cos(a) * r;
      final py = center.dy + math.sin(a) * r;
      canvas.drawCircle(Offset(px, py), r * 0.55, petals);
      canvas.drawCircle(Offset(px, py), r * 0.55, outline);
    }
    canvas.drawCircle(center, r * 0.42, Paint()..color = stroke.withValues(alpha: 0.75));
  }

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double angle,
    Color leafColor,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(4, -2, 8, 0)
      ..quadraticBezierTo(4, 2, 0, 0);
    canvas.drawPath(path, Paint()..color = leafColor.withValues(alpha: 0.35));
    canvas.drawPath(
      path,
      Paint()
        ..color = leafColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    canvas.restore();
  }

  void _drawInnerArch(
    Canvas canvas,
    Rect rect,
    Color gold,
    Color brown,
  ) {
    final path = Path()
      ..moveTo(rect.left, rect.top + rect.height * 0.15)
      ..quadraticBezierTo(rect.left, rect.top, rect.left + rect.width * 0.14, rect.top)
      ..lineTo(rect.right - rect.width * 0.14, rect.top)
      ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + rect.height * 0.15)
      ..lineTo(rect.right, rect.bottom - rect.height * 0.15)
      ..quadraticBezierTo(rect.right, rect.bottom, rect.right - rect.width * 0.14, rect.bottom)
      ..lineTo(rect.left + rect.width * 0.14, rect.bottom)
      ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - rect.height * 0.15)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = gold.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = brown.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }
}
