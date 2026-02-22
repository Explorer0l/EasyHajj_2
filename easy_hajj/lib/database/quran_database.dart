import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// База данных для хранения Корана (114 сур, аятов, переводов)
class QuranDatabase {
  static final QuranDatabase _instance = QuranDatabase._internal();
  factory QuranDatabase() => _instance;
  QuranDatabase._internal();

  Database? _database;

  /// Получить экземпляр базы данных
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Инициализация базы данных
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quran.db');

    print('📚 Инициализация базы данных Корана: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Создание таблиц при первом запуске
  Future<void> _onCreate(Database db, int version) async {
    print('📚 Создание таблиц базы данных...');

    // Таблица сур
    await db.execute('''
      CREATE TABLE surahs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number INTEGER UNIQUE NOT NULL,
        name_arabic TEXT NOT NULL,
        name_russian TEXT NOT NULL,
        meaning TEXT NOT NULL,
        ayah_count INTEGER NOT NULL,
        revelation_place TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Индекс для быстрого поиска по номеру суры
    await db.execute('''
      CREATE INDEX idx_surah_number ON surahs(number)
    ''');

    // Таблица аятов
    await db.execute('''
      CREATE TABLE ayahs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_id INTEGER NOT NULL,
        number INTEGER NOT NULL,
        text_arabic TEXT NOT NULL,
        has_rub_el_hizb INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (surah_id) REFERENCES surahs(id) ON DELETE CASCADE,
        UNIQUE(surah_id, number)
      )
    ''');

    // Индексы для аятов
    await db.execute('''
      CREATE INDEX idx_ayah_surah ON ayahs(surah_id)
    ''');

    // Таблица переводов
    await db.execute('''
      CREATE TABLE translations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ayah_id INTEGER NOT NULL,
        language_code TEXT NOT NULL,
        text TEXT NOT NULL,
        translator_name TEXT,
        FOREIGN KEY (ayah_id) REFERENCES ayahs(id) ON DELETE CASCADE,
        UNIQUE(ayah_id, language_code)
      )
    ''');

    // Индексы для переводов
    await db.execute('''
      CREATE INDEX idx_translation_ayah ON translations(ayah_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_translation_lang ON translations(language_code)
    ''');

    // Таблица закладок
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE(surah_number, ayah_number)
      )
    ''');

    // Индекс для закладок
    await db.execute('''
      CREATE INDEX idx_bookmark_surah_ayah ON bookmarks(surah_number, ayah_number)
    ''');

    print('✅ Таблицы успешно созданы');
  }

  /// Обновление схемы базы данных при новых версиях
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('📚 Обновление базы данных с версии $oldVersion до $newVersion');
    
    // Здесь будут миграции для будущих версий
    // Например:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE surahs ADD COLUMN new_field TEXT');
    // }
  }

  // ==================== CRUD операции для СУР ====================

  /// Сохранить суру
  Future<int> insertSurah(Map<String, dynamic> surah) async {
    final db = await database;
    return await db.insert(
      'surahs',
      surah,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Получить суру по номеру
  Future<Map<String, dynamic>?> getSurah(int number) async {
    final db = await database;
    final results = await db.query(
      'surahs',
      where: 'number = ?',
      whereArgs: [number],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Получить все суры
  Future<List<Map<String, dynamic>>> getAllSurahs() async {
    final db = await database;
    return await db.query('surahs', orderBy: 'number ASC');
  }

  /// Проверить, существует ли сура
  Future<bool> surahExists(int number) async {
    final db = await database;
    final result = await db.query(
      'surahs',
      columns: ['id'],
      where: 'number = ?',
      whereArgs: [number],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Удалить суру
  Future<int> deleteSurah(int number) async {
    final db = await database;
    return await db.delete(
      'surahs',
      where: 'number = ?',
      whereArgs: [number],
    );
  }

  // ==================== CRUD операции для АЯТОВ ====================

  /// Сохранить аят
  Future<int> insertAyah(Map<String, dynamic> ayah) async {
    final db = await database;
    return await db.insert(
      'ayahs',
      ayah,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Получить аяты суры
  Future<List<Map<String, dynamic>>> getAyahsBySurah(int surahId) async {
    final db = await database;
    return await db.query(
      'ayahs',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'number ASC',
    );
  }

  /// Получить конкретный аят
  Future<Map<String, dynamic>?> getAyah(int surahId, int ayahNumber) async {
    final db = await database;
    final results = await db.query(
      'ayahs',
      where: 'surah_id = ? AND number = ?',
      whereArgs: [surahId, ayahNumber],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Сохранить несколько аятов сразу (транзакция)
  Future<void> insertAyahsBatch(List<Map<String, dynamic>> ayahs) async {
    final db = await database;
    final batch = db.batch();
    
    for (final ayah in ayahs) {
      batch.insert(
        'ayahs',
        ayah,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // ==================== CRUD операции для ПЕРЕВОДОВ ====================

  /// Сохранить перевод
  Future<int> insertTranslation(Map<String, dynamic> translation) async {
    final db = await database;
    return await db.insert(
      'translations',
      translation,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Получить переводы аята
  Future<List<Map<String, dynamic>>> getTranslationsByAyah(
    int ayahId, {
    String? languageCode,
  }) async {
    final db = await database;
    
    if (languageCode != null) {
      return await db.query(
        'translations',
        where: 'ayah_id = ? AND language_code = ?',
        whereArgs: [ayahId, languageCode],
      );
    } else {
      return await db.query(
        'translations',
        where: 'ayah_id = ?',
        whereArgs: [ayahId],
      );
    }
  }

  /// Сохранить несколько переводов сразу (транзакция)
  Future<void> insertTranslationsBatch(
    List<Map<String, dynamic>> translations,
  ) async {
    final db = await database;
    final batch = db.batch();
    
    for (final translation in translations) {
      batch.insert(
        'translations',
        translation,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // ==================== CRUD операции для ЗАКЛАДОК ====================

  /// Добавить закладку
  Future<int> insertBookmark(int surahNumber, int ayahNumber) async {
    final db = await database;
    return await db.insert(
      'bookmarks',
      {
        'surah_number': surahNumber,
        'ayah_number': ayahNumber,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Удалить закладку
  Future<int> deleteBookmark(int surahNumber, int ayahNumber) async {
    final db = await database;
    return await db.delete(
      'bookmarks',
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [surahNumber, ayahNumber],
    );
  }

  /// Проверить, есть ли закладка
  Future<bool> isBookmarked(int surahNumber, int ayahNumber) async {
    final db = await database;
    final result = await db.query(
      'bookmarks',
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [surahNumber, ayahNumber],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Получить все закладки
  Future<List<Map<String, dynamic>>> getAllBookmarks() async {
    final db = await database;
    return await db.query(
      'bookmarks',
      orderBy: 'created_at DESC',
    );
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

  /// Получить количество сур в базе
  Future<int> getSurahsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM surahs');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Получить количество аятов в базе
  Future<int> getAyahsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ayahs');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Очистить все данные
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('bookmarks');
    await db.delete('translations');
    await db.delete('ayahs');
    await db.delete('surahs');
    print('🗑️ Все данные удалены из базы');
  }

  /// Закрыть базу данных
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('📚 База данных закрыта');
  }
}

