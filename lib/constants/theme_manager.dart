import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/settings_model.dart';
import 'app_colors.dart';

class ThemeManager {
  static ThemeData getTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.dark:
        return _darkTheme;
      case AppTheme.gold:
        return _goldTheme;
      case AppTheme.sepia:
        return _sepiaTheme;
      case AppTheme.light:
        return _lightTheme;
    }
  }

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.gold,
    scaffoldBackgroundColor: AppColors.pageBg,
    cardColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.light,
      primary: AppColors.gold,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.amiriTextTheme().apply(
      bodyColor: AppColors.dark,
      displayColor: AppColors.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.pageBg,
      foregroundColor: AppColors.dark,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(backgroundColor: Colors.white),
  );

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

  static final ThemeData _sepiaTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF704214),
    scaffoldBackgroundColor: const Color(0xFFF1E7D0),
    cardColor: const Color(0xFFF8F1E1),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF704214),
      brightness: Brightness.light,
      primary: const Color(0xFF704214),
      surface: const Color(0xFFF8F1E1),
    ),
    textTheme: GoogleFonts.amiriTextTheme().apply(
      bodyColor: const Color(0xFF433422),
      displayColor: const Color(0xFF433422),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF1E7D0),
      foregroundColor: Color(0xFF433422),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(backgroundColor: const Color(0xFFF8F1E1)),
  );
}
