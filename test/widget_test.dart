import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_quran_app/main.dart';
import 'package:flutter_quran_app/controllers/settings_controller.dart';
import 'package:flutter_quran_app/screens/splash_screen.dart';
import 'package:flutter_quran_app/services/settings_service.dart';

void main() {
  testWidgets('app starts on the splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsController(SettingsService(prefs)),
        child: const MyApp(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  });
}
