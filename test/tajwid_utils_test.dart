import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as q;

import 'package:flutter_quran_app/utils/quran_utils.dart';
import 'package:flutter_quran_app/utils/tajwid_utils.dart';

void main() {
  group('TajwidUtils', () {
    test('detects madd on dagger alif in Al-Fatihah', () {
      final verse = q.getVerse(1, 1, verseEndSymbol: false);
      final index = verse.indexOf('ٰ');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(verse, index).$2, 'Mad');
    });

    test('detects madd on alif madda', () {
      const text = 'آمَنُوا';

      expect(TajwidUtils.getTajwidInfo(text, 0).$2, 'Mad');
    });

    test('detects natural madd on alif after fatha', () {
      const text = 'قَالَ';
      final index = text.indexOf('ا');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, 'Mad');
    });

    test('detects madd on small waw sign', () {
      const text = 'هُۥ';
      final index = text.indexOf('ۥ');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, 'Mad');
    });

    test('detects madd harfi across every muqattaah opening', () {
      const openingVerses = <(int, int), String>{
        (2, 1): 'الم',
        (3, 1): 'الم',
        (7, 1): 'المص',
        (10, 1): 'الر',
        (11, 1): 'الر',
        (12, 1): 'الر',
        (13, 1): 'المر',
        (14, 1): 'الر',
        (15, 1): 'الر',
        (19, 1): 'كهيعص',
        (20, 1): 'طه',
        (26, 1): 'طسم',
        (27, 1): 'طس',
        (28, 1): 'طسم',
        (29, 1): 'الم',
        (30, 1): 'الم',
        (31, 1): 'الم',
        (32, 1): 'الم',
        (36, 1): 'يس',
        (38, 1): 'ص',
        (40, 1): 'حم',
        (41, 1): 'حم',
        (42, 1): 'حم',
        (42, 2): 'عسق',
        (43, 1): 'حم',
        (44, 1): 'حم',
        (45, 1): 'حم',
        (46, 1): 'حم',
        (50, 1): 'ق',
        (68, 1): 'ن',
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
          final harakat = expectedHarakat[char];
          final info = TajwidUtils.getTajwidInfo(text, index);
          final reason = 'QS ${entry.key.$1}:${entry.key.$2}, huruf $char';

          if (harakat == null) {
            expect(info.$2, isEmpty, reason: reason);
          } else {
            expect(info.$2, 'Mad Harfi', reason: reason);
            expect(info.$3, contains('$harakat harakat'), reason: reason);
          }
        }
      }
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

    test('does not treat tatweel as tafkhim', () {
      final verse = q.getVerse(1, 1, verseEndSymbol: false);
      final index = verse.indexOf('ـ');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(verse, index).$2, isEmpty);
    });
  });
}
