import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as q;
import '../../constants/quran_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_style.dart';
import '../../models/settings_model.dart';
import '../../models/verse_ref.dart';
import '../../utils/quran_utils.dart';

class PageHeader extends StatelessWidget {
  final PageData data;
  const PageHeader({super.key, required this.data});

  String _juzTxt(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return 'الجزء ${n.toString().split('').map((c) => d[int.parse(c)]).join()}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: isDark ? 0.10 : 0.16),
            isDark ? const Color(0xFF252525) : AppColors.hdrBg,
            AppColors.gold.withValues(alpha: isDark ? 0.10 : 0.16),
          ],
        ),
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.65)),
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.65)),
        ),
      ),
      child: CustomPaint(
        painter: HeaderFooterOrnamentPainter(isDark: isDark),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.surahNameAr,
                style: AppTextStyle.quranPageInfoStyle(
                  fontSize: 12,
                  color: textColor,
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.goldLt,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF252525) : AppColors.hdrBg,
                    width: 1,
                  ),
                ),
              ),
              Text(
                _juzTxt(data.juz),
                style: AppTextStyle.quranPageInfoStyle(
                  fontSize: 12,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderFooterOrnamentPainter extends CustomPainter {
  final bool isDark;
  final bool compact;

  const HeaderFooterOrnamentPainter({
    required this.isDark,
    this.compact = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final linePaint =
        Paint()
          ..color = AppColors.goldLt.withValues(alpha: isDark ? 0.46 : 0.62)
          ..strokeWidth = 0.65;
    final softPaint =
        Paint()
          ..color = AppColors.gold.withValues(alpha: isDark ? 0.22 : 0.32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.55;
    final accentPaint =
        Paint()
          ..color = AppColors.goldLt.withValues(alpha: 0.72)
          ..style = PaintingStyle.fill;
    final centerGap = compact ? 30.0 : 22.0;
    final edge = compact ? 32.0 : 18.0;

    canvas.drawLine(
      Offset(edge, cy),
      Offset(size.width / 2 - centerGap, cy),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width / 2 + centerGap, cy),
      Offset(size.width - edge, cy),
      linePaint,
    );

    for (final x in [edge, size.width - edge]) {
      _drawDiamond(canvas, Offset(x, cy), compact ? 3.0 : 3.8, accentPaint);
    }

    if (!compact) {
      for (final x in [edge + 8, size.width - edge - 8]) {
        canvas.drawCircle(Offset(x, cy), 1.6, accentPaint);
      }
      canvas.drawCircle(Offset(size.width / 2, cy), 10, softPaint);
      canvas.drawCircle(Offset(size.width / 2, cy), 7, softPaint);
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        canvas.drawLine(
          Offset(
            size.width / 2 + math.cos(angle) * 7,
            cy + math.sin(angle) * 7,
          ),
          Offset(
            size.width / 2 + math.cos(angle) * 10,
            cy + math.sin(angle) * 10,
          ),
          softPaint,
        );
      }
    } else {
      _drawDiamond(canvas, Offset(size.width / 2 - 22, cy), 2.4, accentPaint);
      _drawDiamond(canvas, Offset(size.width / 2 + 22, cy), 2.4, accentPaint);
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double radius, Paint paint) {
    final path =
        Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy)
          ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeaderFooterOrnamentPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.compact != compact;
  }
}

class MushafDividerPainter extends CustomPainter {
  final bool isDark;
  final bool thick;

  const MushafDividerPainter({required this.isDark, required this.thick});

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final goldPaint =
        Paint()
          ..color = AppColors.goldLt.withValues(alpha: isDark ? 0.60 : 0.78)
          ..strokeWidth = thick ? 0.85 : 0.6;
    final softPaint =
        Paint()
          ..color = AppColors.gold.withValues(alpha: isDark ? 0.24 : 0.38)
          ..strokeWidth = 0.55;

    canvas.drawLine(
      Offset.zero.translate(6, cy),
      Offset(size.width - 6, cy),
      goldPaint,
    );
    if (thick) {
      canvas.drawLine(
        Offset(16, cy + 2),
        Offset(size.width - 16, cy + 2),
        softPaint,
      );
    }
    for (final x in [8.0, size.width - 8]) {
      canvas.drawCircle(Offset(x, cy), 1.5, goldPaint);
    }
    _drawDividerDiamond(canvas, Offset(size.width / 2, cy), goldPaint);
  }

  void _drawDividerDiamond(Canvas canvas, Offset center, Paint paint) {
    const radius = 3.0;
    final path =
        Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy)
          ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant MushafDividerPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.thick != thick;
  }
}

class MushafLineGuidePainter extends CustomPainter {
  final bool isDark;
  final double rowHeight;
  final List<double>? linePositions;

  const MushafLineGuidePainter({
    required this.isDark,
    required this.rowHeight,
    this.linePositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rowHeight <= 0 || size.width < 32) return;

    final linePaint =
        Paint()
          ..color = AppColors.goldLt.withValues(alpha: isDark ? 0.56 : 0.68)
          ..strokeWidth = 0.90;
    final softLinePaint =
        Paint()
          ..color = AppColors.gold.withValues(alpha: isDark ? 0.18 : 0.28)
          ..strokeWidth = 0.45;
    final dotPaint =
        Paint()
          ..color = AppColors.goldLt.withValues(alpha: isDark ? 0.70 : 0.82)
          ..style = PaintingStyle.fill;
    final left = 5.0;
    final right = size.width - 5.0;

    final positions =
        linePositions ??
        [for (double y = rowHeight; y < size.height - 1; y += rowHeight) y];
    for (final y in positions) {
      canvas.drawLine(
        Offset(left + 7, y + 2),
        Offset(right - 7, y + 2),
        softLinePaint,
      );
      canvas.drawLine(Offset(left, y), Offset(right, y), linePaint);
      canvas.drawCircle(Offset(left, y), 1.35, dotPaint);
      canvas.drawCircle(Offset(right, y), 1.35, dotPaint);
      canvas.drawCircle(Offset(left + 4.5, y), 0.85, dotPaint);
      canvas.drawCircle(Offset(right - 4.5, y), 0.85, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MushafLineGuidePainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.linePositions != linePositions;
  }
}

class Basmalah extends StatelessWidget {
  final MushafFont mushafFont;

  const Basmalah({super.key, required this.mushafFont});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bismillah = QuranUtils.getCleanVerse(1, 1, verseEndSymbol: false);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: isDark ? 0.1 : 0.05),
        border: Border(
          top: BorderSide(
            color: AppColors.gold.withValues(alpha: isDark ? 0.35 : 0.55),
            width: 0.8,
          ),
          bottom: BorderSide(
            color: AppColors.gold.withValues(alpha: isDark ? 0.35 : 0.55),
            width: 0.8,
          ),
        ),
      ),
      child: Text(
        bismillah,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: AppQuranFonts.styleFor(mushafFont).copyWith(
          fontSize: 18 * AppQuranFonts.textScaleFor(mushafFont),
          color: isDark ? Colors.white : AppColors.dark,
          height: AppQuranFonts.lineHeightFor(mushafFont) * 0.86,
        ),
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
    final textColor = isDark ? Colors.white : AppColors.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: isDark ? 0.05 : 0.03),
            AppColors.gold.withValues(alpha: isDark ? 0.2 : 0.12),
            AppColors.gold.withValues(alpha: isDark ? 0.05 : 0.03),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: isDark ? 0.25 : 0.4),
          width: 0.7,
        ),
      ),
      child: Column(
        children: [
          Text(
            'سُورَةُ $surahNameAr',
            textAlign: TextAlign.center,
            style: AppTextStyle.quranSurahNameStyle(
              fontSize: 17,
              color: textColor,
            ),
          ),
          Text(
            '${q.getSurahName(surahIndex)} · ${q.getVerseCount(surahIndex)} Ayat',
            style: TextStyle(
              fontSize: 8.5,
              color: textColor.withValues(alpha: 0.45),
              letterSpacing: 0.8,
            ),
          ),
        ],
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
    return CustomPaint(
      painter: MushafDividerPainter(isDark: isDark, thick: thick),
      child: SizedBox(height: thick ? 5 : 3),
    );
  }
}

class PageNum extends StatelessWidget {
  final int n;
  const PageNum({super.key, required this.n});
  static String _ar(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;
    return CustomPaint(
      painter: HeaderFooterOrnamentPainter(isDark: isDark, compact: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.circle,
              size: 3,
              color: AppColors.goldLt.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 6),
            Text(
              _ar(n),
              style: AppTextStyle.quranPageInfoStyle(
                fontSize: 13,
                color: textColor,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.circle,
              size: 3,
              color: AppColors.goldLt.withValues(alpha: 0.65),
            ),
          ],
        ),
      ),
    );
  }
}

class FramePainter extends CustomPainter {
  final bool isDark;
  const FramePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final darkColor = isDark ? Colors.white : AppColors.dark;
    final frameBg = isDark ? const Color(0xFF151515) : AppColors.frameBg;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          colors: [frameBg, frameBg.withValues(alpha: 0.9), frameBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    _pattern(canvas, w, h, darkColor);
    _r(canvas, 0, 0, w, h, darkColor, 3.5);
    _r(canvas, 3.5, 3.5, w - 7, h - 7, AppColors.gold, 1.8);
    _r(canvas, 6, 6, w - 12, h - 12, darkColor.withValues(alpha: 0.35), 0.8);
    _r(
      canvas,
      8.5,
      8.5,
      w - 17,
      h - 17,
      AppColors.gold.withValues(alpha: 0.55),
      0.7,
    );
    _strip(canvas, w, h, darkColor);
    for (final c in [
      [3.5, 3.5, 0.0],
      [w - 3.5, 3.5, math.pi / 2],
      [3.5, h - 3.5, -math.pi / 2],
      [w - 3.5, h - 3.5, math.pi],
    ]) {
      canvas.save();
      canvas.translate(c[0], c[1]);
      canvas.rotate(c[2]);
      _corner(canvas, darkColor);
      canvas.restore();
    }
    _side(canvas, 3.5, h / 2, false, darkColor);
    _side(canvas, w - 3.5, h / 2, true, darkColor);
  }

  void _pattern(Canvas canvas, double w, double h, Color darkColor) {
    final p =
        Paint()
          ..color = darkColor.withValues(alpha: 0.04)
          ..style = PaintingStyle.fill;
    const step = 20.0;
    for (double x = 0; x < w; x += step) {
      for (double y = 0; y < h; y += step) {
        final path =
            Path()
              ..moveTo(x + step / 2, y)
              ..lineTo(x + step, y + step / 2)
              ..lineTo(x + step / 2, y + step)
              ..lineTo(x, y + step / 2)
              ..close();
        canvas.drawPath(path, p);
      }
    }
    final sp =
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.10)
          ..style = PaintingStyle.fill;
    for (final pos in [
      [w * .22, h * .13],
      [w * .78, h * .13],
      [w * .22, h * .87],
      [w * .78, h * .87],
    ]) {
      _star8(canvas, pos[0], pos[1], 13, sp);
    }
  }

  void _star8(Canvas canvas, double cx, double cy, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final oa = i * math.pi / 4 - math.pi / 8;
      final ia = oa + math.pi / 8;
      final ox = cx + r * math.cos(oa);
      final oy = cy + r * math.sin(oa);
      final ix = cx + (r * .42) * math.cos(ia);
      final iy = cy + (r * .42) * math.sin(ia);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, p);
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

  void _strip(Canvas canvas, double w, double h, Color darkColor) {
    final f =
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.28)
          ..style = PaintingStyle.fill;
    final s =
        Paint()
          ..color = darkColor.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6;
    const step = 12.0;
    const sz = 5.5;
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

    for (double x = step; x < w - step; x += step) {
      d(x, 5.5 + sz / 2);
      d(x, h - 5.5 - sz / 2);
    }
    for (double y = step; y < h - step; y += step) {
      d(5.5 + sz / 2, y);
      d(w - 5.5 - sz / 2, y);
    }
  }

  void _corner(Canvas canvas, Color darkColor) {
    const r1 = 18.0, r2 = 11.0, r3 = 6.0, r4 = 3.0;
    canvas.drawCircle(
      const Offset(r1, r1),
      r1,
      Paint()..color = AppColors.gold,
    );
    canvas.drawCircle(
      const Offset(r1, r1),
      r1,
      Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    canvas.drawCircle(
      const Offset(r1, r1),
      r2,
      Paint()..color = darkColor.withValues(alpha: 0.45),
    );
    canvas.drawCircle(
      const Offset(r1, r1),
      r3,
      Paint()..color = AppColors.gold,
    );
    canvas.drawCircle(const Offset(r1, r1), r4, Paint()..color = darkColor);
    final lp =
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.7)
          ..strokeWidth = 0.9
          ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(r1 + math.cos(a) * r4, r1 + math.sin(a) * r4),
        Offset(r1 + math.cos(a) * r1, r1 + math.sin(a) * r1),
        lp,
      );
    }
  }

  void _side(Canvas canvas, double x, double cy, bool right, Color darkColor) {
    const sz = 16.0;
    final ox = right ? x - sz : x + sz;
    final p =
        Path()
          ..moveTo(x, cy - sz)
          ..lineTo(ox, cy - sz * .38)
          ..lineTo(ox + (right ? -sz * .28 : sz * .28), cy)
          ..lineTo(ox, cy + sz * .38)
          ..lineTo(x, cy + sz)
          ..lineTo(right ? x - sz * .38 : x + sz * .38, cy)
          ..close();
    canvas.drawPath(p, Paint()..color = AppColors.gold);
    canvas.drawPath(
      p,
      Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FrameOverlayPainter extends CustomPainter {
  final bool isDark;
  const FrameOverlayPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gold = AppColors.goldLt;
    final mutedGold = AppColors.gold;
    final darkColor = isDark ? const Color(0xFF17130F) : AppColors.dark;

    _rect(canvas, 1.5, 1.5, w - 3, h - 3, gold, 1.0);
    _rect(canvas, 5, 5, w - 10, h - 10, mutedGold, 0.8);
    _rect(canvas, 9, 9, w - 18, h - 18, gold.withValues(alpha: 0.64), 0.65);
    _rect(
      canvas,
      13,
      13,
      w - 26,
      h - 26,
      mutedGold.withValues(alpha: 0.48),
      0.55,
    );

    for (final corner in [
      (Offset.zero, 0.0),
      (Offset(w, 0), math.pi / 2),
      (Offset(0, h), -math.pi / 2),
      (Offset(w, h), math.pi),
    ]) {
      canvas.save();
      canvas.translate(corner.$1.dx, corner.$1.dy);
      canvas.rotate(corner.$2);
      _cornerArabesque(canvas, gold, mutedGold, darkColor);
      canvas.restore();
    }

    _drawSideFlourish(canvas, Offset(10, h / 2), false, gold, mutedGold);
    _drawSideFlourish(canvas, Offset(w - 10, h / 2), true, gold, mutedGold);
  }

  void _rect(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    Color color,
    double width,
  ) {
    canvas.drawRect(
      Rect.fromLTWH(x, y, w, h),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void _cornerArabesque(
    Canvas canvas,
    Color gold,
    Color mutedGold,
    Color darkColor,
  ) {
    final panel =
        Path()
          ..moveTo(5, 48)
          ..lineTo(5, 5)
          ..lineTo(48, 5)
          ..cubicTo(39, 10, 35, 18, 33, 26)
          ..cubicTo(25, 29, 18, 35, 15, 44)
          ..cubicTo(12, 46, 9, 48, 5, 48)
          ..close();
    canvas.drawPath(
      panel,
      Paint()..color = darkColor.withValues(alpha: isDark ? 0.92 : 0.14),
    );
    canvas.drawPath(
      panel,
      Paint()
        ..color = gold.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    final innerCurve =
        Path()
          ..moveTo(10, 39)
          ..cubicTo(16, 27, 22, 19, 39, 10)
          ..moveTo(12, 46)
          ..cubicTo(19, 31, 28, 21, 46, 12);
    canvas.drawPath(
      innerCurve,
      Paint()
        ..color = mutedGold.withValues(alpha: 0.76)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75,
    );

    _petal(canvas, const Offset(17, 18), 7.5, gold, darkColor);
    _petal(canvas, const Offset(27, 12), 5.2, mutedGold, darkColor);
    _petal(canvas, const Offset(12, 29), 5.2, mutedGold, darkColor);

    for (final point in [
      const Offset(31, 19),
      const Offset(22, 29),
      const Offset(14, 39),
      const Offset(39, 13),
    ]) {
      canvas.drawCircle(
        point,
        1.75,
        Paint()..color = gold.withValues(alpha: 0.84),
      );
      canvas.drawCircle(point, 0.65, Paint()..color = darkColor);
    }
  }

  void _petal(
    Canvas canvas,
    Offset center,
    double radius,
    Color gold,
    Color darkColor,
  ) {
    final fill =
        Paint()
          ..color = gold.withValues(alpha: 0.30)
          ..style = PaintingStyle.fill;
    final stroke =
        Paint()
          ..color = gold.withValues(alpha: 0.86)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.65;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final path =
          Path()
            ..moveTo(center.dx, center.dy)
            ..quadraticBezierTo(
              center.dx + math.cos(angle - 0.5) * radius,
              center.dy + math.sin(angle - 0.5) * radius,
              center.dx + math.cos(angle) * radius,
              center.dy + math.sin(angle) * radius,
            )
            ..quadraticBezierTo(
              center.dx + math.cos(angle + 0.5) * radius,
              center.dy + math.sin(angle + 0.5) * radius,
              center.dx,
              center.dy,
            );
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
    canvas.drawCircle(center, 1.6, Paint()..color = gold);
    canvas.drawCircle(center, 0.65, Paint()..color = darkColor);
  }

  void _drawSideFlourish(
    Canvas canvas,
    Offset center,
    bool right,
    Color gold,
    Color mutedGold,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (right) canvas.scale(-1, 1);
    final stroke =
        Paint()
          ..color = gold.withValues(alpha: 0.82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.75;
    canvas.drawLine(const Offset(0, -30), const Offset(0, 30), stroke);
    for (final y in [-30.0, -20.0, 0.0, 20.0, 30.0]) {
      canvas.drawCircle(
        Offset.zero.translate(0, y),
        1.8,
        Paint()..color = mutedGold,
      );
    }
    final leaf =
        Path()
          ..moveTo(0, -15)
          ..cubicTo(11, -11, 11, -4, 0, 0)
          ..cubicTo(11, 4, 11, 11, 0, 15);
    canvas.drawPath(leaf, stroke);
    canvas.drawCircle(Offset.zero, 3.2, stroke);
    canvas.drawCircle(Offset.zero, 1.25, Paint()..color = mutedGold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FrameOverlayPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
