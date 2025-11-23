# EasyHajj

Исламское приложение на Flutter.

## Запуск

```bash
cd easy_hajj
flutter pub get
flutter run
```

## Реализовано

✅ 4 Onboarding экрана:
- Splash Screen
- Welcome Screen (выбор входа)
- Location Screen (геолокация)
- Notification Screen (настройка уведомлений)

## Структура

```
lib/
├── main.dart
├── core/
│   ├── theme/app_theme.dart
│   └── constants/app_colors.dart
└── screens/
    └── onboarding/
        ├── splash_screen.dart
        ├── welcome_screen.dart
        ├── location_screen.dart
        └── notification_screen.dart
```
