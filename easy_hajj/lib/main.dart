import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_hajj/core/theme/app_theme.dart';
import 'package:easy_hajj/screens/onboarding/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Настройка системной панели
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const EasyHajjApp());
}

class EasyHajjApp extends StatelessWidget {
  const EasyHajjApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyHajj',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
