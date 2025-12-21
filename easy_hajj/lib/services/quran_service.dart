import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_hajj/models/quran_models.dart';
import 'package:easy_hajj/models/quran_reciter.dart';
import 'package:easy_hajj/services/storage_service.dart';
import 'package:easy_hajj/services/audio_cache_service.dart';
import 'package:easy_hajj/core/constants/app_colors.dart';

/// Сервис для работы с Кораном
class QuranService {
  static final QuranService _instance = QuranService._internal();
  factory QuranService() => _instance;
  QuranService._internal();

  final StorageService _storageService = StorageService();
  final AudioCacheService _audioCacheService = AudioCacheService();
  List<Surah>? _cachedSurahs;
  String? _selectedReciterId;

  // Фирменные цвета для сур
  static const List<Color> _surahColors = [
    AppColors.primary,    // 112 - Фиолетовый
    AppColors.secondary,  // 113 - Бирюзовый
    Color(0xFFFDB954),    // 114 - Желтый/оранжевый
  ];

  /// Загрузить все суры из JSON
  Future<List<Surah>> loadSurahs() async {
    // Возвращаем кэшированные суры, если они уже загружены
    if (_cachedSurahs != null) {
      return _cachedSurahs!;
    }

    try {
      // Загружаем JSON файл из assets
      final String jsonString = await rootBundle.loadString('assets/data/surahs.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Парсим суры
      final List<dynamic> surahsJson = jsonData['surahs'] as List;
      _cachedSurahs = surahsJson.asMap().entries.map((entry) {
        final index = entry.key;
        final surahJson = entry.value as Map<String, dynamic>;
        // Назначаем цвет в зависимости от индекса
        final color = _surahColors[index % _surahColors.length];
        return Surah.fromJson(surahJson, color);
      }).toList();

      return _cachedSurahs!;
    } catch (e) {
      print('Ошибка загрузки сур: $e');
      return [];
    }
  }

  /// Получить суру по номеру
  Future<Surah?> getSurahByNumber(int number) async {
    final surahs = await loadSurahs();
    try {
      return surahs.firstWhere((surah) => surah.number == number);
    } catch (e) {
      return null;
    }
  }

  /// Переключить закладку для аята
  Future<void> toggleBookmark(int surahNumber, int ayahNumber) async {
    await _storageService.init();
    final key = _getBookmarkKey(surahNumber, ayahNumber);
    final isCurrentlyBookmarked = await isBookmarked(surahNumber, ayahNumber);
    
    if (isCurrentlyBookmarked) {
      // Удаляем закладку
      final bookmarks = await getBookmarks();
      bookmarks.remove(key);
      await _saveBookmarks(bookmarks);
    } else {
      // Добавляем закладку
      final bookmarks = await getBookmarks();
      bookmarks.add(key);
      await _saveBookmarks(bookmarks);
    }
  }

  /// Получить все закладки
  Future<List<String>> getBookmarks() async {
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

  /// Проверить, является ли аят закладкой
  Future<bool> isBookmarked(int surahNumber, int ayahNumber) async {
    final bookmarks = await getBookmarks();
    final key = _getBookmarkKey(surahNumber, ayahNumber);
    return bookmarks.contains(key);
  }

  /// Сохранить закладки
  Future<void> _saveBookmarks(List<String> bookmarks) async {
    final bookmarksJson = json.encode(bookmarks);
    await _storageService.saveString('quran_bookmarks', bookmarksJson);
  }

  /// Получить ключ закладки
  String _getBookmarkKey(int surahNumber, int ayahNumber) {
    return 'surah_${surahNumber}_ayah_$ayahNumber';
  }

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
    final url = _buildAudioUrl(reciter.id, surahNumber, ayahNumber);
    return await _audioCacheService.downloadAndCache(
      url,
      surahNumber,
      ayahNumber,
      reciter.id,
    );
  }

  /// Построить URL для аудио (Islamic Network CDN)
  String _buildAudioUrl(String reciterId, int surahNumber, int ayahNumber) {
    final reciter = QuranReciter.getById(reciterId);
    
    // Islamic Network CDN: формат {surah}{ayah}.mp3
    // Пример: 1121.mp3 = сура 112, аят 1
    final audioId = '$surahNumber$ayahNumber';
    
    return 'https://cdn.islamic.network/quran/audio/128/${reciter.quranComId}/$audioId.mp3';
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
  }

  /// Получить список всех доступных чтецов
  List<QuranReciter> getAllReciters() {
    return QuranReciter.getAll();
  }

  /// Очистить кэш сур
  void clearSurahsCache() {
    _cachedSurahs = null;
  }

  /// Очистить кэш аудио
  Future<void> clearAudioCache() async {
    await _audioCacheService.clearCache();
  }

  /// Получить размер аудио кэша
  Future<String> getAudioCacheSize() async {
    return await _audioCacheService.getCacheSizeMB();
  }
}

