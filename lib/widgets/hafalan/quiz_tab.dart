// ─────────────────────────────────────────────────────────────────────────────
// QuizTab  —  TAB 2: Quiz Sambung Ayat
// (extracted from hafalan_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as q;
import 'package:quran_library/quran_library.dart';
import '../../constants/app_colors.dart';
import '../../models/hafalan_models.dart';
import 'hafalan_widgets.dart';

class QuizTab extends StatelessWidget {
  final int quizSurah, quizFromVerse, quizToVerse;
  final List<QuizQuestion> questions;
  final int quizIndex, quizScore;
  final bool quizDone;
  final String? selectedAnswer;
  final bool? answerCorrect;
  final ValueChanged<int> onQuizSurahChanged;
  final ValueChanged<int> onFromChanged, onToChanged;
  final VoidCallback onGenerate, onRestart;
  final ValueChanged<String> onAnswer;

  const QuizTab({
    super.key,
    required this.quizSurah, required this.quizFromVerse, required this.quizToVerse,
    required this.questions, required this.quizIndex, required this.quizScore,
    required this.quizDone, required this.selectedAnswer, required this.answerCorrect,
    required this.onQuizSurahChanged, required this.onFromChanged, required this.onToChanged,
    required this.onGenerate, required this.onRestart, required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return _buildSetup(context);
    if (quizDone) return _buildResult(context);
    return _buildQuestion(context);
  }

  Widget _buildSetup(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      SectionHeader(icon: Icons.quiz_rounded, title: 'Quiz Sambung Ayat'),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(16), decoration: cardDeco(), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pilih Surah', style: TextStyle(fontSize: 12, color: AppColors.dark.withOpacity(0.6))),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: quizSurah,
            decoration: inputDecoStatic(),
            style: TextStyle(fontSize: 13, color: AppColors.dark),
            items: List.generate(q.totalSurahCount, (i) => i + 1).map((s) =>
              DropdownMenuItem(value: s, child: Text('$s. ${q.getSurahName(s)}'))).toList(),
            onChanged: (v) { if (v != null) onQuizSurahChanged(v); },
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: RangeField(
              label: 'Dari Ayat',
              value: quizFromVerse,
              min: 1,
              max: q.getVerseCount(quizSurah) - 1,
              onChange: onFromChanged,
            )),
            const SizedBox(width: 12),
            Expanded(child: RangeField(
              label: 'Sampai Ayat',
              value: quizToVerse,
              min: 2,
              max: q.getVerseCount(quizSurah),
              onChange: onToChanged,
            )),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Mulai Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark, foregroundColor: AppColors.gold,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          )),
        ],
      )),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.info_outline_rounded, size: 14, color: AppColors.gold),
            const SizedBox(width: 6),
            Text('Cara Bermain', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark)),
          ]),
          const SizedBox(height: 8),
          ...[
            'Sistem menampilkan satu ayat dari rentang yang dipilih.',
            'Pilih ayat yang menjadi sambungan (lanjutan) yang benar.',
            'Pilihan ganda tersedia dari 4 opsi yang diacak.',
            'Skor ditampilkan di akhir quiz.',
          ].map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.circle, size: 5, color: AppColors.gold, ),
              const SizedBox(width: 7),
              Expanded(child: Text(t, style: TextStyle(fontSize: 12, color: AppColors.dark.withOpacity(0.7), height: 1.4))),
            ]),
          )),
        ]),
      ),
    ],
  );

  Widget _buildQuestion(BuildContext context) {
    final q_ = questions[quizIndex];
    return Column(children: [
      // Progress
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.pageBg,
        child: Row(children: [
          Text('${quizIndex + 1}/${questions.length}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
          const SizedBox(width: 10),
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (quizIndex + 1) / questions.length,
              minHeight: 7,
              backgroundColor: AppColors.clrBelum.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          )),
          const SizedBox(width: 10),
          Text('Skor: $quizScore', style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.dark.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              Text('Sambungkan ayat berikut:',
                style: TextStyle(fontSize: 12, color: AppColors.dark.withOpacity(0.55))),
              const SizedBox(height: 12),
              Text(q_.promptText,
                style: QuranLibrary().hafsStyle.copyWith(fontSize: 22, height: 1.85, color: AppColors.dark),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              Text('Ayat ${q_.promptVerse} — ${q.getSurahName(q_.surah)}',
                style: TextStyle(fontSize: 10, color: AppColors.dark.withOpacity(0.4))),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Pilih ayat sambungan yang benar:',
            style: TextStyle(fontSize: 12, color: AppColors.dark.withOpacity(0.6))),
          const SizedBox(height: 10),
          ...q_.options.map((opt) {
            final isSelected = selectedAnswer == opt;
            final isCorrect  = opt == q_.correctAnswer;
            Color? bgColor;
            Color? borderColor;
            if (selectedAnswer != null) {
              if (isCorrect) { bgColor = AppColors.clrHafal.withOpacity(0.12); borderColor = AppColors.clrHafal; }
              else if (isSelected) { bgColor = Colors.red.withOpacity(0.08); borderColor = Colors.red; }
              else { bgColor = Colors.transparent; borderColor = AppColors.gold.withOpacity(0.3); }
            } else {
              bgColor = Colors.transparent;
              borderColor = AppColors.gold.withOpacity(0.4);
            }
            return GestureDetector(
              onTap: () => onAnswer(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: borderColor!, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  if (selectedAnswer != null)
                    Padding(padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        isCorrect ? Icons.check_circle_rounded : isSelected ? Icons.cancel_rounded : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: isCorrect ? AppColors.clrHafal : isSelected ? Colors.red : AppColors.dark.withOpacity(0.3),
                      )),
                  Expanded(child: Text(opt,
                    style: QuranLibrary().hafsStyle.copyWith(fontSize: 18, height: 1.7, color: AppColors.dark),
                    textDirection: TextDirection.rtl,
                  )),
                ]),
              ),
            );
          }),
        ]),
      )),
    ]);
  }

  Widget _buildResult(BuildContext context) {
    final pct = questions.isNotEmpty ? quizScore / questions.length : 0.0;
    final grade = pct >= 0.9 ? 'Sempurna! 🏆' : pct >= 0.7 ? 'Hebat! 🌟' : pct >= 0.5 ? 'Terus Berlatih 💪' : 'Perlu Latihan Lagi 📖';
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgress(value: pct, size: 120, color: pct >= 0.7 ? AppColors.clrHafal : AppColors.clrMurojaah),
        const SizedBox(height: 16),
        Text(grade, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
        const SizedBox(height: 8),
        Text('$quizScore dari ${questions.length} jawaban benar',
          style: TextStyle(fontSize: 14, color: AppColors.dark.withOpacity(0.6))),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Ulangi Quiz'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: BorderSide(color: AppColors.gold),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Pengaturan Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark, foregroundColor: AppColors.gold,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          )),
        ]),
      ]),
    ));
  }
}
