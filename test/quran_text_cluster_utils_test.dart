import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_quran_app/utils/quran_text_cluster_utils.dart';

void main() {
  group('QuranTextClusterUtils.split', () {
    test('keeps Arabic harakat attached to their base letter', () {
      final clusters = QuranTextClusterUtils.split('\u0646\u0652\u0639\u064E');

      expect(clusters.map((cluster) => cluster.text), [
        '\u0646\u0652',
        '\u0639\u064E',
      ]);
    });

    test('keeps Quran waqf signs attached for font shaping', () {
      final clusters = QuranTextClusterUtils.split('\u0645\u06D6 \u0647\u064E');

      expect(clusters.map((cluster) => cluster.text), [
        '\u0645\u06D6',
        ' ',
        '\u0647\u064E',
      ]);
    });
  });
}
