import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  SharedPreferences? _prefs;

  /// Инициализация SharedPreferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

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
    
    // Если нет в кэше - получаем URL
    final urlKey = _getUrlCacheKey(surahNumber, ayahNumber, reciterId);
    String? url = await _getCachedUrl(urlKey);
    
    if (url == null) {
      // Запрашиваем URL из API
      print('🌐 Запрос URL из AlQuran.cloud API...');
      url = await fetchAudioUrlFromApi(surahNumber, ayahNumber, reciterId);
      
      // Кэшируем URL
      await _saveUrlToCache(urlKey, url);
    } else {
      print('💾 URL из кэша');
    }
    
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
    int surahNumber,
    int ayahNumber,
    String reciterId,
  ) async {
    try {
      // Получаем URL через API
      final url = await fetchAudioUrlFromApi(surahNumber, ayahNumber, reciterId);
      
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

  /// Очистить весь кэш аудио файлов
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

  /// Очистить кэш URL (при смене чтеца)
  Future<void> clearUrlCache() async {
    try {
      await _initPrefs();
      final keys = _prefs!.getKeys().where((key) => key.startsWith('audio_url_')).toList();
      
      for (final key in keys) {
        await _prefs!.remove(key);
      }
      
      print('🗑️ Кэш URL очищен (${keys.length} записей)');
    } catch (e) {
      print('❌ Ошибка очистки кэша URL: $e');
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

  /// Получить ключ для кэширования URL
  String _getUrlCacheKey(int surahNumber, int ayahNumber, String reciterId) {
    return 'audio_url_${reciterId}_${surahNumber}_${ayahNumber}';
  }

  /// Получить кэшированный URL
  Future<String?> _getCachedUrl(String key) async {
    await _initPrefs();
    return _prefs!.getString(key);
  }

  /// Сохранить URL в кэш
  Future<void> _saveUrlToCache(String key, String url) async {
    await _initPrefs();
    await _prefs!.setString(key, url);
    print('💾 URL закэширован: $key');
  }

  /// Запросить URL аудио из AlQuran.cloud API
  Future<String> fetchAudioUrlFromApi(
    int surahNumber,
    int ayahNumber,
    String reciterId,
  ) async {
    try {
      final reciter = QuranReciter.getById(reciterId);
      final apiUrl = 'https://api.alquran.cloud/v1/ayah/$surahNumber:$ayahNumber/${reciter.quranComId}';
      
      print('📡 API запрос: $apiUrl');
      
      final response = await _dio.get(apiUrl);
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['code'] == 200 && data['data'] != null) {
          final audioUrl = data['data']['audio'] as String?;
          
          if (audioUrl != null && audioUrl.isNotEmpty) {
            // Очищаем escaped слэши если есть
            final cleanUrl = audioUrl.replaceAll(r'\/', '/');
            print('✅ Получен URL: $cleanUrl');
            return cleanUrl;
          } else {
            throw Exception('URL аудио не найден в ответе API');
          }
        } else {
          throw Exception('API вернул ошибку: ${data['status']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ DioException при запросе к API: ${e.type} - ${e.message}');
      throw Exception('Ошибка сети: ${e.message}');
    } catch (e) {
      print('❌ Ошибка получения URL из API: $e');
      rethrow;
    }
  }
}

