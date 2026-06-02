import 'package:flutter/material.dart';
import '../models/settings_model.dart';

abstract final class AppQuranFonts {
  static const hafsStyle = TextStyle(
    color: Colors.black,
    fontSize: 23.55,
    fontFamily: 'hafs',
  );

  static const naskhStyle = TextStyle(
    color: Colors.black,
    fontSize: 23.55,
    fontFamily: 'naskh',
  );

  static const lpmqIsepMisbahStyle = TextStyle(
    color: Colors.black,
    fontSize: 23.55,
    fontFamily: 'lpmqIsepMisbah',
  );

  static TextStyle styleFor(MushafFont font) {
    return switch (font) {
      MushafFont.hafs => hafsStyle,
      MushafFont.naskh => naskhStyle,
      MushafFont.lpmqIsepMisbah => lpmqIsepMisbahStyle,
    };
  }

  static double textScaleFor(MushafFont font) {
    return switch (font) {
      MushafFont.hafs => 1.0,
      MushafFont.naskh => 0.94,
      MushafFont.lpmqIsepMisbah => 0.90,
    };
  }

  static double lineHeightFor(MushafFont font, {bool spacious = false}) {
    return switch ((font, spacious)) {
      (MushafFont.hafs, false) => 1.85,
      (MushafFont.naskh, false) => 1.72,
      (MushafFont.lpmqIsepMisbah, false) => 1.68,
      (MushafFont.hafs, true) => 2.20,
      (MushafFont.naskh, true) => 2.00,
      (MushafFont.lpmqIsepMisbah, true) => 1.94,
    };
  }

  static double readingLineHeightScaleFor(MushafFont font) {
    return switch (font) {
      MushafFont.hafs => 1.0,
      MushafFont.naskh => 0.92,
      MushafFont.lpmqIsepMisbah => 0.88,
    };
  }
}
