// ─────────────────────────────────────────────────────────────────────────────
// FatihahPage  (extracted from home_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as q;
import 'package:quran_library/quran_library.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_style.dart';
import '../../models/verse_ref.dart';
import '../../utils/tajwid_utils.dart';
import 'page_elements.dart';

class FatihahPage extends StatelessWidget {
  final PageData data;
  final int playVerse, tappedSurah, tappedVerse;
  final bool isPlayingPage, showTajwid;
  final double fontScale;
  final Set<String> bookmarkedVerses;
  final void Function(int, int) onTapVerse, onBookmarkVerse;

  const FatihahPage({
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

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PageHeader(data: data),
      const Rule(thick: true),
      const FatihahSurahBanner(),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: data.verses.map((v) => _buildVerseRow(v)).toList(),
          ),
        ),
      ),
      const Rule(thick: true),
      PageNum(n: data.pageNum),
    ]);
  }

  Widget _buildVerseRow(VerseRef v) {
    final active = isPlayingPage && v.verse == playVerse ||
        tappedSurah == v.surah && tappedVerse == v.verse;
    final key = '${v.surah}:${v.verse}';
    final isBookmarked = bookmarkedVerses.contains(key);
    final text = q.getVerse(v.surah, v.verse, verseEndSymbol: false);

    return GestureDetector(
      onTap: () => onTapVerse(v.surah, v.verse),
      onLongPress: () => onBookmarkVerse(v.surah, v.verse),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppColors.hl.withOpacity(0.06)
              : isBookmarked ? AppColors.gold.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isBookmarked ? Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.8) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isBookmarked)
              Padding(padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.bookmark_rounded, size: 10, color: AppColors.gold)),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  ...buildTajwidSpans(text, 23 * fontScale, 2.2, active, showTajwid),
                  TextSpan(
                    text: ' ${_ar(v.verse)}',
                    style: QuranLibrary().hafsStyle.copyWith(
                      fontSize: 15 * fontScale, color: active ? AppColors.hl : AppColors.gold,
                      fontWeight: FontWeight.bold, height: 2.2,
                    ),
                  ),
                ]),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FatihahSurahBanner
// ─────────────────────────────────────────────────────────────────────────────
class FatihahSurahBanner extends StatelessWidget {
  const FatihahSurahBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 4, 6, 2),
      child: Row(children: [
        const Expanded(child: OrnamentSide(mirror: false)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0E8D8),
            border: Border.all(color: AppColors.gold.withOpacity(0.6), width: 0.8),
          ),
          child: Text('سُورَةُ ٱلْفَاتِحَةِ',
            style: AppTextStyle.quranSurahNameStyle(fontSize: 18, color: AppColors.dark),
            textDirection: TextDirection.rtl),
        ),
        const Expanded(child: OrnamentSide(mirror: true)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OrnamentSide
// ─────────────────────────────────────────────────────────────────────────────
class OrnamentSide extends StatelessWidget {
  final bool mirror;
  const OrnamentSide({super.key, required this.mirror});
  @override
  Widget build(BuildContext context) => Transform.scale(
    scaleX: mirror ? -1 : 1,
    child: CustomPaint(
      painter: OrnamentPainter(gold: AppColors.gold, dark: AppColors.dark),
      child: const SizedBox(height: 36),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// OrnamentPainter
// ─────────────────────────────────────────────────────────────────────────────
class OrnamentPainter extends CustomPainter {
  final Color gold, dark;
  const OrnamentPainter({required this.gold, required this.dark});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final fillPaint = Paint()..color = gold.withOpacity(0.15)..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 0.8;
    const sz = 8.0; const step = 14.0;
    for (double x = sz; x < w - sz/2; x += step) {
      final p = Path()
        ..moveTo(x, h/2 - sz/2)..lineTo(x + sz/2, h/2)
        ..lineTo(x, h/2 + sz/2)..lineTo(x - sz/2, h/2)..close();
      canvas.drawPath(p, fillPaint);
      canvas.drawPath(p, strokePaint);
    }
    canvas.drawLine(Offset(0, h*0.25), Offset(w, h*0.25),
      Paint()..color = gold.withOpacity(0.5)..strokeWidth = 0.6);
    canvas.drawLine(Offset(0, h*0.75), Offset(w, h*0.75),
      Paint()..color = gold.withOpacity(0.5)..strokeWidth = 0.6);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}
