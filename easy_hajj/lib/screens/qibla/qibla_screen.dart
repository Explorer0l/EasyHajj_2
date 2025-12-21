import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/services/location_service.dart';
import 'package:easy_hajj/models/location_data.dart';

/// Упрощенные уровни точности (3 вместо 6)
enum AccuracyLevel {
  accurate,  // ±10° - Точно
  close,     // ±30° - Близко
  far,       // >30° - Далеко
}

/// Qibla Screen - минималистичный экран компаса Киблы
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final LocationService _locationService = LocationService();
  
  LocationData? _currentLocation;
  double? _qiblaDirection;
  bool _isLoading = true;
  String? _errorMessage;
  double? _distanceToKaaba;
  
  // Throttling для compass stream
  DateTime? _lastUpdate;
  StreamSubscription<CompassEvent>? _compassSubscription;
  
  // Координаты Каабы
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _initializeQibla();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  /// Инициализация компаса Киблы
  Future<void> _initializeQibla() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Проверка платформы
      if (kIsWeb) {
        setState(() {
          _errorMessage = 'Компас работает только на мобильных устройствах';
          _isLoading = false;
        });
        return;
      }

      // Получаем местоположение
      LocationData? location;
      try {
        location = await _locationService.getCurrentLocation();
      } catch (e) {
        setState(() {
          _errorMessage = 'Не удалось получить местоположение.\nПроверьте GPS и разрешения.';
          _isLoading = false;
        });
        return;
      }
      
      if (location == null) {
        setState(() {
          _errorMessage = 'Не удалось определить местоположение';
          _isLoading = false;
        });
        return;
      }

      // Рассчитываем направление на Киблу
      final qiblaDir = _locationService.calculateQiblaDirection(
        location.latitude,
        location.longitude,
      );

      // Рассчитываем расстояние до Каабы
      final distance = _locationService.calculateDistance(
        location.latitude,
        location.longitude,
        kaabaLat,
        kaabaLng,
      );

      setState(() {
        _currentLocation = location;
        _qiblaDirection = qiblaDir;
        _distanceToKaaba = distance / 1000;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка инициализации компаса';
        _isLoading = false;
      });
    }
  }

  /// Определить уровень точности (упрощенная версия)
  AccuracyLevel _getAccuracyLevel(double absAngle) {
    if (absAngle <= 10) return AccuracyLevel.accurate;
    if (absAngle <= 30) return AccuracyLevel.close;
    return AccuracyLevel.far;
  }
  
  /// Получить цвет для уровня точности (фирменные цвета)
  Color _getAccuracyColor(AccuracyLevel level) {
    switch (level) {
      case AccuracyLevel.accurate:
        return AppColors.secondary; // Бирюзовый
      case AccuracyLevel.close:
        return AppColors.warning; // Оранжевый
      case AccuracyLevel.far:
        return AppColors.error; // Красный
    }
  }
  
  /// Получить иконку для статуса
  IconData _getAccuracyIcon(AccuracyLevel level) {
    switch (level) {
      case AccuracyLevel.accurate:
        return Icons.check_circle;
      case AccuracyLevel.close:
        return Icons.adjust;
      case AccuracyLevel.far:
        return Icons.explore;
    }
  }

  /// Получить текстовое описание направления
  String _getDirectionText(double angle, AccuracyLevel accuracy) {
    final absAngle = angle.abs();
    
    if (accuracy == AccuracyLevel.accurate) {
      return 'Идеально!';
    } else if (absAngle <= 30) {
      return angle > 0 ? 'Поверните вправо →' : 'Поверните влево ←';
    } else if (absAngle <= 90) {
      return angle > 0 ? 'Повернитесь вправо ⟳' : 'Повернитесь влево ⟲';
    } else {
      return 'Развернитесь ↺';
    }
  }

  /// Минималистичный виджет компаса
  Widget _buildCompassWidget() {
    if (kIsWeb) {
      return _buildErrorWidget();
    }

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events?.transform(
        StreamTransformer.fromHandlers(
          handleData: (event, sink) {
            // Throttling: обновляем только раз в 33мс (30 FPS)
            if (_lastUpdate == null || 
                DateTime.now().difference(_lastUpdate!) > 
                const Duration(milliseconds: 33)) {
              _lastUpdate = DateTime.now();
              sink.add(event);
            }
          },
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.heading == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_off, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Компас недоступен',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final heading = snapshot.data!.heading!;
        
        // Рассчитываем угол для стрелки Киблы
        double qiblaAngle = (_qiblaDirection ?? 0) - heading;
        
        // Нормализуем угол
        while (qiblaAngle > 180) qiblaAngle -= 360;
        while (qiblaAngle < -180) qiblaAngle += 360;
        
        final absAngle = qiblaAngle.abs();
        final accuracy = _getAccuracyLevel(absAngle);
        final color = _getAccuracyColor(accuracy);

        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Статус сверху
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getAccuracyIcon(accuracy), color: color, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _getDirectionText(qiblaAngle, accuracy),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),

                  // Минималистичный компас
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Фоновый круг
                      Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                      
                      // Стрелка Киблы (анимированная)
                      AnimatedRotation(
                        turns: qiblaAngle / 360,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.navigation,
                          size: 120,
                          color: color,
                        ),
                      ),

                      // Центральная точка
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.backgroundWhite,
                            width: 3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Расстояние до Каабы
                  if (_distanceToKaaba != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mosque, size: 24, color: AppColors.secondary),
                          const SizedBox(width: 12),
                          Text(
                            '${_distanceToKaaba!.toStringAsFixed(0)} км до Каабы',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Подсказка внизу
                  Text(
                    'Держите телефон горизонтально',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Виджет загрузки
  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.secondary),
          const SizedBox(height: 24),
          Text(
            'Определение местоположения...',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Виджет ошибки
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? 'Произошла ошибка',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _initializeQibla,
              icon: Icon(Icons.refresh, color: AppColors.textWhite),
              label: Text(
                'Повторить',
                style: TextStyle(fontSize: 16, color: AppColors.textWhite),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Фиксированный фон с градиентом
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF6F6F6),
                  ],
                ),
              ),
            ),
          ),
          
          // Силуэт мечети на фоне
          Positioned.fill(
            child: Opacity(
              opacity: 0.02,
              child: Image.asset(
                'assets/images/mosque_silhouette.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
          
          // Контент
          SafeArea(
            child: _isLoading
                ? _buildLoadingWidget()
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _buildCompassWidget(),
          ),
        ],
      ),
    );
  }
}
