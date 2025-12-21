import 'package:flutter/material.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/models/quran_reciter.dart';
import 'package:easy_hajj/services/quran_service.dart';

/// Экран выбора чтеца Корана
class ReciterSettingsScreen extends StatefulWidget {
  const ReciterSettingsScreen({super.key});

  @override
  State<ReciterSettingsScreen> createState() => _ReciterSettingsScreenState();
}

class _ReciterSettingsScreenState extends State<ReciterSettingsScreen> {
  final QuranService _quranService = QuranService();
  String? _selectedReciterId;
  String _cacheSize = '0.0';

  @override
  void initState() {
    super.initState();
    _loadCurrentReciter();
    _loadCacheSize();
  }

  Future<void> _loadCurrentReciter() async {
    final reciter = await _quranService.getCurrentReciter();
    setState(() {
      _selectedReciterId = reciter.id;
    });
  }

  Future<void> _loadCacheSize() async {
    final size = await _quranService.getAudioCacheSize();
    setState(() {
      _cacheSize = size;
    });
  }

  Future<void> _selectReciter(QuranReciter reciter) async {
    await _quranService.setReciter(reciter.id);
    setState(() {
      _selectedReciterId = reciter.id;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Выбран чтец: ${reciter.nameRussian}'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить кэш?'),
        content: Text('Будет удалено $_cacheSize МБ закэшированных аудио файлов'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _quranService.clearAudioCache();
              await _loadCacheSize();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Кэш аудио очищен'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
            child: Text('Очистить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          'Выбор чтеца',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textBlack,
          ),
        ),
        centerTitle: true,
      ),
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Описание
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Выберите чтеца для прослушивания Корана',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Список чтецов
                ...QuranReciter.getAll().map((reciter) {
                  return _buildReciterCard(reciter);
                }),
                
                const SizedBox(height: 24),
                
                // Информация о кэше
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Кэш аудио',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_cacheSize МБ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _clearCache,
                        icon: Icon(Icons.delete_outline, size: 18),
                        label: const Text('Очистить'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Карточка чтеца
  Widget _buildReciterCard(QuranReciter reciter) {
    final isSelected = _selectedReciterId == reciter.id;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectReciter(reciter),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.secondary.withOpacity(0.1)
                : AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? AppColors.secondary
                  : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ] : [],
          ),
          child: Row(
            children: [
              // Иконка чтеца
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.secondary
                      : AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: isSelected 
                      ? AppColors.backgroundWhite
                      : AppColors.secondary,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Информация о чтеце
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Арабское имя
                    Text(
                      reciter.nameArabic,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Русское имя
                    Text(
                      reciter.nameRussian,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Описание
                    Text(
                      '${reciter.country} • ${reciter.description}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Индикатор выбора
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.secondary,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

