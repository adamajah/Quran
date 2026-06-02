import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_quran_app/constants/quran_fonts.dart';
import 'package:flutter_quran_app/models/settings_model.dart';
import 'package:flutter_quran_app/services/settings_service.dart';

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
