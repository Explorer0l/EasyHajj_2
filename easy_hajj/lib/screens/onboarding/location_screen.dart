import 'package:flutter/material.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/screens/onboarding/notification_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Location Screen - экран запроса геолокации
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _locationStatus = 'Мое местоположение';
  bool _isLoading = false;

  /// Запрос разрешения на геолокацию
  Future<void> _enableLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Проверка доступности сервиса геолокации
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorDialog('Службы геолокации отключены');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Запрос разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorDialog('Разрешение на геолокацию отклонено');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorDialog('Разрешение на геолокацию отклонено навсегда');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Получение текущей позиции
      Position position = await Geolocator.getCurrentPosition();
      
      // Сохранение в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);
      await prefs.setBool('location_enabled', true);

      setState(() {
        _locationStatus = 'Местоположение определено';
        _isLoading = false;
      });

      // Переход на следующий экран
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const NotificationScreen(),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Ошибка получения местоположения: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Показать диалог ошибки
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Пропустить геолокацию
  void _skipLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_enabled', false);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Заголовок
              Text(
                'Включить местоположение',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Иллюстрация (заменяем SVG на иконку)
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(140),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Фон с легким градиентом
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Иконка геолокации
                    Icon(
                      Icons.location_on,
                      size: 120,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Статус местоположения
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _locationStatus,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Кнопка "Включить"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enableLocation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textWhite,
                            ),
                          ),
                        )
                      : Text(
                          'Мое местоположение',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Кнопка "Пропустить"
              TextButton(
                onPressed: _isLoading ? null : _skipLocation,
                child: Text(
                  'Пропустить',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

