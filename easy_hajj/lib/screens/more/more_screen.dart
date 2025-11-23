import 'package:flutter/material.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';

/// More Screen - экран настроек и дополнительных опций
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Настройки',
          style: TextStyle(
            color: AppColors.textBlack,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingCard(
            icon: Icons.person_outline,
            title: 'Мой аккаунт',
            onTap: () {},
          ),
          
          const SizedBox(height: 12),
          
          _buildSettingCard(
            icon: Icons.notifications_outlined,
            title: 'Уведомления',
            onTap: () {},
          ),
          
          const SizedBox(height: 12),
          
          _buildSettingCard(
            icon: Icons.access_time,
            title: 'Время молитв',
            onTap: () {},
          ),
          
          const SizedBox(height: 12),
          
          _buildSettingCard(
            icon: Icons.menu_book,
            title: 'Коран',
            onTap: () {},
          ),
          
          const SizedBox(height: 12),
          
          _buildSettingCard(
            icon: Icons.mosque,
            title: 'Дуа',
            onTap: () {},
          ),
          
          const SizedBox(height: 12),
          
          _buildSettingCard(
            icon: Icons.calendar_today,
            title: 'Исламский календарь',
            onTap: () {},
          ),
          
          const SizedBox(height: 12),
          
          _buildSettingCard(
            icon: Icons.location_on_outlined,
            title: 'Геолокация и места',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  /// Карточка настройки
  Widget _buildSettingCard({
    required IconData icon,
    required String title,
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
            Icon(
              icon,
              size: 24,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBlack,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

