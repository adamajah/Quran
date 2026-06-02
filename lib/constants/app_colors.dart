import 'package:flutter/material.dart';

class AppColors {
  // ── Theme Colors (Original Brown/Gold Theme from backup)
  static const Color gold = Color(0xFFA07848);
  static const Color goldLt = Color(0xFFCCA96E);
  static const Color dark = Color(0xFF2C1A0E);
  static const Color pageBg = Color(0xFFFAF6EE);
  static const Color frameBg = Color(0xFFE8DCC8);
  static const Color outerBg = Color(0xFFD9CCAF);
  static const Color ink = Color(0xFF130900);
  static const Color drawerBg = Color(0xFFBFAF8A);
  static const Color hdrBg = Color(0xFFEDE3CE);
  static const Color hl = Color(0xFF0D5C78);

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
    'ghunnah': Color(0xFF00C853), // Bright Green
    'idgham': Color(0xFF005BFF), // Royal Blue
    'ikhfa': Color(0xFFFF7A00), // Vivid Orange
    'iqlab': Color(0xFFB000B5), // Violet
    'idzharHalqi': Color(0xFF00ACC1), // Cyan
    'qalqalah': Color(0xFFD50000), // Strong Red
    'madWajibMuttasil': Color(0xFFFF5FA2), // Pink
    'madJaizMunfasil': Color(0xFF00796B), // Dark Teal
    'madHarfi': Color(0xFF8D3B1F), // Copper Brown
    'tafkhim': Color(0xFF607D8B), // Slate
    'lamSyamsiyah': Color(0xFFA3A500), // Olive Lime
    'lamQamariah': Color(0xFF3D00C8), // Deep Indigo
    'default': ink,
  };
}
