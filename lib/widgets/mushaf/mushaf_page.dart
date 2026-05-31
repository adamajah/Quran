import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/verse_ref.dart';
import './page_elements.dart';
import './fatihah_page.dart';
import './normal_page.dart';

class MushafPage extends StatelessWidget {
  final PageData data;
  final int playSurah, playVerse, tappedSurah, tappedVerse;
  final bool isPlayingPage, showTajwid;
  final double fontScale;
  final Set<String> bookmarkedVerses;
  final void Function(int surah, int verse) onTapVerse;
  final void Function(int surah, int verse) onBookmarkVerse;

  const MushafPage({
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

  bool get _isFatihah => data.pageNum == 1 || data.pageNum == 2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: MushafPagePainter(isDark: isDark),
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: OrnamentPainter(isDark: isDark),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1B1B) : AppColors.pageBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: isDark ? 0.22 : 0.28),
                  width: 0.7,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child:
                    _isFatihah
                        ? FatihahPage(
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
                        )
                        : NormalPage(
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
            ),
          ),
        ],
      ),
    );
  }
}
