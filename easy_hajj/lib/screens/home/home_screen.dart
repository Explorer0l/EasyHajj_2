import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/screens/dua/dua_screen.dart';
import 'package:easy_hajj/screens/calendar/calendar_screen.dart';
import 'package:easy_hajj/services/app_data_controller.dart';
import 'package:easy_hajj/models/prayer_times.dart';

/// Home Screen - главный экран "Сегодня"
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = AppDataController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Обновляем UI каждую секунду для таймера
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Фиксированный фон с градиентом
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF), // Чисто белый
                    Color(0xFFF6F6F6), // Светло-серый
                  ],
                ),
              ),
            ),
          ),
          
          // Силуэт мечети (фиксированный фон)
          Positioned.fill(
            child: Opacity(
              opacity: 0.03, // Очень прозрачный (3%)
              child: Image.asset(
                'assets/images/mosque_silhouette.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(); // Если изображения нет - ничего не показываем
                },
              ),
            ),
          ),
          
          // Скроллируемый контент поверх фона
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, child) {
                    if (_controller.isLoading && !_controller.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                // Верхняя часть с датой
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM', 'ru').format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Сейчас: ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBlack,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(_controller.isLoading ? Icons.refresh : Icons.more_vert, 
                          color: AppColors.textSecondary),
                      onPressed: () => _controller.refreshData(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Большие цифры текущей молитвы
                _buildNextPrayerDisplay(),
                
                const SizedBox(height: 32),
                
                // Полоса времени молитв
                if (_controller.hasData) _buildPrayerTimeline(),
                
                const SizedBox(height: 32),
                
                // Карточки навигации
                _buildNavigationCard(
                  context,
                  icon: Icons.mosque,
                  title: 'Дуа',
                  color: const Color(0xFFFDB954),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DuaScreen()),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                
                _buildNavigationCard(
                  context,
                  icon: Icons.menu_book,
                  title: 'Мотивация',
                  color: const Color(0xFF5B7FFF),
                  onTap: () {},
                ),
                
                const SizedBox(height: 12),
                
                _buildNavigationCard(
                  context,
                  icon: Icons.people,
                  title: 'Сообщество',
                  color: const Color(0xFF9B59B6),
                  onTap: () {},
                ),
                
                const SizedBox(height: 12),
                
                _buildNavigationCard(
                  context,
                  icon: Icons.calendar_month,
                  title: 'Календарь',
                  color: const Color(0xFFE74C3C),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Аят дня
                _buildAyatCard(),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Отображение следующей молитвы
  Widget _buildNextPrayerDisplay() {
    final nextPrayer = _controller.getNextPrayer();
    
    if (nextPrayer == null) {
      return Text(
        'Загрузка...',
        style: TextStyle(
          fontSize: 24,
          color: AppColors.textSecondary,
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Время следующей молитвы
        Text(
          nextPrayer.time,
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w300,
            color: AppColors.secondary,
            height: 1,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 8),
        // Обратный отсчет и название
        Row(
          children: [
            Text(
              _controller.formatTimeUntilNextPrayer(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                nextPrayer.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Полоса времени молитв
  Widget _buildPrayerTimeline() {
    final prayers = _controller.getAllPrayers();
    
    // Рассчитываем прогресс для отображаемых молитв
    final currentTimeProgress = _calculateTimelineProgress(prayers);

    return Column(
      children: [
        // Времена (выровнены по центру точек)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: prayers.map((prayer) {
            return SizedBox(
              width: 50,
              child: Text(
                prayer.time,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 8),
        
        // Полоса прогресса
        LayoutBuilder(
          builder: (context, constraints) {
            final timelineWidth = constraints.maxWidth;
            // Рассчитываем позицию с учетом того, что точки в контейнерах 50px
            // Первая точка: 25px, последняя точка: (width - 25px)
            // Расстояние между ними: width - 50px
            final firstPointCenter = 25.0;
            final travelDistance = timelineWidth - 50;
            final currentPosition = firstPointCenter + (travelDistance * currentTimeProgress);
            
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Градиентная полоса
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary,
                        const Color(0xFFFDB954),
                        const Color(0xFFFF8C42),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                // Точки молитв (выровнены по центру)
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: prayers.map((prayer) {
                      final now = DateTime.now();
                      final parts = prayer.time.split(':');
                      final prayerTime = DateTime(now.year, now.month, now.day, 
                          int.parse(parts[0]), int.parse(parts[1]));
                      final isActive = now.isBefore(prayerTime);
                      
                      return SizedBox(
                        width: 50,
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive ? AppColors.secondary : const Color(0xFFFF8C42),
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                // Текущая позиция времени (размытая точка внутри таймлайна)
                Positioned(
                  left: currentPosition - 6,
                  top: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.backgroundWhite.withOpacity(0.9),
                      border: Border.all(
                        color: AppColors.backgroundWhite,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.backgroundWhite.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        
        const SizedBox(height: 8),
        
        // Названия молитв (выровнены по центру точек)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: prayers.map((prayer) {
            return SizedBox(
              width: 50,
              child: Text(
                prayer.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Рассчитать прогресс на таймлайне только для отображаемых молитв
  double _calculateTimelineProgress(List<Prayer> prayers) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    
    if (prayers.isEmpty) return 0.0;
    
    // Конвертируем все времена в минуты
    final prayerMinutes = prayers.map((p) {
      final parts = p.time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }).toList();
    
    // Находим текущий сегмент
    int currentSegment = 0;
    for (int i = 0; i < prayerMinutes.length; i++) {
      if (currentMinutes < prayerMinutes[i]) {
        currentSegment = i;
        break;
      }
      if (i == prayerMinutes.length - 1) {
        return 1.0; // После последней молитвы
      }
    }
    
    if (currentSegment == 0) {
      return 0.0; // До первой молитвы
    }
    
    // Прогресс в текущем сегменте
    final previousMinutes = prayerMinutes[currentSegment - 1];
    final nextMinutes = prayerMinutes[currentSegment];
    
    final segmentDuration = nextMinutes - previousMinutes;
    final elapsed = currentMinutes - previousMinutes;
    
    if (segmentDuration <= 0) return 0.0;
    
    final segmentProgress = (elapsed / segmentDuration).clamp(0.0, 1.0);
    
    // Общий прогресс
    final segmentWeight = 1.0 / (prayers.length - 1);
    final baseProgress = (currentSegment - 1) * segmentWeight;
    
    return (baseProgress + (segmentProgress * segmentWeight)).clamp(0.0, 1.0);
  }

  /// Карточка навигации с цветной подложкой
  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Цветная подложка (фон)
          Container(
            height: 68,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          // Основная белая карточка (смещена вправо)
          Positioned(
            left: 10,
            top: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Карточка "Аят дня"
  Widget _buildAyatCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary,
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Аят дня',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.backgroundWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Св. Коран, 26:3',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.backgroundWhite.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Не стоит мучить себя, до смерти переживать, беспокоясь, что не уверуют (не убивайся над тем, что некоторые не становятся верующими)',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.backgroundWhite,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.backgroundWhite,
                ),
                child: const Text('Читать'),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.backgroundWhite,
                ),
                child: const Text('Поделиться'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

