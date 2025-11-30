import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/services/location_service.dart';
import 'package:easy_hajj/models/location_data.dart';

/// Qibla Screen - экран компаса Киблы
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final LocationService _locationService = LocationService();
  
  LocationData? _currentLocation;
  double? _qiblaDirection;
  double? _currentHeading;
  bool _isLoading = true;
  String? _errorMessage;
  double? _distanceToKaaba;
  
  // Координаты Каабы
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _initializeQibla();
  }

  /// Инициализация компаса Киблы с активным запросом разрешений
  Future<void> _initializeQibla() async {
    try {
      print('🧭 Начало инициализации компаса');
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Проверка платформы
      if (kIsWeb) {
        print('⚠️ Приложение запущено в веб-браузере');
        setState(() {
          _errorMessage = 'Компас Киблы работает только на мобильных устройствах (Android/iOS).\n\nЗапустите приложение на телефоне для использования этой функции.';
          _isLoading = false;
        });
        return;
      }

      print('📍 Запрос местоположения с проверкой разрешений...');
      
      // Получаем текущее местоположение (с автоматическим запросом разрешений)
      LocationData? location;
      try {
        location = await _locationService.getCurrentLocation();
      } catch (e) {
        print('❌ Ошибка получения местоположения: $e');
        
        // Определяем тип ошибки и выводим соответствующее сообщение
        String errorMsg;
        
        if (e.toString().contains('GPS отключен')) {
          errorMsg = 'GPS отключен на устройстве\n\n'
              'Для работы компаса Киблы необходимо включить службу геолокации.\n\n'
              'Нажмите кнопку "Настройки GPS" ниже.';
        } else if (e.toString().contains('Разрешение на геолокацию не предоставлено')) {
          errorMsg = 'Нет доступа к геолокации\n\n'
              'Для работы компаса необходимо разрешение на определение местоположения.\n\n'
              'Нажмите "Настройки приложения" чтобы предоставить доступ.';
        } else if (e.toString().contains('Превышено время ожидания')) {
          errorMsg = 'Не удалось получить GPS сигнал\n\n'
              'Возможные причины:\n'
              '• Вы находитесь в помещении\n'
              '• Плохой GPS сигнал\n\n'
              'Попробуйте выйти на открытое пространство.';
        } else {
          errorMsg = 'Не удалось получить местоположение\n\n'
              '${e.toString()}\n\n'
              'Попробуйте:\n'
              '• Включить GPS\n'
              '• Разрешить доступ к геолокации\n'
              '• Выйти на открытое пространство';
        }
        
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
        return;
      }
      
      if (location == null) {
        print('❌ Местоположение не получено (null)');
        setState(() {
          _errorMessage = 'Не удалось определить местоположение\n\n'
              'Пожалуйста, проверьте:\n'
              '• GPS включен\n'
              '• Разрешение на геолокацию предоставлено\n'
              '• Вы находитесь на открытом пространстве';
          _isLoading = false;
        });
        return;
      }

      print('✅ Местоположение получено: ${location.latitude}, ${location.longitude}');

      // Рассчитываем направление на Киблу
      final qiblaDir = _locationService.calculateQiblaDirection(
        location.latitude,
        location.longitude,
      );

      print('🧭 Направление на Киблу: $qiblaDir°');

      // Рассчитываем расстояние до Каабы
      final distance = _locationService.calculateDistance(
        location.latitude,
        location.longitude,
        kaabaLat,
        kaabaLng,
      );

      print('📏 Расстояние до Каабы: ${(distance / 1000).toStringAsFixed(0)} км');

      setState(() {
        _currentLocation = location;
        _qiblaDirection = qiblaDir;
        _distanceToKaaba = distance / 1000; // Переводим в километры
        _isLoading = false;
      });
      
      print('✅ Инициализация компаса завершена успешно');
    } catch (e, stackTrace) {
      print('❌ Ошибка инициализации компаса: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Непредвиденная ошибка\n\n${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Виджет загрузки
  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.secondary,
          ),
          const SizedBox(height: 24),
          Text(
            'Определение местоположения...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Виджет ошибки
  Widget _buildErrorWidget() {
    // Определяем тип ошибки для показа соответствующих кнопок
    final isGpsError = _errorMessage?.contains('GPS отключен') == true;
    final isPermissionError = _errorMessage?.contains('Нет доступа') == true ||
        _errorMessage?.contains('Разрешение') == true;
    final isSignalError = _errorMessage?.contains('GPS сигнал') == true;
    final isLocationError = isGpsError || isPermissionError || isSignalError;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isGpsError 
                  ? Icons.gps_off 
                  : isPermissionError 
                      ? Icons.location_disabled
                      : isSignalError
                          ? Icons.gps_not_fixed
                          : Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? 'Произошла ошибка',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            // Кнопки действий
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // Кнопка повторить - всегда показываем
                ElevatedButton.icon(
                  onPressed: _initializeQibla,
                  icon: Icon(Icons.refresh, color: AppColors.textWhite),
                  label: Text(
                    'Повторить',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textWhite,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                // Кнопка открыть настройки GPS (для ошибок GPS)
                if (isGpsError)
                  ElevatedButton.icon(
                    onPressed: () async {
                      print('🔧 Открываем настройки GPS...');
                      await _locationService.openLocationSettings();
                      // Даем время пользователю изменить настройки
                      await Future.delayed(const Duration(seconds: 1));
                      // Показываем подсказку
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Включите GPS и нажмите "Повторить"'),
                            duration: Duration(seconds: 3),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.gps_fixed, color: AppColors.textWhite),
                    label: Text(
                      'Настройки GPS',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textWhite,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                
                // Кнопка открыть настройки приложения (для ошибок разрешений)
                if (isPermissionError)
                  ElevatedButton.icon(
                    onPressed: () async {
                      print('🔧 Открываем настройки приложения...');
                      await _locationService.openAppSettings();
                      // Даем время пользователю изменить настройки
                      await Future.delayed(const Duration(seconds: 1));
                      // Показываем подсказку
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Разрешите доступ к местоположению и нажмите "Повторить"'),
                            duration: Duration(seconds: 3),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.settings, color: AppColors.textWhite),
                    label: Text(
                      'Настройки приложения',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textWhite,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Подсказка для пользователя
            if (isLocationError) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isGpsError 
                                ? 'Как включить GPS:'
                                : isPermissionError
                                    ? 'Как разрешить доступ:'
                                    : 'Советы:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isGpsError
                          ? '1. Нажмите "Настройки GPS"\n'
                            '2. Включите "Местоположение"\n'
                            '3. Выберите "Высокая точность"\n'
                            '4. Вернитесь и нажмите "Повторить"'
                          : isPermissionError
                              ? '1. Нажмите "Настройки приложения"\n'
                                '2. Найдите "Разрешения"\n'
                                '3. Разрешите "Местоположение"\n'
                                '4. Вернитесь и нажмите "Повторить"'
                              : '• Выйдите на открытое пространство\n'
                                '• Убедитесь что GPS включен\n'
                                '• Подождите пока найдется сигнал\n'
                                '• Попробуйте снова',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Основной виджет компаса
  Widget _buildCompassWidget() {
    // Проверка на веб-платформу
    if (kIsWeb) {
      return _buildWebWarning();
    }

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        print('🧭 Compass stream state: ${snapshot.connectionState}');
        
        if (snapshot.hasError) {
          print('❌ Compass error: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Компас недоступен на этом устройстве',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ошибка: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ Waiting for compass data...');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Инициализация компаса...',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          print('⚠️ No compass data');
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.secondary,
            ),
          );
        }

        double? heading = snapshot.data!.heading;
        
        if (heading == null) {
          print('⚠️ Heading is null');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore_off,
                    size: 80,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Компас недоступен',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Убедитесь, что датчики устройства включены',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        print('🧭 Current heading: $heading°');

        // Обновляем текущее направление
        _currentHeading = heading;

        // Рассчитываем угол для стрелки Киблы
        // qiblaDirection - это направление от севера до Киблы
        // heading - это текущее направление устройства от севера
        // Поэтому нам нужно вычесть heading из qiblaDirection
        double qiblaAngle = (_qiblaDirection ?? 0) - heading;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Заголовок
              Text(
                'Направление на Киблу',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 16),
              
              // Текущий угол
              Text(
                '${heading.toInt()}°',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 32),

              // Компас
              Stack(
                alignment: Alignment.center,
                children: [
                  // Фоновый круг с тенью
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                  ),
                  
                  // Вращающаяся роза ветров
                  Transform.rotate(
                    angle: (heading * (math.pi / 180) * -1),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Метки сторон света
                          _buildCompassMarker('N', 0, AppColors.error),
                          _buildCompassMarker('E', 90, AppColors.textSecondary),
                          _buildCompassMarker('S', 180, AppColors.textSecondary),
                          _buildCompassMarker('W', 270, AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),

                  // Стрелка Киблы (указывает направление)
                  Transform.rotate(
                    angle: qiblaAngle * (math.pi / 180),
                    child: CustomPaint(
                      size: const Size(120, 120),
                      painter: QiblaArrowPainter(),
                    ),
                  ),

                  // Центральная точка
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundWhite,
                        width: 3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Иконка Каабы
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mosque,
                  size: 40,
                  color: AppColors.secondary,
                ),
              ),

              const SizedBox(height: 16),

              // Информация о расстоянии
              if (_distanceToKaaba != null)
                Column(
                  children: [
                    Text(
                      'Расстояние до Каабы',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_distanceToKaaba!.toStringAsFixed(0)} км',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Подсказка
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Поворачивайте устройство пока стрелка не укажет прямо вверх',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Виджет предупреждения для веб-платформы
  Widget _buildWebWarning() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_android,
              size: 100,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 32),
            Text(
              'Компас Киблы',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Доступен только на мобильных устройствах',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.secondary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Для использования компаса необходим физический магнитометр устройства',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Запустите приложение на Android или iOS устройстве',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Создание метки стороны света на компасе
  Widget _buildCompassMarker(String label, double angle, Color color) {
    return Transform.rotate(
      angle: angle * (math.pi / 180),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Transform.rotate(
            angle: -angle * (math.pi / 180),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingWidget()
            : _errorMessage != null
                ? _buildErrorWidget()
                : _buildCompassWidget(),
      ),
    );
  }
}

/// Кастомный painter для стрелки Киблы
class QiblaArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);

    // Рисуем стрелку направленную вверх
    path.moveTo(center.dx, center.dy - 50); // Верхушка стрелки
    path.lineTo(center.dx - 12, center.dy - 20); // Левая сторона
    path.lineTo(center.dx - 5, center.dy - 20); // Внутренний левый край
    path.lineTo(center.dx - 5, center.dy + 50); // Левый низ
    path.lineTo(center.dx + 5, center.dy + 50); // Правый низ
    path.lineTo(center.dx + 5, center.dy - 20); // Внутренний правый край
    path.lineTo(center.dx + 12, center.dy - 20); // Правая сторона
    path.close();

    canvas.drawPath(path, paint);

    // Добавляем обводку
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

