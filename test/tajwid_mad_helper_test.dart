import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_quran_app/utils/tajwid_mad_helper.dart';

void main() {
  group('TajwidMadHelper.applyMadWajibAndJaizSigns', () {
    test('adds Arabic maddah above for mad wajib muttasil', () {
      expect(TajwidMadHelper.applyMadWajibAndJaizSigns('جَاءَ'), 'جَآءَ');
    });

    test('adds Arabic maddah above for mad jaiz munfasil', () {
      expect(
        TajwidMadHelper.applyMadWajibAndJaizSigns('إِنَّا أَعْطَيْنَاكَ'),
        'إِنَّآ أَعْطَيْنَاكَ',
      );
    });

    test('does not duplicate an existing Arabic maddah above', () {
      expect(
        TajwidMadHelper.applyMadWajibAndJaizSigns(
          'جَآءَ إِنَّآ أَعْطَيْنَاكَ',
        ),
        'جَآءَ إِنَّآ أَعْطَيْنَاكَ',
      );
    });

    test('supports superscript alif without damaging Arabic marks', () {
      expect(
        TajwidMadHelper.applyMadWajibAndJaizSigns('هَٰؤُلَاءِ مُوسَىٰ إِذْ'),
        'هَٰٓؤُلَاءِ مُوسَىٰٓ إِذْ',
      );
    });

    test('supports Quran annotation signs between separate words', () {
      expect(
        TajwidMadHelper.applyMadWajibAndJaizSigns('إِنَّا ۖ أَعْطَيْنَاكَ'),
        'إِنَّآ ۖ أَعْطَيْنَاكَ',
      );
    });

    test('keeps ordinary mad and Arabic harakat unchanged', () {
      expect(
        TajwidMadHelper.applyMadWajibAndJaizSigns('قَالَ قِيلَ قُولُوا'),
        'قَالَ قِيلَ قُولُوا',
      );
    });

    test('never inserts a keyboard tilde', () {
      final text = TajwidMadHelper.applyMadWajibAndJaizSigns(
        'جَاءَ إِنَّا أَعْطَيْنَاكَ',
      );

      expect(text, isNot(contains('~')));
      expect(text, contains(TajwidMadHelper.maddahAbove));
    });
  });
}
