import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class ThemeManager {
  static ThemeData get goldTheme => _goldTheme;
  static ThemeData get darkTheme => _darkTheme;

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.gold,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
      primary: AppColors.gold,
      surface: const Color(0xFF1E1E1E),
    ),
    textTheme: GoogleFonts.amiriTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),
  );

  static final ThemeData _goldTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.gold,
    scaffoldBackgroundColor: const Color(0xFFFDF8E1),
    cardColor: const Color(0xFFFFFDF5),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.light,
      primary: AppColors.gold,
      surface: const Color(0xFFFFFDF5),
    ),
    textTheme: GoogleFonts.amiriTextTheme().apply(
      bodyColor: const Color(0xFF4A3423),
      displayColor: const Color(0xFF4A3423),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFDF8E1),
      foregroundColor: Color(0xFF4A3423),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(backgroundColor: const Color(0xFFFFFDF5)),
  );
}
