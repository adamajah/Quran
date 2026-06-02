import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_quran_app/constants/quran_fonts.dart';
import 'package:flutter_quran_app/models/settings_model.dart';
import 'package:flutter_quran_app/services/settings_service.dart';
import 'package:flutter_quran_app/widgets/mushaf/verse_number_ornament.dart';

void main() {
  group('AppQuranFonts', () {
    test('resolves every bundled mushaf font', () {
      expect(AppQuranFonts.styleFor(MushafFont.hafs).fontFamily, 'hafs');
      expect(AppQuranFonts.styleFor(MushafFont.naskh).fontFamily, 'naskh');
      expect(
        AppQuranFonts.styleFor(MushafFont.lpmqIsepMisbah).fontFamily,
        'lpmqIsepMisbah',
      );
    });

    test('uses compact metrics for naskh and LPMQ fonts', () {
      expect(
        AppQuranFonts.textScaleFor(MushafFont.naskh),
        lessThan(AppQuranFonts.textScaleFor(MushafFont.hafs)),
      );
      expect(
        AppQuranFonts.textScaleFor(MushafFont.lpmqIsepMisbah),
        lessThan(AppQuranFonts.textScaleFor(MushafFont.naskh)),
      );
      expect(
        AppQuranFonts.lineHeightFor(MushafFont.lpmqIsepMisbah),
        lessThan(AppQuranFonts.lineHeightFor(MushafFont.hafs)),
      );
    });
  });

  group('VerseNumberOrnament', () {
    test('uses the native end-of-ayah ornament with Arabic numerals', () {
      expect(VerseNumberOrnament.textFor(97), '\u06DD\u0669\u0667');
    });

    test('uses a stable custom ornament for naskh only', () {
      expect(VerseNumberOrnament.usesNativeGlyph(MushafFont.hafs), isTrue);
      expect(VerseNumberOrnament.usesNativeGlyph(MushafFont.naskh), isFalse);
      expect(
        VerseNumberOrnament.usesNativeGlyph(MushafFont.lpmqIsepMisbah),
        isTrue,
      );
      expect(VerseNumberOrnament.arabicNumeralsFor(97), '\u0669\u0667');
    });
  });

  group('SettingsService mushaf font', () {
    test('persists the selected bundled font', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(prefs);

      await service.saveSettings(
        const AppSettings(mushafFont: MushafFont.lpmqIsepMisbah),
      );

      expect(service.loadSettings().mushafFont, MushafFont.lpmqIsepMisbah);
      expect(prefs.getString('mushaf_font_v2'), 'lpmqIsepMisbah');
    });

    test(
      'falls back safely from the legacy unsupported font setting',
      () async {
        SharedPreferences.setMockInitialValues({'mushaf_font': 4});
        final prefs = await SharedPreferences.getInstance();

        expect(
          SettingsService(prefs).loadSettings().mushafFont,
          MushafFont.hafs,
        );
      },
    );
  });
}
