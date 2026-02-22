import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_hajj/models/quran_models.dart';
import 'package:easy_hajj/models/quran_reciter.dart';
import 'package:easy_hajj/database/quran_database.dart';
import 'package:easy_hajj/database/models/surah_entity.dart';
import 'package:easy_hajj/database/models/ayah_entity.dart';
import 'package:easy_hajj/database/models/translation_entity.dart';
import 'package:easy_hajj/services/quran_api_service.dart';
import 'package:easy_hajj/services/storage_service.dart';
import 'package:easy_hajj/services/audio_cache_service.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';

/// Сервис для работы с Кораном через SQLite + API
class QuranService {
  static final QuranService _instance = QuranService._internal();
  factory QuranService() => _instance;
  QuranService._internal();

  final QuranDatabase _database = QuranDatabase();
  final QuranApiService _apiService = QuranApiService();
  final StorageService _storageService = StorageService();
  final AudioCacheService _audioCacheService = AudioCacheService();
  
  // Кэш в памяти для быстрого доступа
  final Map<int, Surah> _memoryCache = {};
  String? _selectedReciterId;
  String _currentLanguage = 'ru'; // Текущий язык перевода

  // Фирменные цвета для сур
  static const List<Color> _surahColors = [
    AppColors.primary,    // Фиолетовый
    AppColors.secondary,  // Бирюзовый
    Color(0xFFFDB954),    // Желтый/оранжевый
  ];

  /// Инициализация сервиса
  Future<void> initialize() async {
    await _storageService.init();
    _currentLanguage = await _storageService.getString('selected_language') ?? 'ru';
    print('📚 QuranService инициализирован (язык: $_currentLanguage)');
  }

  // ==================== ЗАГРУЗКА СУР ====================

  /// Загрузить все суры (ВРЕМЕННО: используем JSON с 3 сурами)
  Future<List<Surah>> loadSurahs() async {
    try {
      print('📚 Загрузка списка сур из JSON...');
      
      // Загружаем JSON файл из assets (3 суры: 112, 113, 114)
      final String jsonString = await rootBundle.loadString('assets/data/surahs.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Парсим суры
      final List<dynamic> surahsJson = jsonData['surahs'] as List;
      final surahs = surahsJson.asMap().entries.map((entry) {
        final index = entry.key;
        final surahJson = entry.value as Map<String, dynamic>;
        // Назначаем цвет в зависимости от индекса
        final color = _surahColors[index % _surahColors.length];
        return Surah.fromJson(surahJson, color);
      }).toList();

      print('✅ Загружено ${surahs.length} сур из JSON');
      return surahs;
    } catch (e) {
      print('❌ Ошибка загрузки сур: $e');
      return [];
    }
  }

  /// Загрузить метаданные всех сур из API
  Future<void> _loadAllSurahsMetadata() async {
    try {
      final entities = await _apiService.fetchAllSurahsMetadata();
      
      // Обогащаем русскими названиями и сохраняем в базу
      for (final entity in entities) {
        final enriched = _apiService.enrichSurahWithRussianNames(entity);
        await _database.insertSurah(enriched.toMap());
      }
      
      print('✅ Метаданные ${entities.length} сур сохранены в базу');
    } catch (e) {
      print('❌ Ошибка загрузки метаданных: $e');
      rethrow;
    }
  }

  /// Получить суру по номеру (ВРЕМЕННО: используем JSON)
  Future<Surah?> getSurahByNumber(int number) async {
    try {
      print('📖 Загрузка суры $number из JSON...');
      
      final surahs = await loadSurahs();
      final surah = surahs.firstWhere(
        (s) => s.number == number,
        orElse: () => throw Exception('Сура $number не найдена'),
      );
      
      print('✅ Сура $number загружена (${surah.ayahs.length} аятов)');
      return surah;
    } catch (e) {
      print('❌ Ошибка загрузки суры $number: $e');
      return null;
    }
  }

  /// Загрузить суру из API и сохранить в базу
  Future<void> _loadSurahFromApi(int surahNumber, String languageCode) async {
    try {
      print('📡 Загрузка суры $surahNumber из API...');
      
      // 1. Загружаем суру с переводом из API
      final apiResponse = await _apiService.fetchSurahWithTranslation(
        surahNumber,
        languageCode,
      );
      
      // 2. Получаем ID суры в базе
      final surahMap = await _database.getSurah(surahNumber);
      if (surahMap == null) {
        throw Exception('Сура $surahNumber не найдена в базе');
      }
      final surahId = surahMap['id'] as int;
      
      // 3. Парсим аяты и переводы
      final parsed = await _apiService.parseSurahResponse(apiResponse, surahId);
      final ayahEntities = parsed['ayahs'] as List<AyahEntity>;
      final translationEntities = parsed['translations'] as List<TranslationEntity>;
      
      // 4. Сохраняем аяты в базу (батчем для скорости)
      final ayahMaps = ayahEntities.map((e) => e.toMap()).toList();
      await _database.insertAyahsBatch(ayahMaps);
      
      // 5. Получаем ID аятов и сохраняем переводы
      final savedAyahs = await _database.getAyahsBySurah(surahId);
      for (int i = 0; i < translationEntities.length; i++) {
        final ayahId = savedAyahs[i]['id'] as int;
        final translation = translationEntities[i];
        
        await _database.insertTranslation({
          'ayah_id': ayahId,
          'language_code': translation.languageCode,
          'text': translation.text,
          'translator_name': translation.translatorName,
        });
      }
      
      print('✅ Сура $surahNumber сохранена в базу');
    } catch (e) {
      print('❌ Ошибка загрузки суры из API: $e');
      rethrow;
    }
  }

  /// Построить модель Surah из данных базы
  Future<Surah> _buildSurahModel(Map<String, dynamic> surahMap) async {
    final entity = SurahEntity.fromMap(surahMap);
    final surahId = surahMap['id'] as int;
    
    // Получаем аяты
    final ayahMaps = await _database.getAyahsBySurah(surahId);
    
    // Строим модели аятов с переводами
    final ayahs = <Ayah>[];
    for (final ayahMap in ayahMaps) {
      final ayahEntity = AyahEntity.fromMap(ayahMap);
      final ayahId = ayahMap['id'] as int;
      
      // Получаем переводы аята
      final translationMaps = await _database.getTranslationsByAyah(ayahId);
      
      String mainTranslation = '';
      final Map<String, String> translations = {};
      
      for (final translationMap in translationMaps) {
        final langCode = translationMap['language_code'] as String;
        final text = translationMap['text'] as String;
        
        if (langCode == 'ru') {
          mainTranslation = text;
        } else {
          translations[langCode] = text;
        }
      }
      
      ayahs.add(ayahEntity.toModel(
        textRussian: mainTranslation,
      ).copyWithTranslation(
        _currentLanguage,
        translations[_currentLanguage] ?? mainTranslation,
      ));
    }
    
    final color = _surahColors[entity.number % _surahColors.length];
    return entity.toModel(ayahs: ayahs, color: color);
  }

  // ==================== ЗАКЛАДКИ ====================

  /// Переключить закладку для аята (ВРЕМЕННО: используем старый метод)
  Future<void> toggleBookmark(int surahNumber, int ayahNumber) async {
    await _storageService.init();
    final key = _getBookmarkKey(surahNumber, ayahNumber);
    final isCurrentlyBookmarked = await isBookmarked(surahNumber, ayahNumber);
    
    if (isCurrentlyBookmarked) {
      // Удаляем закладку
      final bookmarks = await _getBookmarks();
      bookmarks.remove(key);
      await _saveBookmarks(bookmarks);
      print('🔖 Закладка удалена: $surahNumber:$ayahNumber');
    } else {
      // Добавляем закладку
      final bookmarks = await _getBookmarks();
      bookmarks.add(key);
      await _saveBookmarks(bookmarks);
      print('🔖 Закладка добавлена: $surahNumber:$ayahNumber');
    }
  }

  /// Проверить, является ли аят закладкой
  Future<bool> isBookmarked(int surahNumber, int ayahNumber) async {
    final bookmarks = await _getBookmarks();
    final key = _getBookmarkKey(surahNumber, ayahNumber);
    return bookmarks.contains(key);
  }

  /// Получить все закладки (старый формат)
  Future<List<String>> _getBookmarks() async {
    await _storageService.init();
    final bookmarksJson = await _storageService.getString('quran_bookmarks');
    
    if (bookmarksJson == null || bookmarksJson.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = json.decode(bookmarksJson);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Сохранить закладки (старый формат)
  Future<void> _saveBookmarks(List<String> bookmarks) async {
    final bookmarksJson = json.encode(bookmarks);
    await _storageService.saveString('quran_bookmarks', bookmarksJson);
  }

  /// Получить ключ закладки
  String _getBookmarkKey(int surahNumber, int ayahNumber) {
    return 'surah_${surahNumber}_ayah_$ayahNumber';
  }

  // ==================== АУДИО ====================

  /// Получить URL или путь к аудио (гибридный режим: стриминг + кэш)
  Future<String> getAudioUrl(int surahNumber, int ayahNumber) async {
    final reciter = await getCurrentReciter();
    return await _audioCacheService.getAudioPath(
      surahNumber,
      ayahNumber,
      reciter.id,
    );
  }

  /// Проверить, закэширован ли аудио файл
  Future<bool> isAudioCached(int surahNumber, int ayahNumber) async {
    final reciter = await getCurrentReciter();
    return await _audioCacheService.isCached(
      surahNumber,
      ayahNumber,
      reciter.id,
    );
  }

  /// Скачать и закэшировать аудио
  Future<String?> cacheAudio(int surahNumber, int ayahNumber) async {
    final reciter = await getCurrentReciter();
    return await _audioCacheService.downloadAndCache(
      surahNumber,
      ayahNumber,
      reciter.id,
    );
  }

  /// Получить текущего выбранного чтеца
  Future<QuranReciter> getCurrentReciter() async {
    if (_selectedReciterId == null) {
      _selectedReciterId = await _storageService.getString('selected_reciter') ?? 'mishary';
    }
    return QuranReciter.getById(_selectedReciterId!);
  }

  /// Установить чтеца
  Future<void> setReciter(String reciterId) async {
    _selectedReciterId = reciterId;
    await _storageService.saveString('selected_reciter', reciterId);
    await _audioCacheService.clearUrlCache();
    print('🔄 Чтец изменен: $reciterId');
  }

  /// Получить список всех доступных чтецов
  List<QuranReciter> getAllReciters() {
    return QuranReciter.getAll();
  }

  // ==================== ЯЗЫК ПЕРЕВОДА ====================

  /// Установить язык перевода
  Future<void> setLanguage(String languageCode) async {
    if (!SupportedLanguages.getAllLanguages().contains(languageCode)) {
      throw Exception('Язык $languageCode не поддерживается');
    }
    
    _currentLanguage = languageCode;
    await _storageService.saveString('selected_language', languageCode);
    
    // Очищаем кэш памяти, чтобы перезагрузить суры с новым переводом
    _memoryCache.clear();
    
    print('🌐 Язык изменен: $languageCode');
  }

  /// Получить текущий язык
  String getCurrentLanguage() => _currentLanguage;

  // ==================== УТИЛИТЫ ====================

  /// Очистить кэш в памяти
  void clearMemoryCache() {
    _memoryCache.clear();
    print('🗑️ Кэш памяти очищен');
  }

  /// Очистить кэш аудио
  Future<void> clearAudioCache() async {
    await _audioCacheService.clearCache();
  }

  /// Получить размер аудио кэша
  Future<String> getAudioCacheSize() async {
    return await _audioCacheService.getCacheSizeMB();
  }

  /// Очистить всю базу данных
  Future<void> clearDatabase() async {
    await _database.clearAllData();
    _memoryCache.clear();
    print('🗑️ База данных очищена');
  }

  /// Получить статистику
  Future<Map<String, int>> getStatistics() async {
    return {
      'surahsCount': await _database.getSurahsCount(),
      'ayahsCount': await _database.getAyahsCount(),
      'bookmarksCount': (await _database.getAllBookmarks()).length,
    };
  }

  /// Проверить доступность API
  Future<bool> checkApiAvailability() async {
    return await _apiService.checkApiAvailability();
  }

  // ==================== МИГРАЦИЯ ЗАКЛАДОК ====================

  /// Мигрировать старые закладки из SharedPreferences в SQLite
  Future<void> migrateOldBookmarks() async {
    try {
      final oldBookmarksJson = await _storageService.getString('quran_bookmarks');
      
      if (oldBookmarksJson == null || oldBookmarksJson.isEmpty) {
        print('📚 Нет старых закладок для миграции');
        return;
      }
      
      final List<dynamic> oldBookmarks = jsonDecode(oldBookmarksJson) as List;
      int migratedCount = 0;
      
      for (final bookmarkKey in oldBookmarks) {
        final key = bookmarkKey.toString();
        // Формат ключа: "surah_112_ayah_1"
        final parts = key.split('_');
        if (parts.length == 4) {
          final surahNumber = int.tryParse(parts[1]);
          final ayahNumber = int.tryParse(parts[3]);
          
          if (surahNumber != null && ayahNumber != null) {
            await _database.insertBookmark(surahNumber, ayahNumber);
            migratedCount++;
          }
        }
      }
      
      print('✅ Мигрировано $migratedCount закладок');
      
      // Удаляем старые закладки из SharedPreferences
      await _storageService.saveString('quran_bookmarks', '');
    } catch (e) {
      print('❌ Ошибка миграции закладок: $e');
    }
  }
}
