import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:easy_hajj/models/quran_reciter.dart';

/// Сервис для кэширования аудио файлов Корана
class AudioCacheService {
  static final AudioCacheService _instance = AudioCacheService._internal();
  factory AudioCacheService() => _instance;
  AudioCacheService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status! < 500,
    ),
  );
  
  String? _cacheDir;

  /// Инициализация - получить путь к директории кэша
  Future<String> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = '${appDir.path}/audio_cache';
    
    // Создаем директорию если её нет
    final dir = Directory(_cacheDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return _cacheDir!;
  }

  /// Получить путь к аудио файлу (локальный или URL)
  Future<String> getAudioPath(
    int surahNumber,
    int ayahNumber,
    String reciterId,
  ) async {
    // Проверяем, есть ли файл в кэше
    final cachedPath = await _getCachedFilePath(surahNumber, ayahNumber, reciterId);
    final file = File(cachedPath);
    
    if (await file.exists()) {
      print('🎵 Аудио из кэша: $cachedPath');
      return cachedPath;
    }
    
    // Если нет в кэше - возвращаем URL для стриминга
    final url = _buildAudioUrl(reciterId, surahNumber, ayahNumber);
    print('🎵 Аудио стриминг: $url');
    return url;
  }

  /// Проверить, есть ли аудио в кэше
  Future<bool> isCached(
    int surahNumber,
    int ayahNumber,
    String reciterId,
  ) async {
    final cachedPath = await _getCachedFilePath(surahNumber, ayahNumber, reciterId);
    return await File(cachedPath).exists();
  }

  /// Скачать и закэшировать аудио файл
  Future<String?> downloadAndCache(
    String url,
    int surahNumber,
    int ayahNumber,
    String reciterId,
  ) async {
    try {
      print('⬇️ Скачивание аудио: $url');
      
      final cachedPath = await _getCachedFilePath(surahNumber, ayahNumber, reciterId);
      
      // Скачиваем с прогрессом через Dio
      await _dio.download(
        url,
        cachedPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('📥 Прогресс: $progress%');
          }
        },
      );
      
      final file = File(cachedPath);
      final sizeKB = (await file.length() / 1024).toStringAsFixed(1);
      print('✅ Аудио закэшировано: $cachedPath ($sizeKB KB)');
      return cachedPath;
    } on DioException catch (e) {
      print('❌ DioException: ${e.type} - ${e.message}');
      if (e.response != null) {
        print('   HTTP ${e.response?.statusCode}: ${e.response?.statusMessage}');
      }
      return null;
    } catch (e) {
      print('❌ Ошибка кэширования аудио: $e');
      return null;
    }
  }

  /// Очистить весь кэш
  Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      final dir = Directory(cacheDir);
      
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
        print('🗑️ Кэш аудио очищен');
      }
    } catch (e) {
      print('❌ Ошибка очистки кэша: $e');
    }
  }

  /// Получить размер кэша в байтах
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      final dir = Directory(cacheDir);
      
      if (!await dir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      print('❌ Ошибка получения размера кэша: $e');
      return 0;
    }
  }

  /// Получить размер кэша в МБ (для UI)
  Future<String> getCacheSizeMB() async {
    final bytes = await getCacheSize();
    final mb = bytes / (1024 * 1024);
    return mb.toStringAsFixed(1);
  }

  /// Получить путь к закэшированному файлу
  Future<String> _getCachedFilePath(
    int surahNumber,
    int ayahNumber,
    String reciterId,
  ) async {
    final cacheDir = await _getCacheDirectory();
    return '$cacheDir/${reciterId}_${surahNumber}_${ayahNumber}.mp3';
  }

  /// Построить URL для аудио API (Islamic Network CDN)
  String _buildAudioUrl(String reciterId, int surahNumber, int ayahNumber) {
    final reciter = QuranReciter.getById(reciterId);
    
    // Islamic Network CDN: формат {surah}{ayah}.mp3
    // Пример: 1121.mp3 = сура 112, аят 1
    final audioId = '$surahNumber$ayahNumber';
    
    return 'https://cdn.islamic.network/quran/audio/128/${reciter.quranComId}/$audioId.mp3';
  }
}

