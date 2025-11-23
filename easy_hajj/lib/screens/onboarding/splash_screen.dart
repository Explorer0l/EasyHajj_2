import 'package:flutter/material.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/screens/onboarding/welcome_screen.dart';

/// Splash Screen - начальный экран с логотипом
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToWelcome();
  }

  // Переход на Welcome экран через 2 секунды
  Future<void> _navigateToWelcome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Логотип EASYHAJJ
            Text(
              'EASYHAJJ',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

