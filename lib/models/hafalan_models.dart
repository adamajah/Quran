// ─────────────────────────────────────────────────────────────────────────────
// Hafalan Models  (extracted from hafalan_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

enum HafalanStatus { belum, murojaah, hafal }

enum HideMode { none, allText, partialWords }

class VerseState {
  HafalanStatus status;
  bool isBookmarked;
  bool isRevealed; // used in hide mode
  VerseState({
    this.status = HafalanStatus.belum,
    this.isBookmarked = false,
    this.isRevealed = false,
  });
}

class RepeatConfig {
  int count;          // times to repeat
  int delaySeconds;   // pause between repeats
  int fromVerse;
  int toVerse;
  RepeatConfig({
    this.count = 3,
    this.delaySeconds = 2,
    this.fromVerse = 1,
    this.toVerse = 7,
  });
}

class DailyStats {
  int totalSessions;
  int streak;
  int todayVerses;
  DateTime lastStudied;
  DailyStats({
    this.totalSessions = 0,
    this.streak = 0,
    this.todayVerses = 0,
    required this.lastStudied,
  });
}

class QuizQuestion {
  final int surah, promptVerse;
  final String promptText, correctAnswer;
  final List<String> options;
  const QuizQuestion({
    required this.surah, required this.promptVerse,
    required this.promptText, required this.correctAnswer,
    required this.options,
  });
}
