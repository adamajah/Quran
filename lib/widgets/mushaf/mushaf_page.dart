import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/settings_model.dart';
import '../../models/verse_ref.dart';
import './fatihah_page.dart';
import './normal_page.dart';
import './page_elements.dart';

class MushafPage extends StatelessWidget {
  final PageData data;
  final int playSurah, playVerse, tappedSurah, tappedVerse;
  final bool isPlayingPage, showTajwid;
  final double fontScale;
  final MushafFont mushafFont;
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
    required this.mushafFont,
    required this.showTajwid,
    required this.bookmarkedVerses,
    required this.onTapVerse,
    required this.onBookmarkVerse,
  });

  bool get _isFatihah => data.pageNum == 1 || data.pageNum == 2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: FramePainter(isDark: isDark)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : AppColors.pageBg,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: isDark ? 0.3 : 0.4),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
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
                      mushafFont: mushafFont,
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
                      mushafFont: mushafFont,
                      showTajwid: showTajwid,
                      bookmarkedVerses: bookmarkedVerses,
                      onTapVerse: onTapVerse,
                      onBookmarkVerse: onBookmarkVerse,
                    ),
          ),
        ),
      ],
    );
  }
}
