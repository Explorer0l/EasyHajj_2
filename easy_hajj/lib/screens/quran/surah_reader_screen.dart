import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';
import 'package:easy_hajj/models/quran_models.dart';
import 'package:easy_hajj/models/quran_reciter.dart';
import 'package:easy_hajj/services/quran_service.dart';
import 'package:easy_hajj/screens/quran/reciter_settings_screen.dart';

/// Состояния аудио плеера
enum AudioState {
  idle,    // Не играет
  loading, // Загрузка
  playing, // Воспроизведение
  error,   // Ошибка
}

/// Экран чтения суры с постраничным листанием
class SurahReaderScreen extends StatefulWidget {
  final Surah surah;

  const SurahReaderScreen({
    super.key,
    required this.surah,
  });

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  final QuranService _quranService = QuranService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PageController _pageController = PageController();

  int _currentPage = 0;
  AudioState _audioState = AudioState.idle;
  Map<String, bool> _bookmarks = {};
  Map<String, bool> _audioCached = {};
  QuranReciter? _currentReciter;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _loadAudioCache();
    _loadCurrentReciter();
    
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _audioState = AudioState.idle);
      }
    });
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted && state == PlayerState.stopped) {
        setState(() => _audioState = AudioState.idle);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    for (final ayah in widget.surah.ayahs) {
      final isBookmarked = await _quranService.isBookmarked(
        widget.surah.number,
        ayah.number,
      );
      setState(() {
        _bookmarks['${widget.surah.number}_${ayah.number}'] = isBookmarked;
      });
    }
  }

  Future<void> _loadAudioCache() async {
    for (final ayah in widget.surah.ayahs) {
      final isCached = await _quranService.isAudioCached(
        widget.surah.number,
        ayah.number,
      );
      setState(() {
        _audioCached['${widget.surah.number}_${ayah.number}'] = isCached;
      });
    }
  }

  Future<void> _loadCurrentReciter() async {
    final reciter = await _quranService.getCurrentReciter();
    setState(() {
      _currentReciter = reciter;
    });
  }

  Future<void> _toggleBookmark(Ayah ayah) async {
    await _quranService.toggleBookmark(widget.surah.number, ayah.number);
    final isBookmarked = await _quranService.isBookmarked(
      widget.surah.number,
      ayah.number,
    );
    setState(() {
      _bookmarks['${widget.surah.number}_${ayah.number}'] = isBookmarked;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBookmarked ? 'Закладка добавлена' : 'Закладка удалена',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  Future<void> _toggleAudio(Ayah ayah) async {
    if (_audioState == AudioState.playing) {
      await _audioPlayer.stop();
      setState(() => _audioState = AudioState.idle);
      return;
    }

    try {
      setState(() => _audioState = AudioState.loading);
      
      // Получаем путь к аудио (кэш или URL)
      final audioPath = await _quranService.getAudioUrl(
        widget.surah.number,
        ayah.number,
      );
      
      print('🎵 Попытка воспроизведения: $audioPath');
      
      // Определяем тип источника
      final isUrl = audioPath.startsWith('http');
      
      if (isUrl) {
        print('🌐 Стриминг аудио из интернета (чтец: ${_currentReciter?.shortName})');
        // Стриминг
        await _audioPlayer.play(UrlSource(audioPath));
        
        // Кэшируем в фоне после начала воспроизведения
        _quranService.cacheAudio(widget.surah.number, ayah.number).then((cachedPath) {
          if (cachedPath != null) {
            print('✅ Аудио успешно закэшировано');
            // Обновляем статус кэша
            if (mounted) {
              setState(() {
                _audioCached['${widget.surah.number}_${ayah.number}'] = true;
              });
            }
          }
        }).catchError((error) {
          print('⚠️ Не удалось закэшировать аудио: $error');
        });
      } else {
        print('💾 Воспроизведение из локального кэша');
        // Из кэша
        await _audioPlayer.play(DeviceFileSource(audioPath));
      }
      
      setState(() => _audioState = AudioState.playing);
      print('▶️ Воспроизведение началось успешно');
    } catch (e) {
      print('❌ ОШИБКА воспроизведения аудио: $e');
      setState(() => _audioState = AudioState.error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Не удалось воспроизвести аудио.\nПроверьте интернет-соединение.',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Повтор',
              textColor: Colors.white,
              onPressed: () => _toggleAudio(ayah),
            ),
          ),
        );
      }
    }
  }

  void _shareAyah(Ayah ayah) {
    final text = ayah.toShareText(widget.surah.nameRussian, widget.surah.number);
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Сура ${widget.surah.number}: ${widget.surah.nameRussian}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        centerTitle: true,
        actions: [
          // Кнопка выбора чтеца
          IconButton(
            icon: Icon(Icons.person_outline, color: AppColors.textBlack),
            tooltip: 'Выбрать чтеца',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReciterSettingsScreen(),
                ),
              );
              // Если чтец изменился - обновляем
              if (result == true) {
                await _loadCurrentReciter();
                await _loadAudioCache();
              }
            },
          ),
        ],
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
            child: Column(
              children: [
                // PageView с аятами
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.surah.ayahCount,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      // Останавливаем аудио при смене страницы
                      if (_audioState == AudioState.playing) {
                        _audioPlayer.stop();
                        setState(() => _audioState = AudioState.idle);
                      }
                    },
                    itemBuilder: (context, index) {
                      return _buildAyahPage(widget.surah.ayahs[index]);
                    },
                  ),
                ),
                
                // Индикатор страниц
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.surah.ayahCount,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? widget.surah.color
                              : AppColors.inactive,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Страница с аятом
  Widget _buildAyahPage(Ayah ayah) {
    final isBookmarked = _bookmarks['${widget.surah.number}_${ayah.number}'] ?? false;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Бисмиллях для первого аята суры
            if (ayah.number == 1 && widget.surah.number != 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: widget.surah.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Карточка аята
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Арабский текст с Руб-эль-Хизб (۞)
                  Text(
                    ayah.displayArabic,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Номер аята
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.surah.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.surah.color,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Аят ${ayah.number}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.surah.color,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Русский перевод
                  Text(
                    ayah.textRussian,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Кнопки управления
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Аудио с индикаторами
                _buildAudioButton(ayah),
                
                // Закладка
                _buildActionButton(
                  icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  label: 'Закладка',
                  color: AppColors.secondary,
                  onTap: () => _toggleBookmark(ayah),
                ),
                
                // Поделиться
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Поделиться',
                  color: AppColors.primary,
                  onTap: () => _shareAyah(ayah),
                ),
              ],
            ),
            
            // Информация о текущем чтеце
            if (_currentReciter != null) ...[
              const SizedBox(height: 16),
              Text(
                'Чтец: ${_currentReciter!.shortName}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Кнопка аудио с индикаторами
  Widget _buildAudioButton(Ayah ayah) {
    final isCached = _audioCached['${widget.surah.number}_${ayah.number}'] ?? false;
    
    // Определяем иконку и лейбл
    IconData icon;
    String label;
    
    switch (_audioState) {
      case AudioState.loading:
        icon = Icons.hourglass_empty;
        label = 'Загрузка...';
        break;
      case AudioState.playing:
        icon = Icons.stop;
        label = 'Стоп';
        break;
      case AudioState.error:
        icon = Icons.error_outline;
        label = 'Ошибка';
        break;
      case AudioState.idle:
      default:
        icon = Icons.volume_up;
        label = 'Прослушать';
        break;
    }
    
    return InkWell(
      onTap: _audioState == AudioState.loading ? null : () => _toggleAudio(ayah),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.surah.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.surah.color.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: widget.surah.color, size: 24),
                // Индикатор кэша (маленькая зеленая точка)
                if (isCached && _audioState == AudioState.idle)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.surah.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Кнопка действия
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

