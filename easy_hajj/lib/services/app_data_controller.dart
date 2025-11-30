import 'package:flutter/foundation.dart';
import 'package:easy_hajj/models/prayer_times.dart';
import 'package:easy_hajj/models/location_data.dart';
import 'package:easy_hajj/services/location_service.dart';
import 'package:easy_hajj/services/prayer_times_service.dart';
import 'package:easy_hajj/services/storage_service.dart';

/// Главный контроллер приложения для управления данными
class AppDataController extends ChangeNotifier {
  static final AppDataController _instance = AppDataController._internal();
  factory AppDataController() => _instance;
  AppDataController._internal();

  // Сервисы
  final _locationService = LocationService();
  final _prayerTimesService = PrayerTimesService();
  final _storageService = StorageService();

  // Состояние
  LocationData? _location;
  PrayerTimes? _prayerTimes;
  bool _isLoading = false;
  String? _error;

  // Геттеры
  LocationData? get location => _location;
  PrayerTimes? get prayerTimes => _prayerTimes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _location != null && _prayerTimes != null;

  /// Инициализация приложения
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      // Инициализируем storage
      await _storageService.init();
      
      // При первом запуске включаем все уведомления по умолчанию
      if (await _storageService.isFirstLaunch()) {
        print('Первый запуск приложения - включаем все уведомления по умолчанию');
        await _storageService.enableAllPrayerNotifications();
        await _storageService.saveNotificationsEnabled(true);
        await _storageService.setNotFirstLaunch();
      }
      
      // Загружаем сохраненные данные
      await _loadSavedData();
      
      // Если данных нет или они устарели, получаем новые
      if (!hasData || !await _isDataValid()) {
        await refreshData();
      }
    } catch (e) {
      _setError('Ошибка инициализации: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Загрузить сохраненные данные
  Future<void> _loadSavedData() async {
    try {
      _location = await _storageService.getLocation();
      _prayerTimes = await _storageService.getPrayerTimes();
      notifyListeners();
    } catch (e) {
      print('Ошибка загрузки сохраненных данных: $e');
    }
  }

  /// Проверить, актуальны ли данные
  Future<bool> _isDataValid() async {
    // Проверяем геолокацию
    if (_location != null && !_location!.isValid()) {
      return false;
    }
    
    // Проверяем времена молитв
    final isPrayerTimesValid = await _storageService.isPrayerTimesValid();
    return isPrayerTimesValid;
  }

  /// Обновить все данные
  Future<void> refreshData() async {
    _setLoading(true);
    _setError(null);
    
    try {
      // 1. Получаем геолокацию
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        throw Exception('Не удалось получить геолокацию');
      }
      
      _location = location;
      await _storageService.saveLocation(location);
      notifyListeners();
      
      // 2. Получаем времена молитв
      final prayerTimes = await _prayerTimesService.getPrayerTimes(location);
      if (prayerTimes == null) {
        throw Exception('Не удалось получить времена молитв');
      }
      
      _prayerTimes = prayerTimes;
      await _storageService.savePrayerTimes(prayerTimes);
      notifyListeners();
      
      print('Данные успешно обновлены');
    } catch (e) {
      _setError('Ошибка обновления данных: $e');
      print('Ошибка обновления данных: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Обновить только времена молитв (без геолокации)
  Future<void> refreshPrayerTimes() async {
    if (_location == null) {
      await refreshData();
      return;
    }
    
    _setLoading(true);
    _setError(null);
    
    try {
      final prayerTimes = await _prayerTimesService.getPrayerTimes(_location!);
      if (prayerTimes == null) {
        throw Exception('Не удалось получить времена молитв');
      }
      
      _prayerTimes = prayerTimes;
      await _storageService.savePrayerTimes(prayerTimes);
      notifyListeners();
    } catch (e) {
      _setError('Ошибка обновления времен молитв: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Обновить только геолокацию
  Future<void> refreshLocation() async {
    _setLoading(true);
    _setError(null);
    
    try {
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        throw Exception('Не удалось получить геолокацию');
      }
      
      _location = location;
      await _storageService.saveLocation(location);
      notifyListeners();
      
      // Автоматически обновляем времена молитв
      await refreshPrayerTimes();
    } catch (e) {
      _setError('Ошибка обновления геолокации: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Получить направление на Киблу
  double? getQiblaDirection() {
    if (_location == null) return null;
    return _locationService.calculateQiblaDirection(
      _location!.latitude,
      _location!.longitude,
    );
  }

  /// Получить текущую молитву
  Prayer? getCurrentPrayer() {
    return _prayerTimes?.getCurrentPrayer();
  }

  /// Получить следующую молитву
  Prayer? getNextPrayer() {
    return _prayerTimes?.getNextPrayer();
  }

  /// Получить прогресс между молитвами
  double getProgressBetweenPrayers() {
    final progress = _prayerTimes?.getProgressBetweenPrayers() ?? 0.0;
    // Отладка: выводим текущий прогресс
    // print('Текущий прогресс на таймлайне: ${(progress * 100).toStringAsFixed(1)}%');
    return progress;
  }

  /// Получить все молитвы
  List<Prayer> getAllPrayers() {
    return _prayerTimes?.getAllPrayers() ?? [];
  }

  /// Проверить разрешения на геолокацию
  Future<bool> checkLocationPermissions() async {
    return await _locationService.checkPermissions();
  }

  /// Запросить разрешения на геолокацию
  Future<bool> requestLocationPermissions() async {
    return await _locationService.requestPermissions();
  }

  /// Открыть настройки геолокации
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Очистить все данные
  Future<void> clearAllData() async {
    _location = null;
    _prayerTimes = null;
    _error = null;
    await _storageService.clearAll();
    notifyListeners();
  }

  // Приватные методы

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      notifyListeners();
    }
  }

  /// Получить время до следующей молитвы
  Duration? getTimeUntilNextPrayer() {
    final nextPrayer = getNextPrayer();
    if (nextPrayer == null || _prayerTimes == null) return null;
    
    final now = DateTime.now();
    final parts = nextPrayer.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    var prayerTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    // Если время уже прошло сегодня, берем завтрашний день
    if (prayerTime.isBefore(now)) {
      prayerTime = prayerTime.add(const Duration(days: 1));
    }
    
    return prayerTime.difference(now);
  }

  /// Форматировать оставшееся время
  String formatTimeUntilNextPrayer() {
    final duration = getTimeUntilNextPrayer();
    if (duration == null) return '--:--:--';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    return '-${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

