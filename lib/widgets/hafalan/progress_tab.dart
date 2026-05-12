// ─────────────────────────────────────────────────────────────────────────────
// ProgressTab  —  TAB 1: Progress Hafalan
// (extracted from hafalan_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as q;
import '../../constants/app_colors.dart';
import '../../models/hafalan_models.dart';
import 'hafalan_widgets.dart';

class ProgressTab extends StatefulWidget {
  final int surah, totalHafal, totalVerses;
  final VerseState Function(int, int) getState;
  final int Function(int, HafalanStatus) versesByStatus;
  final double Function(int) surahProgress;

  const ProgressTab({
    super.key,
    required this.surah, required this.getState,
    required this.versesByStatus, required this.surahProgress,
    required this.totalHafal, required this.totalVerses,
  });

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  bool _showAllSurahs = false;

  @override
  Widget build(BuildContext context) {
    final globalPct = widget.totalVerses > 0
        ? widget.totalHafal / widget.totalVerses
        : 0.0;

    return ListView(padding: const EdgeInsets.all(14), children: [
      // ── Global progress
      SectionHeader(icon: Icons.auto_graph_rounded, title: 'Progres Keseluruhan'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDeco(),
        child: Column(children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${widget.totalHafal} / ${widget.totalVerses} Ayat',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
              Text('sudah dihafal', style: TextStyle(fontSize: 12, color: AppColors.dark.withOpacity(0.5))),
            ])),
            CircularProgress(value: globalPct, size: 72, color: AppColors.clrHafal),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: globalPct,
              minHeight: 8,
              backgroundColor: AppColors.clrBelum.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.clrHafal),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 20),

      // ── Juz progress (simplified: 30 juz)
      SectionHeader(icon: Icons.grid_view_rounded, title: 'Progres per Juz'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDeco(),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1,
          ),
          itemCount: 30,
          itemBuilder: (_, juz) {
            // find all surahs in this juz
            double hafalCount = 0, totalCount = 0;
            for (int s = 1; s <= q.totalSurahCount; s++) {
              final cnt = q.getVerseCount(s);
              for (int v = 1; v <= cnt; v++) {
                if (q.getJuzNumber(s, v) == juz + 1) {
                  totalCount++;
                  if (widget.getState(s, v).status == HafalanStatus.hafal) hafalCount++;
                }
              }
            }
            final pct = totalCount > 0 ? hafalCount / totalCount : 0.0;
            final color = pct >= 1.0 ? AppColors.clrHafal : pct > 0 ? AppColors.clrMurojaah : AppColors.clrBelum;
            return Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                border: Border.all(color: color.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${juz + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.dark)),
                Text('${(pct * 100).round()}%',
                  style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 20),

      // ── Per-surah progress
      SectionHeader(icon: Icons.format_list_bulleted_rounded, title: 'Progres per Surah'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDeco(),
        child: Column(children: [
          ..._surahsWithProgress().take(_showAllSurahs ? 999 : 10).map((entry) {
            final s = entry.key; final pct = entry.value;
            final hf = widget.versesByStatus(s, HafalanStatus.hafal);
            final mr = widget.versesByStatus(s, HafalanStatus.murojaah);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                SizedBox(width: 20, child: Text('$s',
                  style: TextStyle(fontSize: 10, color: AppColors.dark.withOpacity(0.5)))),
                const SizedBox(width: 6),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(q.getSurahName(s),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark))),
                    Text('$hf/${q.getVerseCount(s)}',
                      style: TextStyle(fontSize: 10, color: AppColors.dark.withOpacity(0.5))),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Stack(children: [
                      LinearProgressIndicator(
                        value: mr / q.getVerseCount(s),
                        minHeight: 6,
                        backgroundColor: AppColors.clrBelum.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation(AppColors.clrMurojaah),
                      ),
                      LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation(AppColors.clrHafal),
                      ),
                    ]),
                  ),
                ])),
              ]),
            );
          }),
          if (!_showAllSurahs) GestureDetector(
            onTap: () => setState(() => _showAllSurahs = true),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Tampilkan semua surah',
                  style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Icon(Icons.expand_more_rounded, size: 16, color: AppColors.gold),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }

  List<MapEntry<int, double>> _surahsWithProgress() {
    final entries = <MapEntry<int, double>>[];
    for (int s = 1; s <= q.totalSurahCount; s++) {
      final pct = widget.surahProgress(s);
      if (pct > 0) entries.add(MapEntry(s, pct));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}
