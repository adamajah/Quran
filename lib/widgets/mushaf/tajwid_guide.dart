import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_style.dart';

class TajwidLegend extends StatelessWidget {
  const TajwidLegend({super.key});

  // (nama, arab, warna, deskripsi, contoh)
  static const _rules = [
    (
      'Ghunnah',
      'غُنَّة',
      Color(0xFF2E7D32),
      'Dengung hidung selama 2 harakat, terjadi pada nun/mim bertasydid.',
      'إِنَّ، مَّن',
    ),
    (
      'Idgham',
      'إِدْغَام',
      Color(0xFF1976D2),
      'Nun mati atau tanwin lebur ke huruf berikutnya: ي ر م ل و ن.',
      'مِن رَّبِّ',
    ),
    (
      'Ikhfa',
      'إِخْفَاء',
      Color(0xFFE65100),
      'Nun mati/tanwin dibaca samar (antara jelas dan lebur) di depan 15 huruf.',
      'مَنْ ثَمَرٍ',
    ),
    (
      'Iqlab',
      'إِقْلَاب',
      Color(0xFF7B1FA2),
      'Nun mati/tanwin berubah menjadi mim samar di depan huruf ب.',
      'مِنْ بَعْدِ',
    ),
    (
      'Qalqalah',
      'قَلْقَلَة',
      Color(0xFFC62828),
      'Huruf ق ط ب ج د mati dibaca memantul (bergema) ringan.',
      'يَقْطَعُ',
    ),
    (
      'Madd',
      'مَدّ',
      Color(0xFFFBC02D),
      'Huruf mad ا و ي dibaca panjang 2–6 harakat sesuai jenis mad-nya.',
      'قَالَ، قِيلَ',
    ),
    (
      'Tafkhim',
      'تَفْخِيم',
      Color(0xFF8D6E63),
      'Penebalan bunyi pada huruf tertentu, terutama lafadz Allah.',
      'اللَّهُ',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder:
          (_, ctrl) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : AppColors.pageBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Judul
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    'Panduan Tajwid',
                    style: AppTextStyle.quranSurahNameStyle(
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                ),
                Text(
                  'Tap lama ikon tajwid untuk membuka panduan ini',
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 1,
                  color: AppColors.gold.withValues(alpha: 0.2),
                ),
                // Daftar hukum
                Expanded(
                  child: ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _rules.length,
                    separatorBuilder:
                        (_, _) => Divider(
                          height: 1,
                          color: AppColors.gold.withValues(alpha: 0.15),
                        ),
                    itemBuilder: (_, i) {
                      final rule = _rules[i];
                      final name = rule.$1;
                      final ar = rule.$2;
                      final color = rule.$3;
                      final desc = rule.$4;
                      final ex = rule.$5;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dot warna
                            Container(
                              width: 13,
                              height: 13,
                              margin: const EdgeInsets.only(top: 3),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Konten
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nama + arab
                                  Row(
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        ar,
                                        style: AppTextStyle.quranSurahNameStyle(
                                          fontSize: 15,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Deskripsi
                                  Text(
                                    desc,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor.withValues(alpha: 0.65),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Contoh bacaan
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: color.withValues(alpha: 0.45),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      ex,
                                      style: QuranLibrary().hafsStyle.copyWith(
                                        fontSize: 16,
                                        color: color,
                                      ),
                                      textDirection: TextDirection.rtl,
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
