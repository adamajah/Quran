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

  static TextStyle styleFor(MushafFont font) {
    return switch (font) {
      MushafFont.hafs => hafsStyle,
      MushafFont.naskh => naskhStyle,
    };
  }
}
