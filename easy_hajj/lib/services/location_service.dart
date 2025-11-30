import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_hajj/models/location_data.dart';

/// Статус доступности геолокации
enum LocationStatus {
  available, // Все готово
  permissionDenied, // Разрешение не предоставлено
  serviceDisabled, // GPS отключен
  permissionDeniedAndServiceDisabled, // И разрешение, и GPS
  error, // Ошибка проверки
}

/// Сервис для работы с геолокацией
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Проверка разрешений на геолокацию
  Future<bool> checkPermissions() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Запрос разрешений на геолокацию
  Future<bool> requestPermissions() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Проверка, включена ли геолокация на устройстве
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Получение текущего местоположения с активным запросом разрешений
  Future<LocationData?> getCurrentLocation() async {
    try {
      print('📍 Начало получения геолокации...');
      
      // ШАГ 1: Проверяем разрешения СНАЧАЛА
      bool hasPermission = await checkPermissions();
      print('📍 Текущее состояние разрешения: $hasPermission');
      
      if (!hasPermission) {
        print('📍 Запрос разрешения на геолокацию у пользователя...');
        hasPermission = await requestPermissions();
        print('📍 Результат запроса разрешения: $hasPermission');
        
        if (!hasPermission) {
          print('❌ Пользователь отклонил разрешение на геолокацию');
          throw Exception('Разрешение на геолокацию не предоставлено. Пожалуйста, разрешите доступ к геолокации в настройках приложения.');
        }
      }
      
      // ШАГ 2: Проверяем, включена ли служба геолокации
      final serviceEnabled = await isLocationServiceEnabled();
      print('📍 Служба геолокации включена: $serviceEnabled');
      
      if (!serviceEnabled) {
        print('⚠️ GPS отключен на устройстве');
        throw Exception('GPS отключен');
      }

      // ШАГ 3: Получаем позицию
      print('📍 Получение текущей позиции...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: false,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Превышено время ожидания GPS сигнала. Убедитесь, что находитесь на открытом пространстве.');
        },
      );

      print('✅ Позиция получена: ${position.latitude}, ${position.longitude}');
      print('📍 Точность: ${position.accuracy}м');

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('❌ Ошибка получения геолокации: $e');
      rethrow; // Пробрасываем ошибку выше для более детальной обработки
    }
  }
  
  /// Проверка доступности геолокации с детальной информацией
  Future<LocationStatus> checkLocationStatus() async {
    try {
      // Проверяем разрешения
      final hasPermission = await checkPermissions();
      
      // Проверяем службу геолокации
      final serviceEnabled = await isLocationServiceEnabled();
      
      if (!hasPermission && !serviceEnabled) {
        return LocationStatus.permissionDeniedAndServiceDisabled;
      } else if (!hasPermission) {
        return LocationStatus.permissionDenied;
      } else if (!serviceEnabled) {
        return LocationStatus.serviceDisabled;
      } else {
        return LocationStatus.available;
      }
    } catch (e) {
      print('❌ Ошибка проверки статуса геолокации: $e');
      return LocationStatus.error;
    }
  }

  /// Получение названия города по координатам (через Geocoding или API)
  Future<LocationData?> getLocationWithCity(double latitude, double longitude) async {
    try {
      // Здесь можно использовать Geocoding API для получения города
      // Пока возвращаем базовую информацию
      return LocationData(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Ошибка получения информации о городе: $e');
      return null;
    }
  }

  /// Расчет расстояния между двумя точками (в метрах)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Расчет направления на Каабу (Кибла)
  /// Координаты Каабы: 21.4225° N, 39.8262° E
  double calculateQiblaDirection(double latitude, double longitude) {
    const kaabaLat = 21.4225;
    const kaabaLng = 39.8262;

    return Geolocator.bearingBetween(
      latitude,
      longitude,
      kaabaLat,
      kaabaLng,
    );
  }

  /// Открыть настройки местоположения
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Открыть настройки приложения
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Подписка на изменения местоположения
  Stream<LocationData> getLocationStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    
    return Geolocator.getPositionStream(locationSettings: settings)
        .map((position) {
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
    });
  }
}


