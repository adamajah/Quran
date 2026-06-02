import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as q;

import 'package:flutter_quran_app/constants/app_colors.dart';
import 'package:flutter_quran_app/utils/quran_utils.dart';
import 'package:flutter_quran_app/utils/tajwid_mad_helper.dart';
import 'package:flutter_quran_app/utils/tajwid_utils.dart';

void main() {
  group('TajwidUtils', () {
    test('does not classify dagger alif as wajib or jaiz', () {
      final verse = q.getVerse(1, 1, verseEndSymbol: false);
      final index = verse.indexOf('ٰ');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(verse, index).$2, isEmpty);
    });

    test('does not classify alif madda as wajib or jaiz without context', () {
      const text = 'آمَنُوا';

      expect(TajwidUtils.getTajwidInfo(text, 0).$2, isEmpty);
    });

    test('does not classify natural madd as wajib or jaiz', () {
      const text = 'قَالَ';
      final index = text.indexOf('ا');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, isEmpty);
    });

    test('does not classify small waw sign as wajib or jaiz', () {
      const text = 'هُۥ';
      final index = text.indexOf('ۥ');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, isEmpty);
    });

    test('detects mad wajib muttasil from Arabic maddah above', () {
      final text = TajwidMadHelper.applyMadWajibAndJaizSigns('جَاءَ');
      final index = text.indexOf(TajwidMadHelper.maddahAbove);

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, 'Mad Wajib Muttasil');
    });

    test('detects mad jaiz munfasil from Arabic maddah above', () {
      final text = TajwidMadHelper.applyMadWajibAndJaizSigns(
        'إِنَّا أَعْطَيْنَاكَ',
      );
      final index = text.indexOf(TajwidMadHelper.maddahAbove);

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, 'Mad Jaiz Munfasil');
    });

    test('does not keep the old yellow madd color', () {
      expect(AppColors.tajwidColors, isNot(contains('madd')));
      expect(
        AppColors.tajwidColors['madWajibMuttasil'],
        isNot(const Color(0xFFFBC02D)),
      );
      expect(
        AppColors.tajwidColors['madJaizMunfasil'],
        isNot(const Color(0xFFFBC02D)),
      );
    });

    test('keeps every tajwid rule color visually distinct', () {
      final ruleColors =
          AppColors.tajwidColors.entries
              .where((entry) => entry.key != 'default')
              .toList();

      int rgbDistanceSquared(Color left, Color right) {
        final leftArgb = left.toARGB32();
        final rightArgb = right.toARGB32();
        final redDistance =
            ((leftArgb >> 16) & 0xFF) - ((rightArgb >> 16) & 0xFF);
        final greenDistance =
            ((leftArgb >> 8) & 0xFF) - ((rightArgb >> 8) & 0xFF);
        final blueDistance = (leftArgb & 0xFF) - (rightArgb & 0xFF);
        return redDistance * redDistance +
            greenDistance * greenDistance +
            blueDistance * blueDistance;
      }

      for (int i = 0; i < ruleColors.length; i++) {
        for (int j = i + 1; j < ruleColors.length; j++) {
          expect(
            rgbDistanceSquared(ruleColors[i].value, ruleColors[j].value),
            greaterThanOrEqualTo(80 * 80),
            reason:
                '${ruleColors[i].key} dan ${ruleColors[j].key} terlalu mirip.',
          );
        }
      }
    });

    test('detects madd harfi across every muqattaah opening', () {
      const maddahAbove = '\u0653';
      const openingVerses = <(int, int), String>{
        (2, 1): 'ال\u0653م\u0653',
        (3, 1): 'ال\u0653م\u0653',
        (7, 1): 'ال\u0653م\u0653ص\u0653',
        (10, 1): 'ال\u0653ر',
        (11, 1): 'ال\u0653ر',
        (12, 1): 'ال\u0653ر',
        (13, 1): 'ال\u0653م\u0653ر',
        (14, 1): 'ال\u0653ر',
        (15, 1): 'ال\u0653ر',
        (19, 1): 'ك\u0653هيع\u0653ص\u0653',
        (20, 1): 'طه',
        (26, 1): 'طس\u0653م\u0653',
        (27, 1): 'طس\u0653',
        (28, 1): 'طس\u0653م\u0653',
        (29, 1): 'ال\u0653م\u0653',
        (30, 1): 'ال\u0653م\u0653',
        (31, 1): 'ال\u0653م\u0653',
        (32, 1): 'ال\u0653م\u0653',
        (36, 1): 'يس\u0653',
        (38, 1): 'ص\u0653',
        (40, 1): 'حم\u0653',
        (41, 1): 'حم\u0653',
        (42, 1): 'حم\u0653',
        (42, 2): 'ع\u0653س\u0653ق\u0653',
        (43, 1): 'حم\u0653',
        (44, 1): 'حم\u0653',
        (45, 1): 'حم\u0653',
        (46, 1): 'حم\u0653',
        (50, 1): 'ق\u0653',
        (68, 1): 'ن\u0653',
      };
      const expectedHarakat = <String, String?>{
        'ا': null,
        'ح': '2',
        'ي': '2',
        'ط': '2',
        'ه': '2',
        'ر': '2',
        'ن': '6',
        'ق': '6',
        'ص': '6',
        'س': '6',
        'ل': '6',
        'ك': '6',
        'م': '6',
        'ع': '4 atau 6',
      };

      for (final entry in openingVerses.entries) {
        final text = QuranUtils.getCleanVerse(entry.key.$1, entry.key.$2);
        final opening = entry.value;
        expect(text, startsWith(opening));

        for (int index = 0; index < opening.length; index++) {
          final char = opening[index];
          final harakat = char == maddahAbove ? null : expectedHarakat[char];
          final info = TajwidUtils.getTajwidInfo(text, index);
          final reason = 'QS ${entry.key.$1}:${entry.key.$2}, huruf $char';

          if (char == maddahAbove) {
            expect(info.$2, 'Mad Harfi', reason: reason);
          } else if (harakat == null) {
            expect(info.$2, isEmpty, reason: reason);
          } else {
            expect(info.$2, 'Mad Harfi', reason: reason);
            expect(info.$3, contains('$harakat harakat'), reason: reason);
          }
        }
      }
    });

    test('adds maddah display marks through cleanText', () {
      const bismillah = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';

      expect(QuranUtils.cleanText('$bismillah الم'), 'الٓمٓ');
      expect(QuranUtils.cleanText('يس'), 'يسٓ');
      expect(QuranUtils.prepareForDisplay('جَاءَ'), 'جَآءَ');
      expect(
        QuranUtils.prepareForDisplay('إِنَّا أَعْطَيْنَاكَ'),
        'إِنَّآ أَعْطَيْنَاكَ',
      );
    });

    test('does not detect vowelled ya as madd', () {
      const text = 'قِيَام';
      final index = text.indexOf('ي');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, isEmpty);
    });

    test('does not detect vowelled waw as madd', () {
      const text = 'قُوَّة';
      final index = text.indexOf('و');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, isEmpty);
    });

    test('detects ghunnah on nun with shadda', () {
      const text = 'إِنَّ';
      final index = text.indexOf('ن');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, 'Ghunnah');
    });

    test('detects iqlab on nun before ba', () {
      const text = 'مِنْ بَعْدِ';
      final index = text.indexOf('ن');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, 'Iqlab');
    });

    test('detects idzhar halqi on nun sukun before a throat letter', () {
      const text = 'مِنْ هَادٍ';
      final index = text.indexOf('\u0646');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, 'Idzhar Halqi');
    });

    test('does not detect iqlab on vowelled nun before ba', () {
      const text = 'نَبَأ';
      final index = text.indexOf('ن');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, isEmpty);
    });

    test('detects lam syamsiyah', () {
      const text = 'الشَّمْس';
      final index = text.indexOf('ل');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, 'Lam Syamsiyah');
    });

    test('detects lam qamariah with clear-reading description', () {
      const text = 'الْقَمَرُ';
      final index = text.indexOf('\u0644');
      final info = TajwidUtils.getTajwidInfo(text, index);

      expect(index, isNonNegative);
      expect(info.$2, 'Lam Qamariah');
      expect(info.$3, 'Dibaca jelas');
    });

    test('does not treat tatweel as tafkhim', () {
      final verse = q.getVerse(1, 1, verseEndSymbol: false);
      final index = verse.indexOf('ـ');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(verse, index).$2, isEmpty);
    });
  });
}
