import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:easy_hajj/models/prayer_times.dart';
import 'package:easy_hajj/models/location_data.dart';

/// Сервис для получения времен молитв через API
class PrayerTimesService {
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal();

  String? _cachedTimezone;

  /// Получить текущий часовой пояс устройства
  Future<String> _getDeviceTimezone() async {
    if (_cachedTimezone != null) {
      return _cachedTimezone!;
    }
    
    try {
      _cachedTimezone = await FlutterTimezone.getLocalTimezone();
      print('Часовой пояс устройства: $_cachedTimezone');
      return _cachedTimezone!;
    } catch (e) {
      print('Ошибка получения часового пояса: $e');
      // Возвращаем дефолтный часовой пояс для Малайзии
      return 'Asia/Kuala_Lumpur';
    }
  }

  /// Получить времена молитв по координатам
  Future<PrayerTimes?> getPrayerTimes(LocationData location) async {
    try {
      // Автоопределение метода расчета по региону
      int method = _getMethodByLocation(location.latitude, location.longitude);
      
      // Получаем часовой пояс устройства
      final timezone = await _getDeviceTimezone();
      
      // Используем текущую дату в формате DD-MM-YYYY
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      
      // Получаем tune параметры для корректировки времен (в минутах)
      final tuneParams = _getTuneParameters(location.latitude, location.longitude, method);
      
      // Правильно формируем URL с кодированием параметров (HTTPS!)
      final url = Uri.https(
        'api.aladhan.com',
        '/v1/timings/$dateStr',
        {
          'latitude': location.latitude.toString(),
          'longitude': location.longitude.toString(),
          'method': method.toString(),
          'timezonestring': timezone,
          if (tuneParams.isNotEmpty) 'tune': tuneParams,
        },
      );

      print('Запрос времен молитв: $url');
      print('Текущая дата устройства: $dateStr (${now.hour}:${now.minute}:${now.second})');
      print('Часовой пояс: $timezone');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 200 && data['status'] == 'OK') {
          print('Ответ API времен молитв: ${json.encode(data['data']['timings'])}');
          return PrayerTimes.fromJson(data['data']);
        } else {
          throw Exception('API вернул ошибку: ${data['status']}');
        }
      } else {
        throw Exception('HTTP ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка получения времен молитв: $e');
      return null;
    }
  }

  /// Автоматическое определение метода расчета по геолокации
  /// Получить параметры корректировки времен (tune) для региона
  /// Формат: Imsak,Fajr,Sunrise,Dhuhr,Asr,Sunset,Maghrib,Isha,Midnight
  /// Значения в минутах (положительные добавляют, отрицательные вычитают)
  String _getTuneParameters(double latitude, double longitude, int method) {
    // Малайзия с MWL методом требует корректировки
    if (latitude >= 0.85 && latitude <= 7.4 && longitude >= 99.6 && longitude <= 119.3 && method == 3) {
      // Корректировки для точного соответствия официальным временам JAKIM:
      // Fajr: +2 мин, Sunrise: 0 мин, Dhuhr: +1 мин, Asr: +1 мин, Maghrib: +2 мин, Isha: +5 мин
      return "0,2,0,1,1,0,2,5,0";
    }
    // Для других регионов корректировки не требуются
    return "";
  }

  int _getMethodByLocation(double latitude, double longitude) {
    // Сингапур (более точные границы)
    if (latitude >= 1.15 && latitude <= 1.47 && longitude >= 103.6 && longitude <= 104.0) {
      return 11; // Majlis Ugama Islam Singapura (MUIS)
    }
    // Малайзия (используем MWL с поправками для региона)
    else if (latitude >= 0.85 && latitude <= 7.4 && longitude >= 99.6 && longitude <= 119.3) {
      return 3; // Muslim World League (более точный для Малайзии)
    }
    // Бруней
    else if (latitude >= 4.0 && latitude <= 5.1 && longitude >= 114.0 && longitude <= 115.5) {
      return 11; // MUIS (близко к Малайзии)
    }
    // Турция
    else if (latitude >= 36 && latitude <= 42 && longitude >= 26 && longitude <= 45) {
      return 13; // Diyanet İşleri Başkanlığı
    }
    // Россия, Казахстан
    else if (latitude >= 40 && latitude <= 75 && longitude >= 20 && longitude <= 180) {
      return 14; // Spiritual Administration of Muslims of Russia
    }
    // Персидский залив (ОАЭ, Саудовская Аравия, Кувейт, Катар)
    else if (latitude >= 15 && latitude <= 32 && longitude >= 34 && longitude <= 60) {
      return 8; // Gulf Region
    }
    // Египет
    else if (latitude >= 22 && latitude <= 32 && longitude >= 25 && longitude <= 35) {
      return 5; // Egyptian General Authority of Survey
    }
    // По умолчанию - Muslim World League (универсальный)
    else {
      return 3; // MWL
    }
  }

  /// Получить времена молитв на конкретную дату
  Future<PrayerTimes?> getPrayerTimesForDate(
    LocationData location,
    DateTime date,
  ) async {
    try {
      // Определяем метод расчета на основе местоположения
      int method = _getMethodByLocation(location.latitude, location.longitude);
      
      // Получаем часовой пояс устройства
      final timezone = await _getDeviceTimezone();
      
      // Форматируем дату в формате DD-MM-YYYY
      final dateStr = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      
      // Получаем tune параметры для корректировки времен (в минутах)
      final tuneParams = _getTuneParameters(location.latitude, location.longitude, method);
      
      // Правильно формируем URL с кодированием параметров (HTTPS!)
      final url = Uri.https(
        'api.aladhan.com',
        '/v1/timings/$dateStr',
        {
          'latitude': location.latitude.toString(),
          'longitude': location.longitude.toString(),
          'method': method.toString(),
          'timezonestring': timezone,
          if (tuneParams.isNotEmpty) 'tune': tuneParams,
        },
      );

      print('📅 Запрос времен молитв для даты $dateStr: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 200 && data['status'] == 'OK') {
          print('✅ Времена молитв для $dateStr получены');
          return PrayerTimes.fromJson(data['data']);
        } else {
          throw Exception('API вернул ошибку: ${data['status']}');
        }
      } else {
        throw Exception('HTTP ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка получения времен молитв для даты: $e');
      return null;
    }
  }

  /// Получить времена молитв на месяц
  Future<List<PrayerTimes>?> getMonthlyPrayerTimes(
    LocationData location,
    int year,
    int month,
  ) async {
    try {
      // Автоопределение метода расчета по региону
      int method = _getMethodByLocation(location.latitude, location.longitude);
      
      // Получаем часовой пояс устройства
      final timezone = await _getDeviceTimezone();
      
      // Получаем tune параметры для корректировки времен
      final tuneParams = _getTuneParameters(location.latitude, location.longitude, method);
      
      // Правильно формируем URL с кодированием параметров (HTTPS!)
      final url = Uri.https(
        'api.aladhan.com',
        '/v1/calendar/$year/$month',
        {
          'latitude': location.latitude.toString(),
          'longitude': location.longitude.toString(),
          'method': method.toString(),
          'timezonestring': timezone,
          if (tuneParams.isNotEmpty) 'tune': tuneParams,
        },
      );

      print('Запрос месячных времен молитв: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 200 && data['status'] == 'OK') {
          final List<dynamic> daysData = data['data'];
          return daysData.map((day) => PrayerTimes.fromJson(day)).toList();
        } else {
          throw Exception('API вернул ошибку: ${data['status']}');
        }
      } else {
        throw Exception('HTTP ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка получения месячных времен молитв: $e');
      return null;
    }
  }

  /// Методы расчета (для настроек)
  /// 1 = University of Islamic Sciences, Karachi
  /// 2 = Islamic Society of North America (ISNA)
  /// 3 = Muslim World League
  /// 4 = Umm Al-Qura University, Makkah
  /// 5 = Egyptian General Authority of Survey
  /// 7 = Institute of Geophysics, University of Tehran
  /// 8 = Gulf Region
  /// 9 = Kuwait
  /// 10 = Qatar
  /// 11 = Majlis Ugama Islam Singapura, Singapore
  /// 12 = Union Organization islamic de France
  /// 13 = Diyanet İşleri Başkanlığı, Turkey
  /// 14 = Spiritual Administration of Muslims of Russia
  
  Map<int, String> getCalculationMethods() {
    return {
      1: 'University of Islamic Sciences, Karachi',
      2: 'Islamic Society of North America (ISNA)',
      3: 'Muslim World League',
      4: 'Umm Al-Qura University, Makkah',
      5: 'Egyptian General Authority of Survey',
      7: 'Institute of Geophysics, University of Tehran',
      8: 'Gulf Region',
      9: 'Kuwait',
      10: 'Qatar',
      11: 'Majlis Ugama Islam Singapura, Singapore',
      12: 'Union Organization islamic de France',
      13: 'Diyanet İşleri Başkanlığı, Turkey',
      14: 'Spiritual Administration of Muslims of Russia',
    };
  }
}

