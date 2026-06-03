import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'constants/theme_manager.dart';
import 'controllers/settings_controller.dart';
import 'services/settings_service.dart';

import 'services/storage_service.dart';
import 'services/download_service.dart';
import 'services/audio_service.dart';
import 'providers/storage_provider.dart';
import 'providers/download_provider.dart';
import 'providers/audio_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // NotificationService initialization moved to SplashScreen to avoid Activity-not-ready issues

  final prefs = await SharedPreferences.getInstance();
  final settingsService = SettingsService(prefs);
  final storageService = StorageService();
  final downloadService = DownloadService();
  final audioService = AudioService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsController(settingsService),
        ),
        ChangeNotifierProvider(create: (_) => StorageProvider(storageService)),
        ChangeNotifierProvider(
          create:
              (_) => DownloadProvider(downloadService, storageService, prefs),
        ),
        ChangeNotifierProvider(create: (_) => AudioProvider(audioService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, child) {
        return ScreenUtilInit(
          designSize: const Size(392, 800),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeManager.goldTheme,
              darkTheme: ThemeManager.darkTheme,
              themeMode: ThemeMode.system,
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
