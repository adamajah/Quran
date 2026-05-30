import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quran_app/constants/app_text_style.dart';
import 'package:flutter_quran_app/screens/home_screen.dart';
import 'package:flutter_quran_app/services/notification_service.dart';

import '../constants/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// ANIMATION CONTROLLER
  late AnimationController _controller;

  /// ANIMATION
  late Animation<double> _animation;

  /// OFFSET ANIMATION
  late Animation<Offset> _offsetAnimation;

  late final Timer _navigationTimer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    /// INITIALING THE CONTROLLER
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    /// INITIALING THE ANIMATION
    _animation = CurvedAnimation(parent: _controller, curve: Curves.decelerate);

    /// INITIALING THE  OFFSET ANIMATION
    _offsetAnimation = _controller
        .drive(CurveTween(curve: Curves.easeInOut))
        .drive(Tween<Offset>(begin: Offset(0.0, 10.0), end: Offset(0.0, 0.0)));

    /// STARTING THE ANIMATION
    _controller.forward();

    /// INITIALIZE NOTIFICATIONS LATER (To avoid SQLITE_BUSY and Context Null issues)
    _initNotifications();

    /// TIMER FOR SPLASH DURATION
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      /// NAVIGATING TO HOME SCREEN
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
    });
  }

  Future<void> _initNotifications() async {
    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint("Delayed Notification init failed: $e");
    }
  }

  @override
  void dispose() {
    _navigationTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Hero(
                  tag: AppStrings.appLogo,
                  child: Image.asset(AppStrings.appLogo),
                ),
              ),
              SlideTransition(
                position: _offsetAnimation,
                child: AppTextStyle.headlineText(context, AppStrings.alQuran),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: AppTextStyle.titleMediumText(
                context,
                AppStrings.developerBranding,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
