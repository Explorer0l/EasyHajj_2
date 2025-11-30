import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_hajj/models/islamic_event.dart';
import 'package:easy_hajj/services/storage_service.dart';

/// Сервис для получения исламских событий и праздников
class IslamicEventsService {
  static final IslamicEventsService _instance = IslamicEventsService._internal();
  factory IslamicEventsService() => _instance;
  IslamicEventsService._internal();

  static const String _baseUrl = 'https://api.aladhan.com/v1';
  final _storage = StorageService();
  
  // Кэш в памяти для быстрого доступа
  final Map<int, List<IslamicEvent>> _eventsCache = {};

  /// Получить список исламских событий на год (с кэшированием)
  Future<List<IslamicEvent>> getIslamicEventsForYear(int year) async {
    // Проверяем кэш в памяти
    if (_eventsCache.containsKey(year)) {
      print('Загружены события из кэша памяти для года $year');
      return _eventsCache[year]!;
    }

    // Проверяем кэш в storage
    try {
      final cachedJson = await _storage.getIslamicEvents(year);
      if (cachedJson != null) {
        print('Загружены события из локального хранилища для года $year');
        final List<dynamic> jsonList = json.decode(cachedJson);
        final events = jsonList.map((e) => IslamicEvent.fromJson(e)).toList();
        _eventsCache[year] = events;
        return events;
      }
    } catch (e) {
      print('Ошибка загрузки кэшированных событий: $e');
    }

    // Загружаем из API
    print('Загружаем события из API для года $year');
    final events = await _loadEventsFromAPI(year);
    
    // Сохраняем в кэш
    if (events.isNotEmpty) {
      _eventsCache[year] = events;
      
      // Сохраняем в storage
      try {
        final jsonList = events.map((e) => e.toJson()).toList();
        final jsonString = json.encode(jsonList);
        await _storage.saveIslamicEvents(year, jsonString);
        print('События сохранены в локальное хранилище');
      } catch (e) {
        print('Ошибка сохранения событий: $e');
      }
    }
    
    return events;
  }

  /// Загрузить события из API (внутренний метод)
  Future<List<IslamicEvent>> _loadEventsFromAPI(int year) async {
    final events = <IslamicEvent>[];

    try {
      // Используем текущую дату для получения хиджри календаря
      final date = DateTime(year, 1, 1);
      
      // Получаем данные о хиджри дате для начала года
      final dateStr = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      final url = Uri.parse('$_baseUrl/gToH/$dateStr');
      print('Запрос исламских событий: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 200) {
          final hijriData = data['data']['hijri'];
          
          // Парсим год с обработкой разных типов
          final yearData = hijriData['year'];
          final hijriYear = yearData is int 
              ? yearData 
              : int.parse(yearData as String);
          
          print('Получен Хиджри год: $hijriYear для григорианского года $year');
          
          // Добавляем фиксированные исламские праздники
          final fixedEvents = await _getFixedIslamicEvents(year, hijriYear);
          events.addAll(fixedEvents);
        } else {
          print('Ошибка API: ${data['status']}');
        }
      } else {
        print('HTTP ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка получения исламских событий: $e');
    }

    // Если не удалось получить через API, возвращаем примерные даты
    if (events.isEmpty) {
      print('Используем примерные даты для года $year');
      events.addAll(_getApproximateEventsForYear(year));
    }

    // Сортируем по дате
    events.sort((a, b) => a.gregorianDate.compareTo(b.gregorianDate));
    
    print('Загружено ${events.length} исламских событий');
    
    return events;
  }

  /// Получить фиксированные исламские события по хиджри календарю
  Future<List<IslamicEvent>> _getFixedIslamicEvents(int gregorianYear, int hijriYear) async {
    final events = <IslamicEvent>[];
    
    // Основные исламские события с фиксированными датами по хиджри
    final fixedEvents = [
      {
        'name': 'Исламский Новый год',
        'nameEn': 'Islamic New Year',
        'hijriMonth': 1,
        'hijriDay': 1,
        'type': 'hijri_new_year',
      },
      {
        'name': 'День Ашура',
        'nameEn': 'Day of Ashura',
        'hijriMonth': 1,
        'hijriDay': 10,
        'type': 'ashura',
      },
      {
        'name': 'Маулид (День рождения Пророка)',
        'nameEn': 'Mawlid al-Nabi',
        'hijriMonth': 3,
        'hijriDay': 12,
        'type': 'mawlid',
      },
      {
        'name': 'Ночь Мирадж',
        'nameEn': 'Isra and Miraj',
        'hijriMonth': 7,
        'hijriDay': 27,
        'type': 'isra',
      },
      {
        'name': 'Ночь Бараат',
        'nameEn': 'Lailatul Baraat',
        'hijriMonth': 8,
        'hijriDay': 15,
        'type': 'lailatul_baraat',
      },
      {
        'name': 'Начало Рамадана',
        'nameEn': 'Ramadan Begins',
        'hijriMonth': 9,
        'hijriDay': 1,
        'type': 'ramadan',
      },
      {
        'name': 'Ночь Кадр',
        'nameEn': 'Laylatul Qadr',
        'hijriMonth': 9,
        'hijriDay': 27,
        'type': 'laylatul_qadr',
      },
      {
        'name': 'Ураза-байрам',
        'nameEn': 'Eid al-Fitr',
        'hijriMonth': 10,
        'hijriDay': 1,
        'type': 'eid_al_fitr',
      },
      {
        'name': 'День Арафат',
        'nameEn': 'Day of Arafat',
        'hijriMonth': 12,
        'hijriDay': 9,
        'type': 'arafat',
      },
      {
        'name': 'Курбан-байрам',
        'nameEn': 'Eid al-Adha',
        'hijriMonth': 12,
        'hijriDay': 10,
        'type': 'eid_al_adha',
      },
    ];

    // Также проверяем следующий хиджри год, так как события могут быть на границе лет
    final hijriYears = [hijriYear, hijriYear + 1];
    
    for (var hYear in hijriYears) {
      for (var event in fixedEvents) {
        // Точно конвертируем хиджри дату в григорианскую через API
        final gregorianDate = await _hijriToGregorian(
          hYear,
          event['hijriMonth'] as int,
          event['hijriDay'] as int,
        );

        if (gregorianDate == null) continue;

        // Проверяем, что дата попадает в нужный григорианский год
        if (gregorianDate.year == gregorianYear) {
          events.add(IslamicEvent(
            name: event['name'] as String,
            nameEn: event['nameEn'] as String,
            gregorianDate: gregorianDate,
            hijriDate: '${event['hijriDay']} ${_getHijriMonthName(event['hijriMonth'] as int)} $hYear',
            type: IslamicEvent.parseEventType(event['type'] as String),
          ));
        }
      }
    }

    return events;
  }

  /// Получить примерные даты исламских событий (если API не работает)
  List<IslamicEvent> _getApproximateEventsForYear(int year) {
    // Базовые даты на 2025 год (будут корректироваться для других лет)
    final base2025 = {
      'Исламский Новый год': DateTime(2025, 6, 27),
      'День Ашура': DateTime(2025, 7, 6),
      'Маулид': DateTime(2025, 9, 5),
      'Ночь Мирадж': DateTime(2025, 1, 27),
      'Ночь Бараат': DateTime(2025, 2, 14),
      'Начало Рамадана': DateTime(2025, 3, 1),
      'Ночь Кадр': DateTime(2025, 3, 27),
      'Ураза-байрам': DateTime(2025, 3, 31),
      'День Арафат': DateTime(2025, 6, 5),
      'Курбан-байрам': DateTime(2025, 6, 6),
    };

    // Приблизительный сдвиг: исламский год короче на ~11 дней
    final yearDiff = year - 2025;
    final dayShift = yearDiff * -11;

    final events = <IslamicEvent>[];

    base2025.forEach((name, baseDate) {
      final adjustedDate = baseDate.add(Duration(days: dayShift));
      
      IslamicEventType type;
      String nameEn;
      
      if (name.contains('Новый год')) {
        type = IslamicEventType.hijriNewYear;
        nameEn = 'Islamic New Year';
      } else if (name.contains('Ашура')) {
        type = IslamicEventType.ashura;
        nameEn = 'Day of Ashura';
      } else if (name.contains('Маулид')) {
        type = IslamicEventType.mawlid;
        nameEn = 'Mawlid al-Nabi';
      } else if (name.contains('Мирадж')) {
        type = IslamicEventType.isra;
        nameEn = 'Isra and Miraj';
      } else if (name.contains('Бараат')) {
        type = IslamicEventType.lalatulBaraat;
        nameEn = 'Lailatul Baraat';
      } else if (name.contains('Рамадан')) {
        type = IslamicEventType.ramadan;
        nameEn = 'Ramadan Begins';
      } else if (name.contains('Кадр')) {
        type = IslamicEventType.laylatulQadr;
        nameEn = 'Laylatul Qadr';
      } else if (name.contains('Ураза')) {
        type = IslamicEventType.eidAlFitr;
        nameEn = 'Eid al-Fitr';
      } else if (name.contains('Арафат')) {
        type = IslamicEventType.arafat;
        nameEn = 'Day of Arafat';
      } else {
        type = IslamicEventType.eidAlAdha;
        nameEn = 'Eid al-Adha';
      }

      events.add(IslamicEvent(
        name: name,
        nameEn: nameEn,
        gregorianDate: adjustedDate,
        hijriDate: 'Хиджри ${1446 + yearDiff}',
        type: type,
      ));
    });

    return events;
  }

  /// Точная конвертация хиджри даты в григорианскую через API
  Future<DateTime?> _hijriToGregorian(int hijriYear, int hijriMonth, int hijriDay) async {
    try {
      // Формат даты: DD-MM-YYYY
      final dateStr = '${hijriDay.toString().padLeft(2, '0')}-${hijriMonth.toString().padLeft(2, '0')}-$hijriYear';
      final url = Uri.parse('$_baseUrl/hToG/$dateStr');
      
      print('Конвертация хиджри даты в григорианскую: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 200) {
          final gregorianData = data['data']['gregorian'];
          
          // Парсим с обработкой разных типов (String или int)
          final dayData = gregorianData['day'];
          final day = dayData is int ? dayData : int.parse(dayData as String);
          
          final monthNumber = gregorianData['month']['number'];
          final month = monthNumber is int ? monthNumber : int.parse(monthNumber as String);
          
          final yearData = gregorianData['year'];
          final year = yearData is int ? yearData : int.parse(yearData as String);
          
          print('Хиджри $hijriDay/$hijriMonth/$hijriYear → Григорианская $day/$month/$year');
          
          return DateTime(year, month, day);
        }
      }
      
      print('Ошибка конвертации хиджри даты: ${response.statusCode}');
    } catch (e) {
      print('Ошибка API конвертации хиджри даты: $e');
    }
    
    // Fallback: используем приблизительную формулу
    return _approximateHijriToGregorian(hijriYear, hijriMonth, hijriDay);
  }
  
  /// Приблизительная конвертация (fallback)
  DateTime _approximateHijriToGregorian(int hijriYear, int hijriMonth, int hijriDay) {
    // Приблизительная формула конвертации
    // Григорианский год ≈ Хиджри год + 622 - (Хиджри год / 33)
    final gregorianYear = (hijriYear + 622 - (hijriYear / 33)).round();
    
    // Месяц смещается примерно на 11 дней в год
    final dayOfYear = ((hijriMonth - 1) * 29.5 + hijriDay).round();
    
    return DateTime(gregorianYear, 1, 1).add(Duration(days: dayOfYear - 1));
  }

  /// Получить название хиджри месяца
  String _getHijriMonthName(int month) {
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
    return months[month - 1];
  }

  /// Получить события для конкретного месяца
  Future<List<IslamicEvent>> getEventsForMonth(int year, int month) async {
    final allEvents = await getIslamicEventsForYear(year);
    return allEvents.where((event) => 
      event.gregorianDate.year == year && 
      event.gregorianDate.month == month
    ).toList();
  }

  /// Получить события для конкретного дня
  Future<List<IslamicEvent>> getEventsForDay(DateTime date) async {
    final allEvents = await getIslamicEventsForYear(date.year);
    return allEvents.where((event) =>
      event.gregorianDate.year == date.year &&
      event.gregorianDate.month == date.month &&
      event.gregorianDate.day == date.day
    ).toList();
  }
}

