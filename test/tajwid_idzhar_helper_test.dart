import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_quran_app/utils/tajwid_idzhar_helper.dart';

void main() {
  group('TajwidIdzharHelper.detectIdzharHalqi', () {
    test('detects every supported halqi letter after nun sukun', () {
      const halqiLetters = [
        '\u0621',
        '\u0627',
        '\u0623',
        '\u0625',
        '\u0622',
        '\u0671',
        '\u0647',
        '\u062D',
        '\u062E',
        '\u0639',
        '\u063A',
      ];

      for (final letter in halqiLetters) {
        final text = '\u0645\u0650\u0646\u0652 $letter\u064E';
        expect(
          TajwidIdzharHelper.detectIdzharHalqi(text),
          {text.indexOf(TajwidIdzharHelper.nun)},
          reason: 'Huruf halqi $letter harus terdeteksi.',
        );
      }
    });

    test('detects halqi letter in the same word', () {
      const text =
          '\u0623\u064E\u0646\u0652\u0639\u064E\u0645\u0652\u062A\u064E';

      expect(TajwidIdzharHelper.detectIdzharHalqi(text), {2});
    });

    test('ignores marks and Quran annotations between words', () {
      const text =
          '\u0645\u0650\u0646\u0652 \u06D6 \u0647\u064E\u0627\u062F\u064D';

      expect(TajwidIdzharHelper.detectIdzharHalqi(text), {2});
    });

    test('does not detect nun without sukun', () {
      const text = '\u0646\u064E\u0628\u064E\u0623';

      expect(TajwidIdzharHelper.detectIdzharHalqi(text), isEmpty);
    });

    test('does not detect a non-halqi following letter', () {
      const text =
          '\u0645\u0650\u0646\u0652 \u0628\u064E\u0639\u0652\u062F\u0650';

      expect(TajwidIdzharHelper.detectIdzharHalqi(text), isEmpty);
    });
  });
}
