import 'package:flutter/material.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/screens/dua/dua_screen.dart';

/// Home Screen - главный экран "Сегодня"
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            child: SingleChildScrollView(
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
                          'Четверг, 14 января',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textBlack,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '1 джумад-уль-ахир 1442 г. АН',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
                      onPressed: () {},
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Большие цифры текущей молитвы
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '17:32',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        color: AppColors.secondary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '-1:15:50',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Магриб',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textBlack,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Полоса времени молитв
                _buildPrayerTimeline(),
                
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
                  onTap: () {},
                ),
                
                const SizedBox(height: 24),
                
                // Аят дня
                _buildAyatCard(),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ],
      ),
    );
  }

  /// Полоса времени молитв
  Widget _buildPrayerTimeline() {
    final prayers = [
      {'time': '05:25', 'name': 'Фаджр', 'progress': 0.0},
      {'time': '13:20', 'name': 'Зухр', 'progress': 0.3},
      {'time': '16:00', 'name': 'Аср', 'progress': 0.6},
      {'time': '18:10', 'name': 'Магриб', 'progress': 0.85},
      {'time': '21:30', 'name': 'Иша', 'progress': 1.0},
    ];

    // Текущая позиция (расчет на основе времени 17:32)
    // Между Аср (16:00) и Магриб (18:10) = 130 минут
    // Прошло с 16:00: 1 час 32 минуты = 92 минуты
    // Процент: 92/130 = 0.707
    // Позиция на таймлайне: между 0.6 (Аср) и 0.85 (Магриб)
    // 0.6 + (0.85 - 0.6) * 0.707 = 0.777
    final currentTimeProgress = 0.777;

    return Column(
      children: [
        // Времена (выровнены по центру точек)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: prayers.map((prayer) {
            return SizedBox(
              width: 50,
              child: Text(
                prayer['time'] as String,
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
                      final isActive = (prayer['progress'] as double) <= 0.85;
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
                
                // Текущая позиция времени (прозрачная точка с белой обводкой)
                Positioned(
                  left: currentPosition - 8,
                  top: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundWhite,
                        width: 3,
                      ),
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
                prayer['name'] as String,
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

  /// Карточка навигации
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
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
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

