// ─────────────────────────────────────────────────────────────────────────────
// StatistikTab  —  TAB 3: Statistik Hafalan
// (extracted from hafalan_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/hafalan_models.dart';
import 'hafalan_widgets.dart';

class StatistikTab extends StatelessWidget {
  final DailyStats stats;
  final int totalHafal, totalVerses;
  const StatistikTab({
    super.key,
    required this.stats, required this.totalHafal, required this.totalVerses,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      SectionHeader(icon: Icons.insights_rounded, title: 'Statistik Hafalan'),
      const SizedBox(height: 12),

      // ── Key stats
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: [
          StatCard(icon: Icons.check_circle_outline_rounded, label: 'Total Hafal',
            value: '$totalHafal', sub: 'dari $totalVerses ayat', color: AppColors.clrHafal),
          StatCard(icon: Icons.local_fire_department_rounded, label: 'Streak Harian',
            value: '${stats.streak}', sub: 'hari berturut-turut', color: const Color(0xFFE65100)),
          StatCard(icon: Icons.calendar_today_rounded, label: 'Sesi Hafalan',
            value: '${stats.totalSessions}', sub: 'total sesi', color: AppColors.hl),
          StatCard(icon: Icons.today_rounded, label: 'Hari Ini',
            value: '${stats.todayVerses}', sub: 'ayat baru hafal', color: AppColors.goldLt),
        ],
      ),
      const SizedBox(height: 20),

      // ── Progress bar overall
      SectionHeader(icon: Icons.percent_rounded, title: 'Pencapaian Global'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDeco(),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Progres Al-Quran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
            Text('${totalVerses > 0 ? (totalHafal / totalVerses * 100).toStringAsFixed(1) : 0}%',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.clrHafal)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totalVerses > 0 ? totalHafal / totalVerses : 0,
              minHeight: 12,
              backgroundColor: AppColors.clrBelum.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation(AppColors.clrHafal),
            )),
          const SizedBox(height: 6),
          Text('$totalHafal dari $totalVerses ayat Al-Quran telah dihafal',
            style: TextStyle(fontSize: 11, color: AppColors.dark.withOpacity(0.5))),
        ]),
      ),
      const SizedBox(height: 20),

      // ── Tips
      SectionHeader(icon: Icons.lightbulb_outline_rounded, title: 'Tips Hafalan'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDeco(),
        child: Column(children: [
          ..._tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12), shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withOpacity(0.5))),
                child: Center(child: Icon(tip.$1, size: 14, color: AppColors.gold)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tip.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark)),
                Text(tip.$3, style: TextStyle(fontSize: 11, color: AppColors.dark.withOpacity(0.6), height: 1.4)),
              ])),
            ]),
          )),
        ]),
      ),
    ]);
  }

  static const _tips = [
    (Icons.repeat_rounded, 'Metode Pengulangan', 'Ulangi setiap ayat minimal 7-10 kali sebelum lanjut ke ayat berikutnya.'),
    (Icons.volume_up_rounded, 'Dengarkan & Ikuti', 'Dengarkan murattal berulang kali sebelum mulai menghafal.'),
    (Icons.schedule_rounded, 'Konsistensi Waktu', 'Hafalkan pada waktu yang sama setiap hari, idealnya setelah Subuh.'),
    (Icons.refresh_rounded, 'Murojaah Rutin', 'Ulang hafalan lama setiap hari sebelum menambah hafalan baru.'),
    (Icons.group_rounded, 'Setoran dengan Ustadz', 'Setor bacaan kepada guru untuk koreksi tajwid dan makhraj.'),
  ];
}
