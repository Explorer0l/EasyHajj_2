/// Модель времен молитв
class PrayerTimes {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final DateTime date;

  PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
  });

  /// Создание из JSON (API ответ)
  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    final timings = json['timings'] as Map<String, dynamic>;
    final dateString = json['date']['readable'] as String;
    
    return PrayerTimes(
      fajr: _cleanTime(timings['Fajr'] as String),
      sunrise: _cleanTime(timings['Sunrise'] as String),
      dhuhr: _cleanTime(timings['Dhuhr'] as String),
      asr: _cleanTime(timings['Asr'] as String),
      maghrib: _cleanTime(timings['Maghrib'] as String),
      isha: _cleanTime(timings['Isha'] as String),
      date: DateTime.now(), // Можно парсить из json['date']
    );
  }

  /// Преобразование в JSON для хранения
  Map<String, dynamic> toJson() {
    return {
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'date': date.toIso8601String(),
    };
  }

  /// Создание из сохраненных данных
  factory PrayerTimes.fromStoredJson(Map<String, dynamic> json) {
    return PrayerTimes(
      fajr: json['fajr'] as String,
      sunrise: json['sunrise'] as String,
      dhuhr: json['dhuhr'] as String,
      asr: json['asr'] as String,
      maghrib: json['maghrib'] as String,
      isha: json['isha'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  /// Очистка времени от часового пояса (например "12:30 (+03)" -> "12:30")
  static String _cleanTime(String time) {
    return time.split(' ').first;
  }

  /// Получить список всех молитв (без Шурук)
  List<Prayer> getAllPrayers() {
    return [
      Prayer(name: 'Фаджр', nameEn: 'Fajr', time: fajr, type: PrayerType.fajr),
      Prayer(name: 'Зухр', nameEn: 'Dhuhr', time: dhuhr, type: PrayerType.dhuhr),
      Prayer(name: 'Аср', nameEn: 'Asr', time: asr, type: PrayerType.asr),
      Prayer(name: 'Магриб', nameEn: 'Maghrib', time: maghrib, type: PrayerType.maghrib),
      Prayer(name: 'Иша', nameEn: 'Isha', time: isha, type: PrayerType.isha),
    ];
  }

  /// Получить следующую молитву (которая еще не наступила)
  Prayer? getCurrentPrayer() {
    final now = DateTime.now();
    final prayers = getAllPrayers();
    
    // Проходим по всем молитвам и ищем первую, которая еще не наступила
    for (int i = 0; i < prayers.length; i++) {
      final prayerTime = _parseTime(prayers[i].time);
      if (now.isBefore(prayerTime)) {
        return prayers[i]; // Возвращаем следующую молитву
      }
    }
    
    // Если все молитвы прошли сегодня, следующая - Фаджр завтра
    return prayers.first;
  }

  /// Получить следующую молитву (которая еще не наступила)
  Prayer? getNextPrayer() {
    // Просто возвращаем текущую (следующую предстоящую) молитву
    return getCurrentPrayer();
  }
  
  /// Получить молитву после следующей
  Prayer? getFollowingPrayer() {
    final current = getCurrentPrayer();
    if (current == null) return null;
    
    final prayers = getAllPrayers();
    final currentIndex = prayers.indexWhere((p) => p.type == current.type);
    
    if (currentIndex == -1 || currentIndex == prayers.length - 1) {
      return prayers.first; // Следующий день
    }
    
    return prayers[currentIndex + 1];
  }

  /// Парсинг времени в DateTime
  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Получить прогресс между двумя молитвами (0.0 - 1.0)
  double getProgressBetweenPrayers() {
    final now = DateTime.now();
    final prayers = getAllPrayers();
    
    if (prayers.isEmpty) return 0.0;
    
    // Конвертируем все времена в минуты от начала дня
    final currentMinutes = now.hour * 60 + now.minute;
    
    // Находим между какими молитвами мы находимся
    int currentSegment = 0;
    for (int i = 0; i < prayers.length; i++) {
      final prayerTime = _parseTime(prayers[i].time);
      final prayerMinutes = prayerTime.hour * 60 + prayerTime.minute;
      
      if (currentMinutes < prayerMinutes) {
        currentSegment = i;
        break;
      }
      if (i == prayers.length - 1) {
        // После последней молитвы
        return 1.0;
      }
    }
    
    if (currentSegment == 0) {
      // До первой молитвы
      return 0.0;
    }
    
    // Рассчитываем прогресс в текущем сегменте
    final previousPrayer = prayers[currentSegment - 1];
    final nextPrayer = prayers[currentSegment];
    
    final previousTime = _parseTime(previousPrayer.time);
    final nextTime = _parseTime(nextPrayer.time);
    
    final previousMinutes = previousTime.hour * 60 + previousTime.minute;
    final nextMinutes = nextTime.hour * 60 + nextTime.minute;
    
    final segmentDuration = nextMinutes - previousMinutes;
    final elapsed = currentMinutes - previousMinutes;
    
    if (segmentDuration <= 0) return 0.0;
    
    // Прогресс в текущем сегменте (от 0.0 до 1.0)
    final segmentProgress = (elapsed / segmentDuration).clamp(0.0, 1.0);
    
    // Общий прогресс по дню
    // Каждый сегмент занимает 1/(количество сегментов) от всей линии
    final segmentWeight = 1.0 / (prayers.length - 1);
    final baseProgress = (currentSegment - 1) * segmentWeight;
    
    return (baseProgress + (segmentProgress * segmentWeight)).clamp(0.0, 1.0);
  }
}

/// Тип молитвы
enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}

/// Модель отдельной молитвы
class Prayer {
  final String name;
  final String nameEn;
  final String time;
  final PrayerType type;

  Prayer({
    required this.name,
    required this.nameEn,
    required this.time,
    required this.type,
  });
}

