# Backend Services - Документация

Профессиональная реализация backend для работы с геолокацией и временами молитв.

## Архитектура

```
lib/
├── models/              # Модели данных
│   ├── location_data.dart
│   └── prayer_times.dart
└── services/            # Сервисы
    ├── location_service.dart      # Работа с геолокацией
    ├── prayer_times_service.dart  # API времен молитв
    ├── storage_service.dart       # Локальное хранилище
    └── app_data_controller.dart   # Главный контроллер
```

## Использование

### 1. Инициализация

В `main.dart` контроллер автоматически инициализируется:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final appController = AppDataController();
  await appController.initialize();
  
  runApp(const EasyHajjApp());
}
```

### 2. Получение данных в UI

#### Вариант 1: Прямое использование (Singleton)

```dart
import 'package:easy_hajj/services/app_data_controller.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = AppDataController();
    
    // Получить времена молитв
    final prayerTimes = controller.prayerTimes;
    
    // Получить текущую молитву
    final currentPrayer = controller.getCurrentPrayer();
    
    // Получить геолокацию
    final location = controller.location;
    
    return Text('Следующая молитва: ${currentPrayer?.name}');
  }
}
```

#### Вариант 2: С обновлениями (ListenableBuilder)

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = AppDataController();
    
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        if (controller.isLoading) {
          return CircularProgressIndicator();
        }
        
        if (controller.error != null) {
          return Text('Ошибка: ${controller.error}');
        }
        
        final prayers = controller.getAllPrayers();
        return ListView.builder(
          itemCount: prayers.length,
          itemBuilder: (context, index) {
            final prayer = prayers[index];
            return ListTile(
              title: Text(prayer.name),
              subtitle: Text(prayer.time),
            );
          },
        );
      },
    );
  }
}
```

### 3. Обновление данных

```dart
final controller = AppDataController();

// Обновить все данные (геолокация + времена молитв)
await controller.refreshData();

// Обновить только времена молитв
await controller.refreshPrayerTimes();

// Обновить только геолокацию
await controller.refreshLocation();
```

### 4. Работа с геолокацией

```dart
final controller = AppDataController();

// Проверить разрешения
final hasPermission = await controller.checkLocationPermissions();

// Запросить разрешения
if (!hasPermission) {
  final granted = await controller.requestLocationPermissions();
}

// Открыть настройки геолокации
await controller.openLocationSettings();

// Получить текущую локацию
final location = controller.location;
print('Координаты: ${location?.latitude}, ${location?.longitude}');
```

### 5. Времена молитв

```dart
final controller = AppDataController();

// Получить все молитвы
final prayers = controller.getAllPrayers();

// Получить текущую молитву
final current = controller.getCurrentPrayer();
print('Текущая молитва: ${current?.name} в ${current?.time}');

// Получить следующую молитву
final next = controller.getNextPrayer();

// Получить время до следующей молитвы
final timeUntil = controller.getTimeUntilNextPrayer();
print('До следующей молитвы: ${timeUntil?.inMinutes} минут');

// Форматированное время
final formatted = controller.formatTimeUntilNextPrayer();
print('Осталось: $formatted');

// Прогресс между молитвами (0.0 - 1.0)
final progress = controller.getProgressBetweenPrayers();
```

### 6. Направление Киблы

```dart
final controller = AppDataController();

// Получить направление на Каабу (в градусах)
final qiblaDirection = controller.getQiblaDirection();
print('Направление Киблы: $qiblaDirection°');
```

## API и Сервисы

### LocationService

Работа с GPS и геолокацией:
- `getCurrentLocation()` - получить текущее местоположение
- `checkPermissions()` - проверить разрешения
- `requestPermissions()` - запросить разрешения
- `calculateQiblaDirection()` - рассчитать направление Киблы
- `getLocationStream()` - поток обновлений геолокации

### PrayerTimesService

API для получения времен молитв (Aladhan API):
- `getPrayerTimes(location)` - получить времена на сегодня
- `getMonthlyPrayerTimes(location, year, month)` - на месяц
- `getIslamicCalendar(year)` - исламский календарь

### StorageService

Локальное хранилище (SharedPreferences):
- `saveLocation()` / `getLocation()` - геолокация
- `savePrayerTimes()` / `getPrayerTimes()` - времена молитв
- `saveCalculationMethod()` - метод расчета
- `saveNotificationsEnabled()` - настройки уведомлений

## Кэширование

Система автоматически кэширует данные:
- **Геолокация**: актуальна 24 часа
- **Времена молитв**: обновляются ежедневно
- При отсутствии интернета используются кэшированные данные

## Методы расчета времен молитв

Можно настроить метод расчета (по умолчанию ISNA):

```dart
final storage = StorageService();
await storage.saveCalculationMethod(4); // Umm Al-Qura (Мекка)
```

Доступные методы:
- 1 - University of Islamic Sciences, Karachi
- 2 - Islamic Society of North America (ISNA) ← по умолчанию
- 3 - Muslim World League
- 4 - Umm Al-Qura University, Makkah
- 8 - Gulf Region
- 13 - Turkey (Diyanet)
- 14 - Russia

## Обработка ошибок

```dart
final controller = AppDataController();

if (controller.error != null) {
  print('Ошибка: ${controller.error}');
  
  // Показать пользователю
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(controller.error!)),
  );
}
```

## Пример полного использования

```dart
import 'package:flutter/material.dart';
import 'package:easy_hajj/services/app_data_controller.dart';

class PrayerTimesWidget extends StatefulWidget {
  @override
  State<PrayerTimesWidget> createState() => _PrayerTimesWidgetState();
}

class _PrayerTimesWidgetState extends State<PrayerTimesWidget> {
  final _controller = AppDataController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    setState(() {}); // Обновить UI при изменении данных
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ошибка: ${_controller.error}'),
            ElevatedButton(
              onPressed: () => _controller.refreshData(),
              child: Text('Повторить'),
            ),
          ],
        ),
      );
    }

    final prayers = _controller.getAllPrayers();
    final current = _controller.getCurrentPrayer();

    return Column(
      children: [
        // Текущая молитва
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Следующая молитва',
                    style: Theme.of(context).textTheme.titleLarge),
                Text(current?.name ?? '--',
                    style: Theme.of(context).textTheme.headlineMedium),
                Text(_controller.formatTimeUntilNextPrayer()),
              ],
            ),
          ),
        ),
        
        // Список всех молитв
        Expanded(
          child: ListView.builder(
            itemCount: prayers.length,
            itemBuilder: (context, index) {
              final prayer = prayers[index];
              final isCurrent = prayer.type == current?.type;
              
              return ListTile(
                leading: Icon(
                  Icons.access_time,
                  color: isCurrent ? Colors.teal : null,
                ),
                title: Text(prayer.name),
                trailing: Text(
                  prayer.time,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : null,
                    color: isCurrent ? Colors.teal : null,
                  ),
                ),
              );
            },
          ),
        ),
        
        // Кнопка обновления
        ElevatedButton.icon(
          onPressed: () => _controller.refreshData(),
          icon: Icon(Icons.refresh),
          label: Text('Обновить'),
        ),
      ],
    );
  }
}
```

## Безопасность и производительность

✅ Singleton паттерн для всех сервисов
✅ Автоматическое кэширование
✅ Проверка актуальности данных
✅ Обработка ошибок сети
✅ Таймауты для API запросов
✅ Оптимизация обновлений UI (ChangeNotifier)
✅ Валидация данных

## Настройка разрешений

### Android (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### iOS (`Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Нам нужна ваша геолокация для расчета времен молитв</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Нам нужна ваша геолокация для расчета времен молитв</string>
```

