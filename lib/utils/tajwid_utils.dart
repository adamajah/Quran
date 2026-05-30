import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TajwidUtils {
  static (Color, String, String) getTajwidInfo(String char, String? nextChar) {
    // 1. Ghunnah: Nun/Mim Tasydid
    if ((char == 'ن' || char == 'م') && nextChar == 'ّ') {
      return (
        AppColors.tajwidColors['ghunnah']!,
        'Ghunnah',
        'Dengung 2 harakat pada nun/mim bertasydid.',
      );
    }

    // 2. Qalqalah: قطبجد (Sukun or end of word)
    const qalqalah = 'قطبجد';
    if (qalqalah.contains(char)) {
      if (nextChar == 'ْ' ||
          nextChar == null ||
          nextChar == ' ' ||
          nextChar == '\n') {
        return (
          AppColors.tajwidColors['qalqalah']!,
          'Qalqalah',
          'Pantulan suara pada huruf mati.',
        );
      }
    }

    // 3. Iqlab: Nun followed by Ba
    if (char == 'ن' && nextChar == 'ب') {
      return (
        AppColors.tajwidColors['iqlab']!,
        'Iqlab',
        'Nun mati berubah menjadi suara mim samar.',
      );
    }

    // 4. Idgham: Nun followed by يرملون
    const idgham = 'يرملون';
    if (char == 'ن' && nextChar != null && idgham.contains(nextChar)) {
      return (
        AppColors.tajwidColors['idgham']!,
        'Idgham',
        'Melebur nun mati ke huruf berikutnya.',
      );
    }

    // 5. Ikhfa: Nun followed by 15 letters
    const ikhfa = 'تثجدذزسشصضطظفقك';
    if (char == 'ن' && nextChar != null && ikhfa.contains(nextChar)) {
      return (
        AppColors.tajwidColors['ikhfa']!,
        'Ikhfa',
        'Menyamarkan suara nun mati.',
      );
    }

    // 6. Madd: Mad signs or vowel prolongations
    const madSigns = 'ٰٓۦۧ';
    if (madSigns.contains(char) ||
        (char == 'ا' && nextChar == ' ') ||
        'وي'.contains(char) && nextChar == 'ْ') {
      return (
        AppColors.tajwidColors['madd']!,
        'Mad',
        'Pemanjangan suara huruf mad.',
      );
    }

    // 7. Lam Tafkhim: Allah name marks (approximation)
    // Common marks used in Allah name for Tafkhim
    if (char == 'ـ' || (char == 'ّ' && nextChar == 'ٰ')) {
      // This often appears in the name of Allah
      return (
        AppColors.tajwidColors['tafkhim']!,
        'Tafkhim',
        'Penebalan bunyi pada lafadz Allah.',
      );
    }

    return (AppColors.tajwidColors['default']!, '', '');
  }

  static Color getTajwidColor(String char, String? nextChar) {
    return getTajwidInfo(char, nextChar).$1;
  }
}
