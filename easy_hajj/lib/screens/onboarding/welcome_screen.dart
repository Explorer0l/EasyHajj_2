import 'package:flutter/material.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/screens/onboarding/location_screen.dart';

/// Welcome Screen - экран выбора способа входа
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Кнопка "Пропустить" справа
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const LocationScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Пропустить',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Логотип
              Text(
                'EASYHAJJ',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Заголовок
              Text(
                'Выберете способ входа',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Кнопка Google
              _buildAuthButton(
                label: 'Войти с помощью Google',
                icon: Icons.g_mobiledata_rounded,
                iconColor: Colors.red,
                onPressed: () {
                  // TODO: Implement Google sign in
                },
              ),
              
              const SizedBox(height: 16),
              
              // Кнопка Facebook
              _buildAuthButton(
                label: 'Войти с помощью Facebook',
                icon: Icons.facebook,
                iconColor: Colors.blue,
                onPressed: () {
                  // TODO: Implement Facebook sign in
                },
              ),
              
              const SizedBox(height: 16),
              
              // Кнопка Телефон
              _buildAuthButton(
                label: 'Использовать номер телефона',
                icon: Icons.phone_android,
                iconColor: AppColors.textPrimary,
                onPressed: () {
                  // TODO: Implement phone sign in
                },
              ),
              
              const SizedBox(height: 16),
              
              // Кнопка Почта
              _buildAuthButton(
                label: 'Войти с помощью почты',
                icon: Icons.email_outlined,
                iconColor: AppColors.textPrimary,
                onPressed: () {
                  // TODO: Implement email sign in
                },
              ),
              
              const SizedBox(height: 32),
              
              // Чекбокс согласия
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _isAgreed,
                      onChanged: (value) {
                        setState(() {
                          _isAgreed = value ?? false;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Я согласен с обработкой информации, как указано в Политике конфиденциальности.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  /// Кнопка авторизации
  Widget _buildAuthButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

