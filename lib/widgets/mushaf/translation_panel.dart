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

    // Use Container (not AnimatedContainer) for maximum drag performance
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            isDark
                ? const Color(0xFF1E1E1E).withValues(alpha: 0.98)
                : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        // Clip contents to prevent visual overflow during fast drags
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        child: Column(
          children: [
            // Handle Penarik - Fixed height area
            GestureDetector(
              onVerticalDragUpdate: (details) {
                final newH = height - details.delta.dy;
                onHeightChanged(newH.clamp(minHeight, maxHeight));
              },
              child: Container(
                width: double.infinity,
                color: Colors.transparent, // Important for drag area
                padding: EdgeInsets.symmetric(vertical: 6.h), // Even tighter
                child: Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white12
                              : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
              ),
            ),

            // Header & Content - Wrapped in a layout that handles small heights
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Only show header if we have at least 40px of vertical space
                  final bool showHeader = constraints.maxHeight > 40.h;

                  return Column(
                    children: [
                      if (showHeader)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 2.h,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: gold.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  languageName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    color: gold,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: onClose,
                                child: Container(
                                  padding: EdgeInsets.all(4.r),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        isDark
                                            ? Colors.white.withValues(
                                              alpha: 0.05,
                                            )
                                            : Colors.black.withValues(
                                              alpha: 0.03,
                                            ),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14.r,
                                    color:
                                        isDark
                                            ? Colors.white24
                                            : Colors.black26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (showHeader) SizedBox(height: 6.h),

                      // Verses List
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                          physics: const BouncingScrollPhysics(),
                          itemCount: verses.length,
                          separatorBuilder:
                              (_, _) => Divider(
                                height: 20.h,
                                color:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.03)
                                        : Colors.black.withValues(alpha: 0.02),
                              ),
                          itemBuilder: (context, index) {
                            final v = verses[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 4.h),
                                  child: Text(
                                    "${v['verse']}",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: gold.withValues(alpha: 0.4),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 18.w),
                                Expanded(
                                  child: Text(
                                    v['text'],
                                    style: AppTextStyle.quranTranslationStyle(
                                      isDark: isDark,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
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
