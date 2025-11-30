import 'package:flutter/material.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/screens/onboarding/notification_screen.dart';
import 'package:easy_hajj/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Location Screen - экран запроса геолокации
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationService _locationService = LocationService();
  String _locationStatus = 'Мое местоположение';
  bool _isLoading = false;

  /// Запрос разрешения на геолокацию с активным запросом
  Future<void> _enableLocation() async {
    setState(() {
      _isLoading = true;
      _locationStatus = 'Получение местоположения...';
    });

    try {
      print('📍 Запуск получения геолокации на onboarding экране');
      
      // Используем улучшенный LocationService с автоматическим запросом разрешений
      final location = await _locationService.getCurrentLocation();
      
      if (location == null) {
        throw Exception('Не удалось получить местоположение');
      }

      print('✅ Местоположение получено: ${location.latitude}, ${location.longitude}');
      
      // Сохранение в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('latitude', location.latitude);
      await prefs.setDouble('longitude', location.longitude);
      await prefs.setBool('location_enabled', true);

      setState(() {
        _locationStatus = '✓ Местоположение определено';
        _isLoading = false;
      });

      // Показываем успешное сообщение
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Местоположение успешно определено!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Переход на следующий экран
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const NotificationScreen(),
          ),
        );
      }
    } catch (e) {
      print('❌ Ошибка получения местоположения: $e');
      
      setState(() {
        _locationStatus = 'Мое местоположение';
        _isLoading = false;
      });
      
      // Определяем тип ошибки и показываем соответствующий диалог
      if (e.toString().contains('GPS отключен')) {
        _showGpsErrorDialog();
      } else if (e.toString().contains('Разрешение на геолокацию не предоставлено')) {
        _showPermissionErrorDialog();
      } else if (e.toString().contains('Превышено время ожидания')) {
        _showTimeoutErrorDialog();
      } else {
        _showErrorDialog('Ошибка получения местоположения', e.toString());
      }
    }
  }

  /// Показать диалог ошибки GPS
  void _showGpsErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.gps_off, color: AppColors.error),
            SizedBox(width: 12),
            Text('GPS отключен'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Для определения местоположения необходимо включить GPS.'),
            SizedBox(height: 16),
            Text(
              'Инструкция:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              '1. Нажмите "Открыть настройки"\n'
              '2. Включите "Местоположение"\n'
              '3. Выберите "Высокая точность"\n'
              '4. Вернитесь и попробуйте снова',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _locationService.openLocationSettings();
              await Future.delayed(Duration(seconds: 2));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Включите GPS и попробуйте снова'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
            icon: Icon(Icons.settings),
            label: Text('Открыть настройки'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Показать диалог ошибки разрешений
  void _showPermissionErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_disabled, color: AppColors.error),
            SizedBox(width: 12),
            Text('Нужно разрешение'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Приложению необходим доступ к вашему местоположению для:'),
            SizedBox(height: 12),
            Text('• Определения времени молитв\n• Направления на Киблу\n• Исламского календаря'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Разрешите доступ к местоположению в настройках приложения',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _locationService.openAppSettings();
              await Future.delayed(Duration(seconds: 2));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Разрешите доступ к местоположению'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
            icon: Icon(Icons.settings),
            label: Text('Настройки приложения'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Показать диалог ошибки таймаута
  void _showTimeoutErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.gps_not_fixed, color: AppColors.warning),
            SizedBox(width: 12),
            Text('Слабый GPS сигнал'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Не удалось получить GPS сигнал.'),
            SizedBox(height: 12),
            Text('Советы:'),
            SizedBox(height: 8),
            Text(
              '• Выйдите на открытое пространство\n'
              '• Убедитесь что GPS включен\n'
              '• Подождите 30-60 секунд\n'
              '• Попробуйте снова',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Понятно'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _enableLocation();
            },
            child: Text('Попробовать снова'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Показать общий диалог ошибки
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
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
              
              // Иллюстрация геолокации
              Image.asset(
                'assets/images/your_location_image.png',
                width: 280,
                height: 280,
                fit: BoxFit.contain,
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
