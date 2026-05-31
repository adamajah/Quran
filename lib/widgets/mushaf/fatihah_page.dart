import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_style.dart';
import '../../constants/quran_fonts.dart';
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
    final theme = Theme.of(context);
    final textColor =
        isDark
            ? Colors.white.withValues(alpha: 0.88)
            : theme.textTheme.bodyLarge?.color ?? AppColors.dark;
    final accent = AppColors.gold.withValues(alpha: isDark ? 0.88 : 0.75);

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
            ).copyWith(fontWeight: FontWeight.w600),
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
            ).copyWith(fontWeight: FontWeight.w600),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayColor =
        isDark
            ? const Color(0xFF1A120B).withValues(alpha: 0.11)
            : const Color(0xFFF8F0DE).withValues(alpha: 0.10);
    final contentPadding = EdgeInsets.fromLTRB(
      24,
      isDark ? 25 : 24,
      24,
      isDark ? 22 : 23,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/fatihah/fatihah_frame.jpeg',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF121212)
                          : const Color(0xFFF8F0DE),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.22),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: overlayColor),
          ),
        ),
        Padding(
          padding: contentPadding,
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
              const SizedBox(height: 7),
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
        margin: const EdgeInsets.symmetric(vertical: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.2),
        decoration: BoxDecoration(
          color:
              active
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : AppColors.hl.withValues(alpha: 0.05))
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
                      21.25 * widget.fontScale,
                      1.92,
                      active,
                      widget.showTajwid,
                      inkColor,
                    ),
                    TextSpan(
                      text: ' ${_ar(v.verse)}',
                      style: AppQuranFonts.hafsStyle.copyWith(
                        fontSize: 13.8 * widget.fontScale,
                        color:
                            active
                                ? (isDark ? Colors.white : AppColors.hl)
                                : AppColors.gold,
                        fontWeight: FontWeight.bold,
                        height: 1.92,
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
                        ? Colors.white.withValues(alpha: 0.09)
                        : AppColors.hl.withValues(alpha: 0.045))
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
                        ? Colors.white.withValues(alpha: 0.09)
                        : AppColors.hl.withValues(alpha: 0.045))
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
