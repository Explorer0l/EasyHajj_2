import 'dart:convert';
import 'package:http/http.dart' as http;

/// Сервис для работы с Хиджри датами
class HijriDateService {
  static final HijriDateService _instance = HijriDateService._internal();
  factory HijriDateService() => _instance;
  HijriDateService._internal();

  static const String _baseUrl = 'https://api.aladhan.com/v1';
  
  // Кэш для конвертации дат
  final Map<String, HijriDate> _cache = {};

  /// Получить Хиджри дату для григорианской даты
  Future<HijriDate?> getHijriDate(DateTime gregorianDate) async {
    final cacheKey = '${gregorianDate.year}-${gregorianDate.month}-${gregorianDate.day}';
    
    // Проверяем кэш
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      // API требует формат DD-MM-YYYY
      final dateStr = '${gregorianDate.day.toString().padLeft(2, '0')}-${gregorianDate.month.toString().padLeft(2, '0')}-${gregorianDate.year}';
      final url = Uri.parse('$_baseUrl/gToH/$dateStr');

      print('Запрос Хиджри даты: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 200) {
          final hijriData = data['data']['hijri'];
          
          // Парсим с обработкой разных типов (String или int)
          final day = hijriData['day'] is int 
              ? hijriData['day'] as int 
              : int.parse(hijriData['day'] as String);
          
          final monthNumber = hijriData['month']['number'];
          final month = monthNumber is int 
              ? monthNumber 
              : int.parse(monthNumber as String);
          
          final yearData = hijriData['year'];
          final year = yearData is int 
              ? yearData 
              : int.parse(yearData as String);
          
          final hijriDate = HijriDate(
            day: day,
            month: month,
            year: year,
            monthName: hijriData['month']['ar'] as String,
            monthNameEn: hijriData['month']['en'] as String,
            weekdayName: hijriData['weekday']['ar'] as String,
            weekdayNameEn: hijriData['weekday']['en'] as String,
          );
          
          // Сохраняем в кэш
          _cache[cacheKey] = hijriDate;
          
          print('Получена Хиджри дата: ${hijriDate.format()}');
          
          return hijriDate;
        }
      }
      
      print('Ошибка API Хиджри: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Ошибка получения Хиджри даты: $e');
    }

    return null;
  }

  /// Очистить кэш
  void clearCache() {
    _cache.clear();
  }

  /// Получить название месяца Хиджри на русском
  String getHijriMonthNameRu(int month) {
    const months = [
      'Мухаррам',
      'Сафар',
      'Раби-уль-авваль',
      'Раби-уль-ахир',
      'Джумада-ль-уля',
      'Джумада-ль-ахира',
      'Раджаб',
      'Шаабан',
      'Рамадан',
      'Шавваль',
      'Зуль-Каада',
      'Зуль-Хиджа',
    ];
    // Безопасная проверка границ массива
    if (month < 1 || month > 12) {
      return 'Неизвестный месяц';
    }
    return months[month - 1];
  }
}

/// Модель Хиджри даты
class HijriDate {
  final int day;
  final int month;
  final int year;
  final String monthName;
  final String monthNameEn;
  final String weekdayName;
  final String weekdayNameEn;

  HijriDate({
    required this.day,
    required this.month,
    required this.year,
    required this.monthName,
    required this.monthNameEn,
    required this.weekdayName,
    required this.weekdayNameEn,
  });

  /// Получить название месяца на русском
  String getMonthNameRu() {
    return HijriDateService().getHijriMonthNameRu(month);
  }

  /// Форматированная дата
  String format() {
    return '$day ${getMonthNameRu()} $year г.х.';
  }

  /// Короткий формат
  String formatShort() {
    return '$day.${month.toString().padLeft(2, '0')}.$year';
  }
}

