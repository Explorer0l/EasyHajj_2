import 'package:flutter/material.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';

/// Dua Screen - экран с категориями дуа
class DuaScreen extends StatelessWidget {
  const DuaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final duaCategories = [
      {
        'title': 'Все',
        'count': '20 глав',
        'image': 'assets/images/dua_all.jpg',
      },
      {
        'title': 'Утро\nВечер',
        'count': '6 глав',
        'image': 'assets/images/dua_morning.jpg',
      },
      {
        'title': 'Дом и\nСемья',
        'count': '14 глав',
        'image': 'assets/images/dua_home.jpg',
      },
      {
        'title': 'Еда и\nнапитки',
        'count': '7 глав',
        'image': 'assets/images/dua_food.jpg',
      },
      {
        'title': 'Радость и\nгоре',
        'count': '15 глав',
        'image': 'assets/images/dua_joy.jpg',
      },
      {
        'title': 'Путешествие',
        'count': '11 глав',
        'image': 'assets/images/dua_travel.jpg',
      },
    ];

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
          'Дуа',
          style: TextStyle(
            color: AppColors.textBlack,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: duaCategories.length,
          itemBuilder: (context, index) {
            final category = duaCategories[index];
            return _buildDuaCard(
              title: category['title']!,
              count: category['count']!,
              imagePath: category['image']!,
            );
          },
        ),
      ),
    );
  }

  /// Карточка категории дуа
  Widget _buildDuaCard({
    required String title,
    required String count,
    required String imagePath,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Изображение
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              height: 120,
              width: double.infinity,
              color: AppColors.background,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.secondary.withOpacity(0.1),
                    child: Icon(
                      Icons.image,
                      size: 48,
                      color: AppColors.secondary.withOpacity(0.3),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Текст
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

