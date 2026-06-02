class QuranTextCluster {
  final String text;
  final int start;
  final int end;

  const QuranTextCluster({
    required this.text,
    required this.start,
    required this.end,
  });
}

abstract final class QuranTextClusterUtils {
  static final _attachedMarkPattern = RegExp(
    r'[\u064B-\u065F\u0670\u06D6-\u06ED]',
  );

  static List<QuranTextCluster> split(String text) {
    final clusters = <QuranTextCluster>[];
    int index = 0;

    while (index < text.length) {
      final start = index;
      index++;
      while (index < text.length && _isAttachedMark(text[index])) {
        index++;
      }
      clusters.add(
        QuranTextCluster(
          text: text.substring(start, index),
          start: start,
          end: index,
        ),
      );
    }
    return clusters;
  }

  static bool _isAttachedMark(String char) =>
      _attachedMarkPattern.hasMatch(char);
}
