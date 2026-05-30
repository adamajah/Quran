// ─────────────────────────────────────────────────────────────────────────────
// TajwidLegend  –  bottom sheet panduan warna tajwid
// (extracted from home_screen.dart)
// PERUBAHAN: warna Lam Syamsiyah diubah dari Color(0xFF18FFFF) ke Color(0xFFB388FF)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../constants/quran_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_style.dart';

class TajwidLegend extends StatelessWidget {
  const TajwidLegend({super.key});

  // (nama, arab, warna, deskripsi, contoh)
  static const _rules = [
    (
      'Ghunnah',
      'غُنَّة',
      Color(0xFFFF6B00),
      'Dengung hidung selama 2 harakat, terjadi pada nun/mim bertasydid.',
      'إِنَّ، مَّن',
    ),
    (
      'Idgham',
      'إِدْغَام',
      Color(0xFF00CFFF), // biru langit
      'Nun mati atau tanwin lebur ke huruf berikutnya: ي ر م ل و ن.',
      'مِن رَّبِّ',
    ),
    (
      'Ikhfa',
      'إِخْفَاء',
      Color(0xFFE040FB),
      'Nun mati/tanwin dibaca samar (antara jelas dan lebur) di depan 15 huruf.',
      'مِنْ ثَمَرٍ',
    ),
    (
      'Iqlab',
      'إِقْلَاب',
      Color(0xFFFF1744),
      'Nun mati/tanwin berubah menjadi mim samar di depan huruf ب.',
      'مِنْ بَعْدِ',
    ),
    (
      'Qalqalah',
      'قَلْقَلَة',
      Color(0xFFFFD600),
      'Huruf ق ط ب ج د mati dibaca memantul (bergema) ringan.',
      'يَقْطَعُ',
    ),
    (
      'Madd',
      'مَدّ',
      Color(0xFF00E676),
      'Huruf mad ا و ي dibaca panjang 2–6 harakat sesuai jenis mad-nya.',
      'قَالَ، قِيلَ',
    ),
    (
      'Lam Syamsiyah',
      'لَامُ الشَّمْسِيَّة',
      Color(
        0xFFB388FF,
      ), // DIUBAH: ungu/violet (sebelumnya #18FFFF cyan — terlalu mirip idgham)
      'Lam pada alif-lam lebur ke huruf syamsiyah berikutnya (ت ث د ذ…).',
      'الشَّمْس',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder:
          (_, ctrl) => Container(
            decoration: const BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      color: AppColors.dark,
                    ),
                  ),
                ),
                Text(
                  'Tap lama ikon tajwid untuk membuka panduan ini',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.dark.withValues(alpha: 0.4),
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
                      final (name, ar, color, desc, ex) = _rules[i];
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
                                          color: AppColors.dark,
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
                                      color: AppColors.dark.withValues(
                                        alpha: 0.65,
                                      ),
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
                                      style: AppQuranFonts.hafsStyle.copyWith(
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
