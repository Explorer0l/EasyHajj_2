import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/models/islamic_event.dart';
import 'package:easy_hajj/services/islamic_events_service.dart';
import 'package:easy_hajj/services/hijri_date_service.dart';

/// Calendar Screen - экран исламского календаря
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  
  final _eventsService = IslamicEventsService();
  final _hijriService = HijriDateService();
  
  // События загружаются один раз на весь год
  Map<int, List<IslamicEvent>> _yearlyEvents = {};
  List<IslamicEvent> _upcomingEvents = [];
  HijriDate? _currentMonthHijri;
  bool _isLoading = true;
  
  // Выбранное событие для подсветки
  IslamicEvent? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  /// Загрузить исламские события (один раз на год)
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      // Загружаем события на текущий и следующий год (для границы лет)
      final currentYear = _currentMonth.year;
      
      if (!_yearlyEvents.containsKey(currentYear)) {
        print('Загружаем события для года $currentYear');
        final events = await _eventsService.getIslamicEventsForYear(currentYear);
        _yearlyEvents[currentYear] = events;
      }
      
      // Предзагружаем следующий год если близко к концу текущего
      if (_currentMonth.month >= 11 && !_yearlyEvents.containsKey(currentYear + 1)) {
        print('Предзагружаем события для года ${currentYear + 1}');
        final nextYearEvents = await _eventsService.getIslamicEventsForYear(currentYear + 1);
        _yearlyEvents[currentYear + 1] = nextYearEvents;
      }
      
      // Получаем Хиджри дату для первого дня текущего месяца
      final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final hijriDate = await _hijriService.getHijriDate(firstDayOfMonth);
      
      // Фильтруем предстоящие события
      _updateUpcomingEvents();
      
      setState(() {
        _currentMonthHijri = hijriDate;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки исламских событий: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Обновить список предстоящих событий
  void _updateUpcomingEvents() {
    final now = DateTime.now();
    final allEvents = _yearlyEvents.values.expand((e) => e).toList();
    
    _upcomingEvents = allEvents.where((e) => 
      e.gregorianDate.isAfter(now) || 
      (e.gregorianDate.year == now.year && 
       e.gregorianDate.month == now.month && 
       e.gregorianDate.day == now.day)
    ).take(10).toList();
  }

  /// Обновить Хиджри дату при смене месяца
  Future<void> _onMonthChanged() async {
    // Проверяем, нужно ли загрузить события для нового года
    if (!_yearlyEvents.containsKey(_currentMonth.year)) {
      await _loadEvents();
      return;
    }
    
    // Просто обновляем Хиджри дату
    try {
      final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final hijriDate = await _hijriService.getHijriDate(firstDayOfMonth);
      setState(() {
        _currentMonthHijri = hijriDate;
      });
    } catch (e) {
      print('Ошибка получения Хиджри даты: $e');
    }
  }
  
  /// Получить все события загруженных лет
  List<IslamicEvent> get _allEvents {
    return _yearlyEvents.values.expand((e) => e).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.textBlack),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Календарь',
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
              ),
            ),

            // Основной контент
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Карточка календаря
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Заголовок с месяцем и стрелками
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.chevron_left, 
                                        color: AppColors.textSecondary, size: 28),
                                    onPressed: () {
                                      setState(() {
                                        _currentMonth = DateTime(
                                          _currentMonth.year,
                                          _currentMonth.month - 1,
                                        );
                                      });
                                      _onMonthChanged();
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          _getMonthName(_currentMonth.month),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textBlack,
                                          ),
                                        ),
                                        Text(
                                          '${_currentMonth.year}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (_currentMonthHijri != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_currentMonthHijri!.getMonthNameRu()} ${_currentMonthHijri!.year} г.х.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.secondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.chevron_right,
                                        color: AppColors.textSecondary, size: 28),
                                    onPressed: () {
                                      setState(() {
                                        _currentMonth = DateTime(
                                          _currentMonth.year,
                                          _currentMonth.month + 1,
                                        );
                                      });
                                      _onMonthChanged();
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Календарная сетка
                              _buildCalendar(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Заголовок списка событий
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Предстоящие исламские события',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Список исламских событий
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_upcomingEvents.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'События не найдены',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _upcomingEvents.length,
                            itemBuilder: (context, index) {
                              final event = _upcomingEvents[index];
                              final daysUntil = event.gregorianDate.difference(DateTime.now()).inDays;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Иконка события
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: event.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        event.icon,
                                        color: event.color,
                                        size: 24,
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16),
                                    
                                    // Информация о событии
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textBlack,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('d MMMM yyyy', 'ru').format(event.gregorianDate),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          if (event.hijriDate.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              event.hijriDate,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    
                                    // Количество дней до события
                                    if (daysUntil >= 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: event.color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          daysUntil == 0
                                              ? 'Сегодня'
                                              : daysUntil == 1
                                                  ? 'Завтра'
                                                  : '$daysUntil дн.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: event.color,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Построение календарной сетки
  Widget _buildCalendar() {
    // Дни недели
    final weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    // Получаем первый день месяца
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // День недели первого дня (1 = понедельник, 7 = воскресенье)
    int firstWeekday = firstDayOfMonth.weekday;

    // Дни предыдущего месяца
    final previousMonth = DateTime(_currentMonth.year, _currentMonth.month, 0);
    final daysInPreviousMonth = previousMonth.day;

    // Все дни для отображения
    List<Widget> dayWidgets = [];

    // Заголовки дней недели
    for (var day in weekDays) {
      dayWidgets.add(
        Container(
          height: 36,
          alignment: Alignment.center,
          child: Text(
            day,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // Дни предыдущего месяца (серые)
    for (int i = firstWeekday - 1; i > 0; i--) {
      final day = daysInPreviousMonth - i + 1;
      dayWidgets.add(_buildDayCell(day, isCurrentMonth: false));
    }

    // Дни текущего месяца
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      
      // Проверяем, есть ли события в этот день и получаем первое (основное)
      final dayEvents = _allEvents.where((event) =>
        event.gregorianDate.year == date.year &&
        event.gregorianDate.month == date.month &&
        event.gregorianDate.day == date.day
      ).toList();
      
      final hasEvent = dayEvents.isNotEmpty;
      final primaryEvent = dayEvents.isNotEmpty ? dayEvents.first : null;
      
      // Проверяем, выбрано ли событие этого дня
      final isEventSelected = _selectedEvent != null && 
          _selectedEvent!.gregorianDate.year == date.year &&
          _selectedEvent!.gregorianDate.month == date.month &&
          _selectedEvent!.gregorianDate.day == date.day;

      dayWidgets.add(_buildDayCell(
        day,
        isCurrentMonth: true,
        isSelected: isSelected,
        hasEvent: hasEvent,
        event: primaryEvent,
        isEventHighlighted: isEventSelected,
        onTap: () {
          setState(() {
            _selectedDate = date;
            // Если есть событие - выбираем его, иначе сбрасываем
            if (dayEvents.isNotEmpty) {
              _selectedEvent = dayEvents.first;
              _showEventDetailsDialog(dayEvents);
            } else {
              _selectedEvent = null;
            }
          });
        },
      ));
    }

    // Дни следующего месяца (серые)
    final remainingCells = 42 - dayWidgets.length + 7; // +7 для заголовков
    for (int day = 1; day <= remainingCells; day++) {
      dayWidgets.add(_buildDayCell(day, isCurrentMonth: false));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.0,
      children: dayWidgets,
    );
  }

  /// Ячейка дня
  Widget _buildDayCell(
    int day, {
    bool isCurrentMonth = true,
    bool isSelected = false,
    bool hasEvent = false,
    IslamicEvent? event,
    bool isEventHighlighted = false,
    VoidCallback? onTap,
  }) {
    // Определяем цвет ячейки
    Color? backgroundColor;
    Color? borderColor;
    
    if (isEventHighlighted && event != null) {
      // Подсвечиваем фирменным цветом события
      backgroundColor = event.color.withOpacity(0.15);
      borderColor = event.color;
    } else if (isSelected) {
      backgroundColor = Color(0xFF5DBFB3).withOpacity(0.1);
      borderColor = Color(0xFF5DBFB3);
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 16,
                fontWeight: (isSelected || isEventHighlighted) ? FontWeight.bold : FontWeight.normal,
                color: isEventHighlighted && event != null
                    ? event.color
                    : isSelected
                        ? Color(0xFF5DBFB3)
                        : isCurrentMonth
                            ? AppColors.textBlack
                            : AppColors.textSecondary.withOpacity(0.4),
              ),
            ),
            // Индикатор события (точка фирменного цвета)
            if (hasEvent && isCurrentMonth && event != null)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: isEventHighlighted ? 6 : 4,
                height: isEventHighlighted ? 6 : 4,
                decoration: BoxDecoration(
                  color: event.color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Получить название месяца
  String _getMonthName(int month) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return months[month - 1];
  }

  /// Показать диалог с деталями события
  void _showEventDetailsDialog(List<IslamicEvent> events) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
              Row(
                children: [
                  Icon(
                    Icons.event,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      events.length > 1 
                          ? 'События этого дня (${events.length})'
                          : 'Событие',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Список событий
              ...events.map((event) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: event.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: event.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Иконка события
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: event.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        event.icon,
                        color: event.color,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Информация о событии
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: event.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMMM yyyy', 'ru').format(event.gregorianDate),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (event.hijriDate.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              event.hijriDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

