import 'package:flutter/material.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/screens/home/home_screen.dart';
import 'package:easy_hajj/screens/prayers/prayers_screen.dart';
import 'package:easy_hajj/screens/qibla/qibla_screen.dart';
import 'package:easy_hajj/screens/more/more_screen.dart';

/// Main Screen - главный экран с bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),      // Коран (пока Home)
    const HomeScreen(),      // Сегодня
    const PrayersScreen(),   // Молитвы
    const QiblaScreen(),     // Кибла
    const MoreScreen(),      // Прочее
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.backgroundWhite,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.inactive,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'Коран',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Сегодня',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time),
              label: 'Молитвы',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Кибла',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'Прочее',
            ),
          ],
        ),
      ),
    );
  }
}

