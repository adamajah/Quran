import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/quran.dart' show Translation;
import '../constants/app_colors.dart';

const Map<String, Translation> language = {
  'Indonesian': Translation.indonesian,
  'English (Saheeh)': Translation.enSaheeh,
  'English (Clear Quran)': Translation.enClearQuran,
  'Turkish': Translation.trSaheeh,
  'Russian': Translation.ruKuliev,
  'French': Translation.frHamidullah,
  'Persian': Translation.faHusseinDari,
  'Spanish': Translation.spanish,
  'Dutch': Translation.nlSiregar,
  'Bengali': Translation.bengali,
  'Chinese': Translation.chinese,
  'Swedish': Translation.swedish,
};

class TranslationDialog extends StatelessWidget {
  final Function(Translation) onSelect;

  const TranslationDialog({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = AppColors.gold;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 60.h),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222222) : Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.translate_rounded,
                      color: gold,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    'Pilih Bahasa',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.dark,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
            ),

            // List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: language.length,
                itemBuilder: (context, index) {
                  final entry = language.entries.elementAt(index);
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 0,
                      ),
                      leading: Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: gold.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppColors.dark.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 18.r,
                        color: gold.withValues(alpha: 0.3),
                      ),
                      onTap: () {
                        onSelect(entry.value);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),

            // Footer Action
            Padding(
              padding: EdgeInsets.all(16.r),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  backgroundColor:
                      isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.03),
                ),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.bold,
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
