import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_quran_app/utils/tajwid_lam_helper.dart';

void main() {
  group('TajwidLamHelper.isLamQamariahAt', () {
    test('detects every supported qamariah letter', () {
      const qamariahLetters = [
        '\u0627',
        '\u0623',
        '\u0625',
        '\u0622',
        '\u0628',
        '\u062C',
        '\u062D',
        '\u062E',
        '\u0639',
        '\u063A',
        '\u0641',
        '\u0642',
        '\u0643',
        '\u0645',
        '\u0648',
        '\u0647',
        '\u064A',
      ];

      for (final letter in qamariahLetters) {
        final text = '\u0627\u0644\u0652$letter\u064E';
        expect(
          TajwidLamHelper.isLamQamariahAt(text, 1),
          isTrue,
          reason: 'Huruf qamariah $letter harus terdeteksi.',
        );
      }
    });

    test('detects alif waslah prefix without depending on sukun', () {
      const text = '\u0671\u0644\u0652\u0642\u064E\u0645\u064E\u0631\u064F';
      const textWithoutSukun =
          '\u0671\u0644\u0642\u064E\u0645\u064E\u0631\u064F';

      expect(TajwidLamHelper.isLamQamariahAt(text, 1), isTrue);
      expect(TajwidLamHelper.isLamQamariahAt(textWithoutSukun, 1), isTrue);
    });

    test('does not detect a sun letter', () {
      const text = '\u0627\u0644\u0634\u0651\u064E\u0645\u0652\u0633\u064F';

      expect(TajwidLamHelper.isLamQamariahAt(text, 1), isFalse);
    });

    test('does not cross a word boundary', () {
      const text = '\u0627\u0644\u0652 \u0642\u064E\u0645\u064E\u0631\u064F';

      expect(TajwidLamHelper.isLamQamariahAt(text, 1), isFalse);
    });
  });
}
