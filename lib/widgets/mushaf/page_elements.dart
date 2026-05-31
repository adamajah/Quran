import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as q;

import '../../constants/app_colors.dart';
import '../../constants/app_text_style.dart';
import '../../constants/quran_fonts.dart';
import '../../models/verse_ref.dart';

String _arabicDigits(int n) {
  const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}

String _juzText(int n) => 'الجزء ${_arabicDigits(n)}';

class PageHeader extends StatelessWidget {
  final PageData data;
  const PageHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF6F2E9) : AppColors.dark;
    final gold = AppColors.gold.withValues(alpha: isDark ? 0.7 : 0.82);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.surahNameAr,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.quranPageInfoStyle(
                    fontSize: 13,
                    color: textColor,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gold.withValues(alpha: 0.18),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  _juzText(data.juz),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.quranPageInfoStyle(
                    fontSize: 13,
                    color: textColor,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ThinOrnamentLine(color: gold),
        ],
      ),
    );
  }
}

class Basmalah extends StatelessWidget {
  const Basmalah({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bismillah = q.getVerse(1, 1, verseEndSymbol: false);
    final gold = AppColors.gold.withValues(alpha: isDark ? 0.7 : 0.8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Column(
        children: [
          _ThinOrnamentLine(color: gold),
          const SizedBox(height: 8),
          Text(
            bismillah,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppQuranFonts.hafsStyle.copyWith(
              fontSize: 19,
              color: isDark ? const Color(0xFFF8F6F0) : AppColors.dark,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 8),
          _ThinOrnamentLine(color: gold),
        ],
      ),
    );
  }
}

class SurahBanner extends StatelessWidget {
  final int surahIndex;
  final String surahNameAr;
  const SurahBanner({
    super.key,
    required this.surahIndex,
    required this.surahNameAr,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF6F2E9) : AppColors.dark;
    final bg = isDark ? const Color(0xFF181818) : const Color(0xFFF2EBDD);
    final gold = AppColors.gold.withValues(alpha: isDark ? 0.72 : 0.82);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: isDark ? 0.72 : 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gold.withValues(alpha: 0.34), width: 0.7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'سُورَةُ $surahNameAr',
              textAlign: TextAlign.center,
              style: AppTextStyle.quranSurahNameStyle(
                fontSize: 15.5,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 18, height: 0.7, color: gold.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text(
                  '${q.getSurahName(surahIndex)} · ${q.getVerseCount(surahIndex)} Ayat',
                  style: TextStyle(
                    fontSize: 8.2,
                    color: gold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 18, height: 0.7, color: gold.withValues(alpha: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MushafRule extends StatelessWidget {
  final bool thick;
  const MushafRule({super.key, this.thick = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppColors.gold.withValues(alpha: isDark ? 0.75 : 0.88);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: thick ? 10 : 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: thick ? 1.2 : 0.8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gold.withValues(alpha: 0),
                    gold,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: thick ? 7 : 5,
            height: thick ? 7 : 5,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: gold, shape: BoxShape.circle),
          ),
          Expanded(
            child: Container(
              height: thick ? 1.2 : 0.8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gold,
                    gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PageNum extends StatelessWidget {
  final int n;
  const PageNum({super.key, required this.n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF6F2E9) : AppColors.dark;
    final gold = AppColors.gold.withValues(alpha: isDark ? 0.75 : 0.85);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: [
          Expanded(child: Container(height: 0.8, color: gold.withValues(alpha: 0.35))),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: gold.withValues(alpha: 0.45), width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(color: gold, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  _arabicDigits(n),
                  style: AppTextStyle.quranPageInfoStyle(
                    fontSize: 13,
                    color: textColor,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(color: gold, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 0.8, color: gold.withValues(alpha: 0.35))),
        ],
      ),
    );
  }
}

class AyahNumberBadge extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AyahNumberBadge({
    super.key,
    required this.label,
    required this.active,
    required this.isDark,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.gold;
    final size = 28.0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: AyahNumberPainter(
                isDark: isDark,
                active: active,
                gold: gold,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppQuranFonts.hafsStyle.copyWith(
                fontSize: 10.5,
                color: active
                    ? (isDark ? const Color(0xFFF8F6F0) : AppColors.dark)
                    : (isDark ? const Color(0xFFF8F6F0) : AppColors.dark),
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MushafPagePainter extends CustomPainter {
  final bool isDark;
  const MushafPagePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgTop = isDark ? const Color(0xFF141414) : const Color(0xFF2B261F);
    final bgBottom = isDark ? const Color(0xFF090909) : const Color(0xFF181511);
    final gold = AppColors.gold.withValues(alpha: isDark ? 0.34 : 0.42);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ).createShader(rect),
    );

    final vignette = Paint()..style = PaintingStyle.fill;
    vignette.shader = RadialGradient(
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: isDark ? 0.28 : 0.22),
      ],
      stops: const [0.52, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, vignette);

    final glow = Paint()..style = PaintingStyle.fill;
    glow.shader = RadialGradient(
      colors: [
        AppColors.gold.withValues(alpha: isDark ? 0.08 : 0.06),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(size.width * .5, size.height * .12), radius: size.shortestSide * .75));
    canvas.drawRect(rect, glow);

    final speck = Paint()..color = Colors.white.withValues(alpha: isDark ? 0.012 : 0.02);
    for (double x = 0; x < size.width; x += 24) {
      for (double y = 0; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x + 3, y + 6), 0.5, speck);
      }
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2.0), const Radius.circular(20)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = gold.withValues(alpha: 0.8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(5.0), const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.55
        ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.15),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OrnamentPainter extends CustomPainter {
  final bool isDark;
  const OrnamentPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gold = AppColors.gold.withValues(alpha: isDark ? 0.42 : 0.55);
    final dim = isDark ? Colors.white.withValues(alpha: 0.28) : AppColors.dark.withValues(alpha: 0.25);
    final inset = 12.0;

    // top and bottom thin divider
    canvas.drawLine(
      Offset(inset, inset),
      Offset(size.width - inset, inset),
      Paint()
        ..color = gold
        ..strokeWidth = 0.7,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
      Paint()
        ..color = gold
        ..strokeWidth = 0.7,
    );

    // corner ornaments
    for (final entry in [
      _OrnamentCorner(const Offset(14, 14), 0),
      _OrnamentCorner(Offset(size.width - 14, 14), math.pi / 2),
      _OrnamentCorner(Offset(14, size.height - 14), -math.pi / 2),
      _OrnamentCorner(Offset(size.width - 14, size.height - 14), math.pi),
    ]) {
      canvas.save();
      canvas.translate(entry.offset.dx, entry.offset.dy);
      canvas.rotate(entry.rotation);
      _drawCorner(canvas, gold, dim);
      canvas.restore();
    }

    // center markers
    canvas.drawCircle(Offset(size.width / 2, inset), 2.1, Paint()..color = gold);
    canvas.drawCircle(Offset(size.width / 2, size.height - inset), 2.1, Paint()..color = gold);
    canvas.drawCircle(Offset(inset, size.height / 2), 1.6, Paint()..color = gold);
    canvas.drawCircle(Offset(size.width - inset, size.height / 2), 1.6, Paint()..color = gold);

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      2.4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = gold.withValues(alpha: 0.7),
    );
  }

  void _drawCorner(Canvas canvas, Color gold, Color dim) {
    final fill = Paint()..color = gold.withValues(alpha: 0.15);
    final line = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(10, 0, 14, 10)
      ..quadraticBezierTo(16, 16, 24, 24)
      ..quadraticBezierTo(18, 18, 14, 12)
      ..quadraticBezierTo(8, 8, 0, 0)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, line);

    canvas.drawCircle(const Offset(7, 7), 2.0, Paint()..color = gold);
    canvas.drawCircle(const Offset(7, 7), 0.9, Paint()..color = dim);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AyahNumberPainter extends CustomPainter {
  final bool isDark;
  final bool active;
  final Color gold;

  const AyahNumberPainter({
    required this.isDark,
    required this.active,
    required this.gold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = gold.withValues(alpha: active ? 0.95 : 0.75);
    final inner = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF6EEDB);
    final fill = active
        ? gold.withValues(alpha: 0.20)
        : inner;

    canvas.drawCircle(center, size.shortestSide * 0.5, Paint()..color = outer);
    canvas.drawCircle(
      center,
      size.shortestSide * 0.39,
      Paint()..color = fill,
    );
    canvas.drawCircle(
      center,
      size.shortestSide * 0.39,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = isDark ? Colors.white.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.12),
    );

    final star = Paint()
      ..color = gold.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final innerR = size.shortestSide * 0.17;
      final outerR = size.shortestSide * 0.28;
      canvas.drawLine(
        center + Offset(math.cos(a) * innerR, math.sin(a) * innerR),
        center + Offset(math.cos(a) * outerR, math.sin(a) * outerR),
        star,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FramePainter extends MushafPagePainter {
  const FramePainter({required super.isDark});
}

class LightOrnamentPainter extends OrnamentPainter {
  const LightOrnamentPainter({required super.isDark});
}

class _ThinOrnamentLine extends StatelessWidget {
  final Color color;
  const _ThinOrnamentLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.7,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0), color],
              ),
            ),
          ),
        ),
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Expanded(
          child: Container(
            height: 0.7,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrnamentCorner {
  final Offset offset;
  final double rotation;
  const _OrnamentCorner(this.offset, this.rotation);
}
