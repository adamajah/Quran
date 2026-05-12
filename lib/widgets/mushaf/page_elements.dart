// ─────────────────────────────────────────────────────────────────────────────
// Mushaf Page Elements  (extracted from home_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as q;
import '../../constants/app_colors.dart';
import '../../constants/app_text_style.dart';
import '../../models/verse_ref.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PageHeader
// ─────────────────────────────────────────────────────────────────────────────
class PageHeader extends StatelessWidget {
  final PageData data;
  const PageHeader({super.key, required this.data});

  String _juzTxt(int n) {
    const d = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return 'الجزء ${n.toString().split('').map((c) => d[int.parse(c)]).join()}';
  }

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.hdrBg,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(data.surahNameAr,
          style: AppTextStyle.quranPageInfoStyle(fontSize: 12, color: AppColors.dark)),
      Container(width: 6, height: 6,
          decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
      Text(_juzTxt(data.juz),
          style: AppTextStyle.quranPageInfoStyle(fontSize: 12, color: AppColors.dark)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Basmalah
// ─────────────────────────────────────────────────────────────────────────────
class Basmalah extends StatelessWidget {
  const Basmalah({super.key});
  @override
  Widget build(BuildContext context) {
    final bismillah = q.getVerse(1, 1, verseEndSymbol: false);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.05),
        border: Border(
          top: BorderSide(color: AppColors.gold.withOpacity(0.55), width: 0.8),
          bottom: BorderSide(color: AppColors.gold.withOpacity(0.55), width: 0.8),
        ),
      ),
      child: Text(bismillah,
        textAlign: TextAlign.center, textDirection: TextDirection.rtl,
        style: AppTextStyle.quranVerseStyle(fontSize: 18, color: AppColors.dark, height: 1.6)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SurahBanner
// ─────────────────────────────────────────────────────────────────────────────
class SurahBanner extends StatelessWidget {
  final int surahIndex;
  final String surahNameAr;
  const SurahBanner({super.key, required this.surahIndex, required this.surahNameAr});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(8, 2, 8, 2),
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        AppColors.gold.withOpacity(0.03), AppColors.gold.withOpacity(0.12), AppColors.gold.withOpacity(0.03),
      ]),
      border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 0.7),
    ),
    child: Column(children: [
      Text('سُورَةُ $surahNameAr',
        textAlign: TextAlign.center,
        style: AppTextStyle.quranSurahNameStyle(fontSize: 17, color: AppColors.dark)),
      Text('${q.getSurahName(surahIndex)} · ${q.getVerseCount(surahIndex)} Ayat',
        style: TextStyle(fontSize: 8.5, color: AppColors.dark.withOpacity(0.45), letterSpacing: 0.8)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Rule
// ─────────────────────────────────────────────────────────────────────────────
class Rule extends StatelessWidget {
  final bool thick;
  const Rule({super.key, this.thick = false});
  @override
  Widget build(BuildContext context) => Container(
    height: thick ? 2.0 : 1.0,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(gradient: LinearGradient(colors: [
      AppColors.gold.withOpacity(0.05), AppColors.gold, AppColors.dark, AppColors.gold, AppColors.gold.withOpacity(0.05),
    ])),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PageNum
// ─────────────────────────────────────────────────────────────────────────────
class PageNum extends StatelessWidget {
  final int n;
  const PageNum({super.key, required this.n});
  static String ar(int n) {
    const d = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.circle, size: 4, color: AppColors.gold.withOpacity(0.5)),
      const SizedBox(width: 6),
      Text(ar(n), style: AppTextStyle.quranPageInfoStyle(fontSize: 13, color: AppColors.dark)),
      const SizedBox(width: 6),
      Icon(Icons.circle, size: 4, color: AppColors.gold.withOpacity(0.5)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FramePainter
// ─────────────────────────────────────────────────────────────────────────────
class FramePainter extends CustomPainter {
  final Color gold, goldLt, dark, bg;
  const FramePainter({required this.gold, required this.goldLt, required this.dark, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0,0,w,h), Paint()
      ..shader = LinearGradient(colors:[bg,bg.withOpacity(0.9),bg],
        begin:Alignment.topLeft, end:Alignment.bottomRight)
        .createShader(Rect.fromLTWH(0,0,w,h)));
    _pattern(canvas, w, h);
    _r(canvas, 0,0,w,h, dark, 3.5);
    _r(canvas, 3.5,3.5,w-7,h-7, gold, 1.8);
    _r(canvas, 6,6,w-12,h-12, dark.withOpacity(0.35), 0.8);
    _r(canvas, 8.5,8.5,w-17,h-17, gold.withOpacity(0.55), 0.7);
    _strip(canvas, w, h);
    for (final c in [
      [3.5,3.5,0.0],[w-3.5,3.5,math.pi/2],[3.5,h-3.5,-math.pi/2],[w-3.5,h-3.5,math.pi]
    ]) { canvas.save(); canvas.translate(c[0],c[1]); canvas.rotate(c[2]); _corner(canvas); canvas.restore(); }
    _pend(canvas, w/2, 3.5, true);
    _pend(canvas, w/2, h-3.5, false);
    _side(canvas, 3.5, h/2, false);
    _side(canvas, w-3.5, h/2, true);
  }

  void _pattern(Canvas canvas, double w, double h) {
    final p = Paint()..color=dark.withOpacity(0.04)..style=PaintingStyle.fill;
    const step = 20.0;
    for (double x=0; x<w; x+=step)
      for (double y=0; y<h; y+=step) {
        final path = Path()..moveTo(x+step/2,y)..lineTo(x+step,y+step/2)
          ..lineTo(x+step/2,y+step)..lineTo(x,y+step/2)..close();
        canvas.drawPath(path, p);
      }
    final sp = Paint()..color=gold.withOpacity(0.10)..style=PaintingStyle.fill;
    for (final pos in [[w*.22,h*.13],[w*.78,h*.13],[w*.22,h*.87],[w*.78,h*.87]])
      _star8(canvas, pos[0], pos[1], 13, sp);
  }

  void _star8(Canvas canvas, double cx, double cy, double r, Paint p) {
    final path = Path();
    for (int i=0; i<8; i++) {
      final oa=i*math.pi/4-math.pi/8; final ia=oa+math.pi/8;
      final ox=cx+r*math.cos(oa); final oy=cy+r*math.sin(oa);
      final ix=cx+(r*.42)*math.cos(ia); final iy=cy+(r*.42)*math.sin(ia);
      if (i==0) path.moveTo(ox,oy); else path.lineTo(ox,oy);
      path.lineTo(ix,iy);
    }
    path.close(); canvas.drawPath(path, p);
  }

  void _r(Canvas c,double x,double y,double w,double h,Color col,double sw) =>
    c.drawRect(Rect.fromLTWH(x,y,w,h), Paint()..color=col..style=PaintingStyle.stroke..strokeWidth=sw);

  void _strip(Canvas canvas, double w, double h) {
    final f=Paint()..color=gold.withOpacity(0.28)..style=PaintingStyle.fill;
    final s=Paint()..color=dark.withOpacity(0.45)..style=PaintingStyle.stroke..strokeWidth=0.6;
    const step=12.0; const sz=5.5;
    void d(double cx,double cy) {
      final p=Path()..moveTo(cx,cy-sz/2)..lineTo(cx+sz/2,cy)
        ..lineTo(cx,cy+sz/2)..lineTo(cx-sz/2,cy)..close();
      canvas.drawPath(p,f); canvas.drawPath(p,s);
    }
    for (double x=step; x<w-step; x+=step) { d(x,5.5+sz/2); d(x,h-5.5-sz/2); }
    for (double y=step; y<h-step; y+=step) { d(5.5+sz/2,y); d(w-5.5-sz/2,y); }
  }

  void _corner(Canvas canvas) {
    const r1=18.0,r2=11.0,r3=6.0,r4=3.0;
    canvas.drawCircle(const Offset(r1,r1),r1,Paint()..color=gold);
    canvas.drawCircle(const Offset(r1,r1),r1,Paint()..color=dark..style=PaintingStyle.stroke..strokeWidth=1.0);
    canvas.drawCircle(const Offset(r1,r1),r2,Paint()..color=dark.withOpacity(0.45));
    canvas.drawCircle(const Offset(r1,r1),r3,Paint()..color=gold);
    canvas.drawCircle(const Offset(r1,r1),r4,Paint()..color=dark);
    final lp=Paint()..color=gold.withOpacity(0.7)..strokeWidth=0.9..style=PaintingStyle.stroke;
    for (int i=0; i<8; i++) {
      final a=i*math.pi/4;
      canvas.drawLine(Offset(r1+math.cos(a)*r4,r1+math.sin(a)*r4),
                      Offset(r1+math.cos(a)*r1,r1+math.sin(a)*r1),lp);
    }
  }

  void _pend(Canvas canvas, double cx, double y, bool top) {
    final sy=top?1.0:-1.0;
    final p=Path()..moveTo(cx-22,y)..lineTo(cx-13,y+sy*13)
      ..arcToPoint(Offset(cx+13,y+sy*13),radius:const Radius.circular(13),clockwise:!top)
      ..lineTo(cx+22,y)..close();
    canvas.drawPath(p,Paint()..color=gold);
    canvas.drawPath(p,Paint()..color=dark..style=PaintingStyle.stroke..strokeWidth=1.0);
    canvas.drawCircle(Offset(cx,y+sy*8),4.5,Paint()..color=dark.withOpacity(0.55));
    canvas.drawCircle(Offset(cx,y+sy*8),2.2,Paint()..color=gold);
  }

  void _side(Canvas canvas, double x, double cy, bool right) {
    const sz=16.0; final ox=right?x-sz:x+sz;
    final p=Path()..moveTo(x,cy-sz)..lineTo(ox,cy-sz*.38)
      ..lineTo(ox+(right?-sz*.28:sz*.28),cy)..lineTo(ox,cy+sz*.38)
      ..lineTo(x,cy+sz)..lineTo(right?x-sz*.38:x+sz*.38,cy)..close();
    canvas.drawPath(p,Paint()..color=gold);
    canvas.drawPath(p,Paint()..color=dark..style=PaintingStyle.stroke..strokeWidth=0.8);
  }

  @override bool shouldRepaint(covariant CustomPainter o) => false;
}
