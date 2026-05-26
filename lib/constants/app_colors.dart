import 'package:flutter/material.dart';

class AppColors {
  // ── Theme Colors (Original Brown/Gold Theme from backup)
  static const Color gold     = Color(0xFFA07848);
  static const Color goldLt   = Color(0xFFCCA96E);
  static const Color dark     = Color(0xFF2C1A0E);
  static const Color pageBg   = Color(0xFFFAF6EE);
  static const Color frameBg  = Color(0xFFE8DCC8);
  static const Color outerBg  = Color(0xFFD9CCAF);
  static const Color ink      = Color(0xFF130900);
  static const Color drawerBg = Color(0xFFBFAF8A);
  static const Color hdrBg    = Color(0xFFEDE3CE);
  static const Color hl       = Color(0xFF0D5C78);

  // ── App Branding (Legacy/General)
  static const Color primaryColor = Color(0xFF00613C); // Green from logo
  static const Color primaryLightColor = Color(0xFFE8F5E9);
  static const Color backgroundColor = Color(0xFFFAF6EE); // Same as pageBg
  static const Color secondaryColor = Color(0xFFFDBB4F); // Yellow from logo
  static const Color textColor = Color(0xFF2C1A0E); // Same as dark

  // ── Hafalan Colors
  static const Color clrHafal = Color(0xFF2E7D32); // Green
  static const Color clrMurojaah = Color(0xFFF57C00); // Orange
  static const Color clrBelum = Color(0xFFD32F2F); // Red

  // ── Tajwid Colors (Premium Professional Palette)
  static const Map<String, Color> tajwidColors = {
    'ghunnah':    Color(0xFF2E7D32), // Green
    'idgham':     Color(0xFF1976D2), // Blue
    'ikhfa':      Color(0xFFE65100), // Orange
    'iqlab':      Color(0xFF7B1FA2), // Purple
    'qalqalah':   Color(0xFFC62828), // Red
    'madd':       Color(0xFFFBC02D), // Yellow/Amber
    'tafkhim':    Color(0xFF8D6E63), // Brown/Gold
    'default':    ink,
  };
}
