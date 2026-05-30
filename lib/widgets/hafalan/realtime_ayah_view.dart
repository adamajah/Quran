import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_style.dart';
import '../../models/hafalan_models.dart';

class RealtimeAyahView extends StatelessWidget {
  final List<InteractiveWord> words;
  final HideMode hideMode;
  final bool isRecording;
  final int currentIndex;
  final GlobalKey currentWordKey;

  const RealtimeAyahView({
    super.key,
    required this.words,
    required this.hideMode,
    required this.isRecording,
    required this.currentIndex,
    required this.currentWordKey,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          direction: Axis.horizontal,
          textDirection: TextDirection.rtl,
          spacing: 2,
          runSpacing: 10,
          children: List.generate(words.length, (idx) {
            final w = words[idx];
            final isCurrent = idx == currentIndex;

            // Determine word color based on status
            Color wColor;
            List<Shadow>? wShadows;
            Color? wBg;

            switch (w.status) {
              case WordStatus.correct:
                wColor = Colors.green;
                break;
              case WordStatus.almost:
                wColor = Colors.orange;
                break;
              case WordStatus.wrong:
                wColor = Colors.red;
                break;
              case WordStatus.pending:
                wColor = textColor;
                break;
            }

            // Glow effect for the currently active word
            if (isCurrent && isRecording) {
              wColor = AppColors.gold;
              wBg = AppColors.gold.withValues(alpha: 0.1);
              wShadows = [
                Shadow(
                  color: AppColors.gold.withValues(alpha: 0.6),
                  blurRadius: 15,
                ),
                Shadow(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  blurRadius: 30,
                ),
              ];
            }

            // Hide logic
            bool shouldHide =
                hideMode == HideMode.allText &&
                w.status == WordStatus.pending &&
                !isCurrent;

            return AnimatedContainer(
              key: isCurrent ? currentWordKey : null,
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: wBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                w.text,
                textAlign: TextAlign.center,
                style: AppTextStyle.quranVerseStyle(
                  fontSize: w.isVerseMarker ? 20 : 26,
                  color: shouldHide ? Colors.transparent : wColor,
                  shadows: wShadows,
                ).copyWith(
                  height: 1.8,
                  // Add a subtle underline for the next expected word
                  decoration:
                      isCurrent && !w.isVerseMarker
                          ? TextDecoration.underline
                          : null,
                  decorationColor: AppColors.gold.withValues(alpha: 0.5),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
