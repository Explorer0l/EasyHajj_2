import 'package:flutter/material.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/services/storage_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:easy_hajj/screens/main_screen.dart';

/// Notification Screen - экран настройки уведомлений для молитв
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _storage = StorageService();
  
  // Состояние переключателей для каждой молитвы (все включены по умолчанию)
  final Map<String, bool> _prayerNotifications = {
    'Фаджр': true,
    'Зухр': true,
    'Аср': true,
    'Магриб': true,
    'Иша': true,
  };

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSavedNotifications();
  }

  /// Загрузить сохраненные настройки уведомлений
  Future<void> _loadSavedNotifications() async {
    final notifications = await _storage.getAllPrayerNotifications();
    setState(() {
      _prayerNotifications.addAll(notifications);
    });
  }

  /// Инициализация уведомлений
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  /// Запрос разрешения на уведомления
  Future<void> _requestNotificationPermission() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    // Для iOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Включить уведомления
  Future<void> _enableNotifications() async {
    await _requestNotificationPermission();
    
    // Сохранение настроек через StorageService
    await _storage.saveNotificationsEnabled(true);
    
    // Сохраняем настройки для каждой молитвы
    for (var entry in _prayerNotifications.entries) {
      await _storage.savePrayerNotification(entry.key, entry.value);
    }

    // Переход на главный экран
    if (mounted) {
      _showCompletionDialog();
    }
  }

  /// Пропустить уведомления
  Future<void> _skipNotifications() async {
    // Отключаем глобальные уведомления
    await _storage.saveNotificationsEnabled(false);
    
    // Но сохраняем выбранные настройки для молитв (на случай если пользователь потом включит)
    for (var entry in _prayerNotifications.entries) {
      await _storage.savePrayerNotification(entry.key, entry.value);
    }
    
    if (mounted) {
      _showCompletionDialog();
    }
  }

  /// Показать диалог завершения onboarding
  void _showCompletionDialog() {
    // Переход на главный экран
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Заголовок
              Text(
                'Включить уведомления для каждой молитвы',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Иллюстрация уведомлений
              Image.asset(
                'assets/images/your_notification_image.png',
                width: 240,
                height: 200,
                fit: BoxFit.contain,
              ),
              
              const SizedBox(height: 40),
              
              // Список молитв с переключателями
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView(
                    children: _prayerNotifications.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textBlack,
                              ),
                            ),
                            Switch(
                              value: entry.value,
                              onChanged: (value) {
                                setState(() {
                                  _prayerNotifications[entry.key] = value;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Кнопка "Включить уведомления"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enableNotifications,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Включить уведомления',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Кнопка "Пропустить"
              TextButton(
                onPressed: _skipNotifications,
                child: Text(
                  'Пропустить',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
