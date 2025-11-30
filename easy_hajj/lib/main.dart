import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easy_hajj/core/theme/app_theme.dart';
import 'package:easy_hajj/screens/onboarding/splash_screen.dart';
import 'package:easy_hajj/services/app_data_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация русской локали для форматирования дат
  await initializeDateFormatting('ru', null);
  
  // Настройка системной панели
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Инициализация главного контроллера данных
  final appController = AppDataController();
  await appController.initialize();
  
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
