import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_style.dart';
import '../models/reciter.dart';

class ReciterDialog extends StatelessWidget {
  final Reciter currentReciter;
  final Function(Reciter) onSelect;

  const ReciterDialog({
    super.key,
    required this.currentReciter,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppColors.pageBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih Qari (Syekh)',
              style: AppTextStyle.quranSurahNameStyle(
                fontSize: 18,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.gold.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableReciters.length,
                itemBuilder: (context, index) {
                  final reciter = availableReciters[index];
                  final isSelected = reciter.id == currentReciter.id;

                  return ListTile(
                    title: Text(
                      reciter.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? AppColors.gold : textColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing:
                        isSelected
                            ? const Icon(
                              Icons.check_circle,
                              color: AppColors.gold,
                              size: 18,
                            )
                            : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Colors.grey,
                            ),
                    onTap: () {
                      onSelect(reciter);
                      Navigator.pop(context);
                    },
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
