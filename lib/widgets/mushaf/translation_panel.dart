import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_style.dart';

class TranslationPanel extends StatelessWidget {
  final List<Map<String, dynamic>> verses;
  final String languageName;
  final double height, minHeight, maxHeight;
  final Function(double) onHeightChanged;
  final VoidCallback onClose;

  const TranslationPanel({
    super.key,
    required this.verses,
    required this.languageName,
    required this.height,
    required this.minHeight,
    required this.maxHeight,
    required this.onHeightChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppColors.gold;
    final surface = isDark ? const Color(0xFF121212) : const Color(0xFFFDFBF7);
    final cardSurface = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final borderColor =
        isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05);
    final subtleText =
        isDark
            ? Colors.white.withValues(alpha: 0.62)
            : AppColors.dark.withValues(alpha: 0.62);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.98 : 0.96),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) {
                final newH = height - details.delta.dy;
                onHeightChanged(newH.clamp(minHeight, maxHeight));
              },
              child: Padding(
                padding: EdgeInsets.only(top: 8.h, bottom: 6.h),
                child: Column(
                  children: [
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 9.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: gold.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              languageName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: gold,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.05,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${verses.length} ayat',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: subtleText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: onClose,
                            child: Container(
                              padding: EdgeInsets.all(5.r),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.04),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14.r,
                                color: subtleText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
            ),
            Expanded(
              child:
                  verses.isEmpty
                      ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.r),
                          child: Text(
                            'Terjemahan belum tersedia',
                            style: TextStyle(
                              color: subtleText,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      : ListView.separated(
                        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 16.h),
                        physics: const BouncingScrollPhysics(),
                        itemCount: verses.length,
                        separatorBuilder: (_, _) => SizedBox(height: 10.h),
                        itemBuilder: (context, index) {
                          final v = verses[index];
                          return Container(
                            padding: EdgeInsets.all(13.r),
                            decoration: BoxDecoration(
                              color: cardSurface,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 30.w,
                                  height: 30.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: gold.withValues(alpha: 0.94),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${v['verse']}',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'QS ${v['surah']}:${v['verse']}',
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          color: gold.withValues(alpha: 0.70),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 5.h),
                                      Text(
                                        v['text'],
                                        style: AppTextStyle.quranTranslationStyle(
                                          isDark: isDark,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
