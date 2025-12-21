import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_hajj/models/prayer_times.dart';
import 'package:easy_hajj/models/location_data.dart';

/// Сервис для хранения данных локально
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  // Ключи для хранения
  static const String _keyLocation = 'location_data';
  static const String _keyPrayerTimes = 'prayer_times';
  static const String _keyLastUpdate = 'last_update';
  static const String _keyCalculationMethod = 'calculation_method';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyIslamicEvents = 'islamic_events_';
  static const String _keyIslamicEventsYear = 'islamic_events_year';
  
  // Ключи для уведомлений каждой молитвы
  static const String _keyNotificationFajr = 'notification_fajr';
  static const String _keyNotificationDhuhr = 'notification_dhuhr';
  static const String _keyNotificationAsr = 'notification_asr';
  static const String _keyNotificationMaghrib = 'notification_maghrib';
  static const String _keyNotificationIsha = 'notification_isha';

  /// Инициализация
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Убедиться, что сервис инициализирован
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }

  // ==================== ГЕОЛОКАЦИЯ ====================

  /// Сохранить геолокацию
  Future<bool> saveLocation(LocationData location) async {
    await _ensureInitialized();
    final json = jsonEncode(location.toJson());
    return await _prefs!.setString(_keyLocation, json);
  }

  /// Получить сохраненную геолокацию
  Future<LocationData?> getLocation() async {
    await _ensureInitialized();
    final json = _prefs!.getString(_keyLocation);
    
    if (json == null) return null;
    
    try {
      final data = jsonDecode(json);
      return LocationData.fromJson(data);
    } catch (e) {
      print('Ошибка при чтении геолокации: $e');
      return null;
    }
  }

  /// Удалить сохраненную геолокацию
  Future<bool> clearLocation() async {
    await _ensureInitialized();
    return await _prefs!.remove(_keyLocation);
  }

  // ==================== ВРЕМЕНА МОЛИТВ ====================

  /// Сохранить времена молитв
  Future<bool> savePrayerTimes(PrayerTimes prayerTimes) async {
    await _ensureInitialized();
    final json = jsonEncode(prayerTimes.toJson());
    await _prefs!.setString(_keyLastUpdate, DateTime.now().toIso8601String());
    return await _prefs!.setString(_keyPrayerTimes, json);
  }

  /// Получить сохраненные времена молитв
  Future<PrayerTimes?> getPrayerTimes() async {
    await _ensureInitialized();
    final json = _prefs!.getString(_keyPrayerTimes);
    
    if (json == null) return null;
    
    try {
      final data = jsonDecode(json);
      return PrayerTimes.fromStoredJson(data);
    } catch (e) {
      print('Ошибка при чтении времен молитв: $e');
      return null;
    }
  }

  /// Проверить, актуальны ли сохраненные времена молитв
  Future<bool> isPrayerTimesValid() async {
    await _ensureInitialized();
    final lastUpdateStr = _prefs!.getString(_keyLastUpdate);
    
    if (lastUpdateStr == null) return false;
    
    try {
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      
      // Времена молитв актуальны, если это тот же день
      return lastUpdate.year == now.year &&
             lastUpdate.month == now.month &&
             lastUpdate.day == now.day;
    } catch (e) {
      return false;
    }
  }

  /// Удалить сохраненные времена молитв
  Future<bool> clearPrayerTimes() async {
    await _ensureInitialized();
    await _prefs!.remove(_keyLastUpdate);
    return await _prefs!.remove(_keyPrayerTimes);
  }

  // ==================== НАСТРОЙКИ ====================

  /// Сохранить метод расчета
  Future<bool> saveCalculationMethod(int method) async {
    await _ensureInitialized();
    return await _prefs!.setInt(_keyCalculationMethod, method);
  }

  /// Получить метод расчета (по умолчанию 2 = ISNA)
  Future<int> getCalculationMethod() async {
    await _ensureInitialized();
    return _prefs!.getInt(_keyCalculationMethod) ?? 2;
  }

  /// Сохранить статус уведомлений
  Future<bool> saveNotificationsEnabled(bool enabled) async {
    await _ensureInitialized();
    return await _prefs!.setBool(_keyNotificationsEnabled, enabled);
  }

  /// Получить статус уведомлений
  Future<bool> getNotificationsEnabled() async {
    await _ensureInitialized();
    return _prefs!.getBool(_keyNotificationsEnabled) ?? true;
  }

  // ==================== УВЕДОМЛЕНИЯ ДЛЯ МОЛИТВ ====================

  /// Сохранить настройку уведомления для конкретной молитвы
  Future<bool> savePrayerNotification(String prayerName, bool enabled) async {
    await _ensureInitialized();
    final key = _getPrayerNotificationKey(prayerName);
    return await _prefs!.setBool(key, enabled);
  }

  /// Получить настройку уведомления для конкретной молитвы (по умолчанию true)
  Future<bool> getPrayerNotification(String prayerName) async {
    await _ensureInitialized();
    final key = _getPrayerNotificationKey(prayerName);
    // По умолчанию все уведомления включены
    return _prefs!.getBool(key) ?? true;
  }

  /// Получить ключ для конкретной молитвы
  String _getPrayerNotificationKey(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'фаджр':
      case 'fajr':
        return _keyNotificationFajr;
      case 'зухр':
      case 'dhuhr':
        return _keyNotificationDhuhr;
      case 'аср':
      case 'asr':
        return _keyNotificationAsr;
      case 'магриб':
      case 'maghrib':
        return _keyNotificationMaghrib;
      case 'иша':
      case 'isha':
        return _keyNotificationIsha;
      default:
        return 'notification_${prayerName.toLowerCase()}';
    }
  }

  /// Получить все настройки уведомлений для молитв
  Future<Map<String, bool>> getAllPrayerNotifications() async {
    await _ensureInitialized();
    return {
      'Фаджр': await getPrayerNotification('Фаджр'),
      'Зухр': await getPrayerNotification('Зухр'),
      'Аср': await getPrayerNotification('Аср'),
      'Магриб': await getPrayerNotification('Магриб'),
      'Иша': await getPrayerNotification('Иша'),
    };
  }

  /// Включить все уведомления для молитв (по умолчанию при первом запуске)
  Future<void> enableAllPrayerNotifications() async {
    await _ensureInitialized();
    await savePrayerNotification('Фаджр', true);
    await savePrayerNotification('Зухр', true);
    await savePrayerNotification('Аср', true);
    await savePrayerNotification('Магриб', true);
    await savePrayerNotification('Иша', true);
  }

  /// Проверить, первый ли это запуск приложения
  Future<bool> isFirstLaunch() async {
    await _ensureInitialized();
    return _prefs!.getBool(_keyFirstLaunch) ?? true;
  }

  /// Отметить, что приложение было запущено
  Future<bool> setNotFirstLaunch() async {
    await _ensureInitialized();
    return await _prefs!.setBool(_keyFirstLaunch, false);
  }

  // ==================== ИСЛАМСКИЕ СОБЫТИЯ ====================

  /// Сохранить исламские события на год
  Future<bool> saveIslamicEvents(int year, String eventsJson) async {
    await _ensureInitialized();
    await _prefs!.setInt(_keyIslamicEventsYear, year);
    return await _prefs!.setString('$_keyIslamicEvents$year', eventsJson);
  }

  /// Получить сохраненные исламские события для года
  Future<String?> getIslamicEvents(int year) async {
    await _ensureInitialized();
    return _prefs!.getString('$_keyIslamicEvents$year');
  }

  /// Проверить, актуальны ли сохраненные события
  Future<bool> areIslamicEventsValid(int year) async {
    await _ensureInitialized();
    final savedYear = _prefs!.getInt(_keyIslamicEventsYear);
    return savedYear == year && _prefs!.containsKey('$_keyIslamicEvents$year');
  }

  /// Очистить старые исламские события
  Future<void> clearOldIslamicEvents() async {
    await _ensureInitialized();
    final currentYear = DateTime.now().year;
    
    // Удаляем события старше 2 лет
    for (int year = currentYear - 3; year < currentYear; year++) {
      await _prefs!.remove('$_keyIslamicEvents$year');
    }
  }

  // ==================== УТИЛИТЫ ====================

  /// Очистить все данные
  Future<bool> clearAll() async {
    await _ensureInitialized();
    return await _prefs!.clear();
  }

  /// Получить время последнего обновления
  Future<DateTime?> getLastUpdateTime() async {
    await _ensureInitialized();
    final lastUpdateStr = _prefs!.getString(_keyLastUpdate);
    
    if (lastUpdateStr == null) return null;
    
    try {
      return DateTime.parse(lastUpdateStr);
    } catch (e) {
      return null;
    }
  }

  // ==================== УНИВЕРСАЛЬНЫЕ МЕТОДЫ ====================

  /// Сохранить строку по ключу
  Future<bool> saveString(String key, String value) async {
    await _ensureInitialized();
    return await _prefs!.setString(key, value);
  }

  /// Получить строку по ключу
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs!.getString(key);
  }
}

