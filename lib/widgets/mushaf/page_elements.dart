import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_style.dart';
import '../../constants/quran_fonts.dart';
import '../../models/verse_ref.dart';

String _arabicDigits(int n) {
  const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}

String _juzText(int n) => 'الجزء ${_arabicDigits(n)}';

const _quranLibraryPackage = 'quran_library';
const _surahBannerDarkAsset = 'assets/svg/surahSvgBannerDark.svg';
const _basmalahAsset = 'assets/svg/besmAllah2.svg';
const _ayahNumberAsset = 'assets/svg/suraNum.svg';

class PageHeader extends StatelessWidget {
  final PageData data;
  const PageHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = const Color(0xFFF4EFE6);
    final gold = AppColors.gold.withValues(alpha: isDark ? 0.7 : 0.82);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
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
                width: 9,
                height: 9,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: gold,
                  shape: BoxShape.circle,
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
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 0.85,
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
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: gold,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  height: 0.85,
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
        ],
      ),
    );
  }
}

class Basmalah extends StatelessWidget {
  final Color? color;
  final double width;
  final double height;

  const Basmalah({
    super.key,
    this.color,
    this.width = 230,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = color ?? (isDark ? const Color(0xFFF5EFE3) : AppColors.dark);

    return Center(
      child: SvgPicture.asset(
        _basmalahAsset,
        package: _quranLibraryPackage,
        width: width,
        height: height,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      ),
    );
  }
}

class SurahBanner extends StatelessWidget {
  final String surahNameAr;
  const SurahBanner({
    super.key,
    required this.surahNameAr,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = const Color(0xFFF8F3EA);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 1),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset(
              _surahBannerDarkAsset,
              package: _quranLibraryPackage,
              fit: BoxFit.fill,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'سُورَةُ $surahNameAr',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.quranSurahNameStyle(
                    fontSize: 15.2,
                    color: textColor,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
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
    final textColor = const Color(0xFFF4EFE6);
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
              color: const Color(0xFF2A2A2A),
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
            SvgPicture.asset(
              _ayahNumberAsset,
              package: _quranLibraryPackage,
              width: size,
              height: size,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                active ? gold.withValues(alpha: 0.96) : gold.withValues(alpha: 0.78),
                BlendMode.srcIn,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppQuranFonts.hafsStyle.copyWith(
                fontSize: 10.2,
                color: AppColors.dark,
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
    final bgTop = isDark ? const Color(0xFF151515) : const Color(0xFF2B261F);
    final bgBottom = isDark ? const Color(0xFF0E0E0E) : const Color(0xFF17130F);
    final gold = AppColors.gold.withValues(alpha: isDark ? 0.55 : 0.64);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ).createShader(rect),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.4), const Radius.circular(22)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.95
        ..color = gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(4.6), const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.14),
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
    final inset = 9.0;

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
      _OrnamentCorner(const Offset(11, 11), 0),
      _OrnamentCorner(Offset(size.width - 11, 11), math.pi / 2),
      _OrnamentCorner(Offset(11, size.height - 11), -math.pi / 2),
      _OrnamentCorner(Offset(size.width - 11, size.height - 11), math.pi),
    ]) {
      canvas.save();
      canvas.translate(entry.offset.dx, entry.offset.dy);
      canvas.rotate(entry.rotation);
      _drawCorner(canvas, gold, dim);
      canvas.restore();
    }

    // center markers
    canvas.drawCircle(Offset(size.width / 2, inset), 1.8, Paint()..color = gold);
    canvas.drawCircle(Offset(size.width / 2, size.height - inset), 1.8, Paint()..color = gold);
    canvas.drawCircle(Offset(inset, size.height / 2), 1.4, Paint()..color = gold);
    canvas.drawCircle(Offset(size.width - inset, size.height / 2), 1.4, Paint()..color = gold);

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      2.0,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.65
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
      ..quadraticBezierTo(9, 0, 12, 9)
      ..quadraticBezierTo(15, 15, 23, 23)
      ..quadraticBezierTo(17, 17, 12, 11)
      ..quadraticBezierTo(7, 7, 0, 0)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, line);

    canvas.drawCircle(const Offset(6.5, 6.5), 1.8, Paint()..color = gold);
    canvas.drawCircle(const Offset(6.5, 6.5), 0.85, Paint()..color = dim);
    canvas.drawLine(
      const Offset(2, 9),
      const Offset(9, 2),
      Paint()
        ..color = gold.withValues(alpha: 0.85)
        ..strokeWidth = 0.7,
    );
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

class _OrnamentCorner {
  final Offset offset;
  final double rotation;
  const _OrnamentCorner(this.offset, this.rotation);
}
