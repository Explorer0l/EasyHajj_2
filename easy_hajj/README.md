# EasyHajj

Исламское приложение на Flutter.

## Запуск

```bash
cd easy_hajj
flutter pub get
flutter run
```

## Реализовано

✅ **4 Onboarding экрана:**
- Splash Screen - логотип приложения
- Welcome Screen - выбор способа входа
- Location Screen - запрос геолокации
- Notification Screen - настройка уведомлений для молитв

✅ **5 Основных экранов:**
- **Сегодня** - главный экран с временем молитв, аятом дня и навигацией
- **Коран** - (Home Screen пока)
- **Молитвы** - список времени всех молитв
- **Кибла** - компас направления на Мекку
- **Прочее** - настройки и дополнительные опции

✅ **Дополнительные экраны:**
- **Дуа** - сетка категорий дуа (2x3)

✅ **Компоненты:**
- Bottom Navigation Bar (5 вкладок)
- Полоса прогресса времени молитв
- Карточка "Аят дня" с градиентом
- Навигационные карточки с цветными полосками

## Структура

```
lib/
├── main.dart
├── core/
│   ├── theme/app_theme.dart
│   └── constants/app_colors.dart
└── screens/
    ├── main_screen.dart                  # Bottom Navigation
    ├── onboarding/
    │   ├── splash_screen.dart
    │   ├── welcome_screen.dart
    │   ├── location_screen.dart
    │   └── notification_screen.dart
    ├── home/
    │   └── home_screen.dart              # Главный экран "Сегодня"
    ├── dua/
    │   └── dua_screen.dart               # Экран "Дуа"
    ├── prayers/
    │   └── prayers_screen.dart           # Экран "Молитвы"
    ├── qibla/
    │   └── qibla_screen.dart             # Экран "Кибла"
    └── more/
        └── more_screen.dart              # Экран "Настройки"
```
