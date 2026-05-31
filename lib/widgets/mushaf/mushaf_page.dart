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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFF17110D),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.32),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
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
                  color: AppColors.pageBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.62),
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
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
      ),
    );
  }
}
