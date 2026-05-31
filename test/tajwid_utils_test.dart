import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as q;

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

    test('detects lam syamsiyah', () {
      const text = 'الشَّمْس';
      final index = text.indexOf('ل');

      expect(index, isNonNegative);
      expect(TajwidUtils.getTajwidInfo(text, index).$2, 'Lam Syamsiyah');
    });
  });
}
