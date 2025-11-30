import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/services/app_data_controller.dart';
import 'package:easy_hajj/services/prayer_times_service.dart';
import 'package:easy_hajj/models/prayer_times.dart';

/// Prayers Screen - экран времени молитв с вертикальным таймлайном
class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  final _controller = AppDataController();
  final _prayerTimesService = PrayerTimesService();
  
  PrayerType? _selectedPrayerType;
  Timer? _timer;
  
  // Выбранная дата для просмотра времен молитв
  DateTime _selectedDate = DateTime.now();
  
  // Времена молитв для выбранной даты
  PrayerTimes? _selectedDatePrayerTimes;
  
  // Состояние загрузки
  bool _isLoadingDate = false;
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDataChanged);
    // Обновляем индикатор каждую секунду
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }
  
  @override
  void dispose() {
    _controller.removeListener(_onDataChanged);
    _timer?.cancel();
    super.dispose();
  }
  
  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  /// Переключить на предыдущий день
  Future<void> _goToPreviousDay() async {
    final newDate = _selectedDate.subtract(const Duration(days: 1));
    await _loadPrayerTimesForDate(newDate);
  }

  /// Переключить на следующий день
  Future<void> _goToNextDay() async {
    final newDate = _selectedDate.add(const Duration(days: 1));
    await _loadPrayerTimesForDate(newDate);
  }

  /// Вернуться к сегодняшнему дню
  Future<void> _goToToday() async {
    await _loadPrayerTimesForDate(DateTime.now());
  }

  /// Загрузить времена молитв для конкретной даты
  Future<void> _loadPrayerTimesForDate(DateTime date) async {
    if (_controller.location == null) {
      print('❌ Нет местоположения для загрузки времен молитв');
      return;
    }

    setState(() {
      _isLoadingDate = true;
      _selectedDate = date;
    });

    try {
      print('📅 Загрузка времен молитв для даты: ${DateFormat('dd-MM-yyyy').format(date)}');
      
      // Получаем времена молитв на конкретную дату
      final prayerTimes = await _prayerTimesService.getPrayerTimesForDate(
        _controller.location!,
        date,
      );

      if (prayerTimes != null) {
        setState(() {
          _selectedDatePrayerTimes = prayerTimes;
          _isLoadingDate = false;
        });
        print('✅ Времена молитв загружены для ${DateFormat('dd-MM-yyyy').format(date)}');
      } else {
        throw Exception('Не удалось получить времена молитв');
      }
    } catch (e) {
      print('❌ Ошибка загрузки времен молитв: $e');
      setState(() {
        _isLoadingDate = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось загрузить времена молитв для этой даты'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Получить времена молитв для отображения (выбранная дата или текущая)
  PrayerTimes? _getDisplayedPrayerTimes() {
    // Если выбрана сегодняшняя дата, показываем данные из контроллера
    if (_isSameDay(_selectedDate, DateTime.now())) {
      return _controller.prayerTimes;
    }
    // Иначе показываем загруженные времена для выбранной даты
    return _selectedDatePrayerTimes;
  }

  /// Проверить, совпадают ли две даты (год, месяц, день)
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Получить список молитв для отображения
  List<Prayer> _getDisplayedPrayers() {
    final prayerTimes = _getDisplayedPrayerTimes();
    if (prayerTimes == null) return [];
    
    return [
      Prayer(
        type: PrayerType.fajr,
        name: 'Фаджр',
        nameEn: 'Fajr',
        time: prayerTimes.fajr,
      ),
      Prayer(
        type: PrayerType.sunrise,
        name: 'Восход',
        nameEn: 'Sunrise',
        time: prayerTimes.sunrise,
      ),
      Prayer(
        type: PrayerType.dhuhr,
        name: 'Зухр',
        nameEn: 'Dhuhr',
        time: prayerTimes.dhuhr,
      ),
      Prayer(
        type: PrayerType.asr,
        name: 'Аср',
        nameEn: 'Asr',
        time: prayerTimes.asr,
      ),
      Prayer(
        type: PrayerType.maghrib,
        name: 'Магриб',
        nameEn: 'Maghrib',
        time: prayerTimes.maghrib,
      ),
      Prayer(
        type: PrayerType.isha,
        name: 'Иша',
        nameEn: 'Isha',
        time: prayerTimes.isha,
      ),
    ];
  }

  // Цвета градиента для вертикальной шкалы
  final List<Color> _gradientColors = [
    Color(0xFF7C4DFF), // Фаджр - фиолетовый
    Color(0xFFD770FF), // Шурук - розово-пурпурный
    Color(0xFFFAD765), // Зухр - жёлтый
    Color(0xFFF5A623), // Аср - оранжево-жёлтый
    Color(0xFFF55D3E), // Магриб - оранжево-красный
    Color(0xFFE8532F), // Иша - красно-оранжевый
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // AppBar
                Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Пустое место вместо кнопки назад
                  Text(
                    'Молитвы',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Карточка с датой и градиентом
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFFDB954), // Желтый
                      Color(0xFF5DBFB3), // Бирюзовый
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Кнопка предыдущий день
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: AppColors.backgroundWhite, size: 28),
                      onPressed: _isLoadingDate ? null : _goToPreviousDay,
                    ),
                    
                    // Дата с возможностью вернуться к "сегодня"
                    GestureDetector(
                      onTap: _isSameDay(_selectedDate, DateTime.now()) ? null : _goToToday,
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('EEEE, d MMMM', 'ru').format(_selectedDate),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.backgroundWhite,
                                ),
                              ),
                              if (!_isSameDay(_selectedDate, DateTime.now())) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundWhite.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Сегодня',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.backgroundWhite,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _controller.location?.city ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.backgroundWhite.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Кнопка следующий день
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: AppColors.backgroundWhite, size: 28),
                      onPressed: _isLoadingDate ? null : _goToNextDay,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Таймлайн с молитвами
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  // Отступы сверху и снизу для ListView
                  final topPadding = 0.0;
                  final bottomPadding = 16.0;
                  // Расчет высоты одного элемента с учетом отступов
                  final itemHeight = 66.0; // высота карточки
                  final itemSpacing = 12.0; // отступ между карточками
                  final totalItemHeight = itemHeight + itemSpacing;
                  
                  final displayedPrayers = _getDisplayedPrayers();
                  final prayersCount = displayedPrayers.length;
                  
                  // Общая высота контента списка
                  final contentHeight = (prayersCount * totalItemHeight) - itemSpacing + topPadding + bottomPadding;
                  
                  // Высота таймлайна - минимум из доступной высоты или высоты контента
                  final timelineHeight = contentHeight < availableHeight ? contentHeight - bottomPadding : availableHeight - bottomPadding;
                  
                  // Позиция первой точки (центр первой карточки)
                  final firstDotPosition = topPadding + (itemHeight / 2);
                  // Позиция последней точки (центр последней карточки)
                  final lastDotPosition = topPadding + ((prayersCount - 1) * totalItemHeight) + (itemHeight / 2);
                  // Высота между первой и последней точкой
                  final dotsRangeHeight = lastDotPosition - firstDotPosition;
                  
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Вертикальная цветная шкала слева
                      SizedBox(
                        width: 24,
                        height: availableHeight,
                        child: Stack(
                          children: [
                            // Градиентная шкала с отступами и закругленными краями
                            Positioned(
                              top: firstDotPosition - 24, // Увеличенный отступ выше первой точки
                              left: 0,
                              height: dotsRangeHeight + 48, // Высота между точками + увеличенные отступы (24px сверху + 24px снизу)
                              child: Container(
                                width: 24,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: _gradientColors,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            
                            // Точки молитв на шкале
                            ...displayedPrayers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final prayer = entry.value;
                              final topPosition = firstDotPosition + (index * totalItemHeight);
                              final prayerColor = _getPrayerColor(prayer.type);
                              
                              return Positioned(
                                left: 6,
                                top: topPosition - 6,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundWhite,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: prayerColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            
                            // Индикатор текущего времени (только для сегодняшнего дня)
                            if (_controller.hasData && _isSameDay(_selectedDate, DateTime.now()))
                              Builder(
                                builder: (context) {
                                  final currentProgress = _controller.getProgressBetweenPrayers();
                                  final currentPosition = firstDotPosition + (dotsRangeHeight * currentProgress);
                                  
                                  return Positioned(
                                    left: 3,
                                    top: currentPosition - 9,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF00BFA5),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.backgroundWhite,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF00BFA5).withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),

                      // Список карточек молитв
                      Expanded(
                        child: _isLoadingDate
                            ? const Center(child: CircularProgressIndicator())
                            : displayedPrayers.isNotEmpty
                                ? ListView.builder(
                                    padding: EdgeInsets.only(
                                      left: 12,
                                      right: 16,
                                      top: topPadding,
                                      bottom: bottomPadding,
                                    ),
                                    itemCount: displayedPrayers.length,
                                    itemBuilder: (context, index) {
                                      final prayer = displayedPrayers[index];
                                      final isCurrent = _selectedPrayerType == prayer.type;
                                      final notificationOn = true;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedPrayerType = prayer.type;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      height: 66,
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? Color(0xFF4CBEB4)
                                            : AppColors.backgroundWhite,
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 12,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            prayer.name,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: isCurrent
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: isCurrent
                                                  ? AppColors.backgroundWhite
                                                  : Color(0xFF4A4A4A),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                prayer.time,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: isCurrent
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: isCurrent
                                                      ? AppColors.backgroundWhite
                                                      : Color(0xFF4A4A4A),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(
                                                notificationOn
                                                    ? Icons.check_circle_outline
                                                    : Icons.notifications_off_outlined,
                                                color: isCurrent
                                                    ? AppColors.backgroundWhite
                                                    : Color(0xFFC0C0C0),
                                                size: 26,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                    },
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 64,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Нет данных о молитвах',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ],
                  );
                },
              ),
            ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Получить цвет для молитвы
  Color _getPrayerColor(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return Color(0xFFB588FF);
      case PrayerType.sunrise:
        return Color(0xFFE4A7FF);
      case PrayerType.dhuhr:
        return Color(0xFFFAD765);
      case PrayerType.asr:
        return Color(0xFFFFC864);
      case PrayerType.maghrib:
        return Color(0xFFFF8650);
      case PrayerType.isha:
        return Color(0xFFFFA56C);
    }
  }
}
