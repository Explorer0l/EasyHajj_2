import 'package:flutter/material.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/models/quran_models.dart';
import 'package:easy_hajj/services/quran_service.dart';
import 'package:easy_hajj/screens/quran/surah_reader_screen.dart';

/// Экран списка сур Корана
class QuranListScreen extends StatefulWidget {
  const QuranListScreen({super.key});

  @override
  State<QuranListScreen> createState() => _QuranListScreenState();
}

class _QuranListScreenState extends State<QuranListScreen> {
  final QuranService _quranService = QuranService();
  List<Surah> _surahs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    setState(() => _isLoading = true);
    try {
      final surahs = await _quranService.loadSurahs();
      setState(() {
        _surahs = surahs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Фиксированный фон с градиентом
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF6F6F6),
                  ],
                ),
              ),
            ),
          ),
          
          // Силуэт мечети на фоне
          Positioned.fill(
            child: Opacity(
              opacity: 0.02,
              child: Image.asset(
                'assets/images/mosque_silhouette.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
          
          // Контент
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    // AppBar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                      child: Row(
                        children: [
                          Text(
                            'Коран',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Список сур
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppColors.secondary,
                              ),
                            )
                          : _surahs.isEmpty
                              ? Center(
                                  child: Text(
                                    'Нет доступных сур',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                  ),
                                  itemCount: _surahs.length,
                                  itemBuilder: (context, index) {
                                    return _buildSurahCard(_surahs[index]);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Карточка суры с фирменным 3D дизайном
  Widget _buildSurahCard(Surah surah) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SurahReaderScreen(surah: surah),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 94,
          child: Stack(
            children: [
              // Цветная полоска (фон)
              Container(
                decoration: BoxDecoration(
                  color: surah.color,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // Белая карточка (смещена вправо)
              Positioned(
                left: 10,
                top: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Номер в круге
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: surah.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: surah.color,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${surah.number}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: surah.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Информация о суре
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Арабское название
                            Text(
                              surah.nameArabic,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBlack,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            // Русское название и значение
                            Text(
                              surah.fullName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            // Информация
                            Row(
                              children: [
                                Text(
                                  surah.ayahInfo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  surah.revelation,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Стрелка
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

