/// Database Entity для перевода аята
class TranslationEntity {
  final int? id;
  final int ayahId;
  final String languageCode; // ru, en, uz, etc.
  final String text;
  final String? translatorName;

  TranslationEntity({
    this.id,
    required this.ayahId,
    required this.languageCode,
    required this.text,
    this.translatorName,
  });

  /// Преобразовать в Map для SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'ayah_id': ayahId,
      'language_code': languageCode,
      'text': text,
      if (translatorName != null) 'translator_name': translatorName,
    };
  }

  /// Создать из Map (из SQLite)
  factory TranslationEntity.fromMap(Map<String, dynamic> map) {
    return TranslationEntity(
      id: map['id'] as int?,
      ayahId: map['ayah_id'] as int,
      languageCode: map['language_code'] as String,
      text: map['text'] as String,
      translatorName: map['translator_name'] as String?,
    );
  }

  /// Создать из API ответа AlQuran.cloud
  factory TranslationEntity.fromApi({
    required int ayahId,
    required String languageCode,
    required Map<String, dynamic> apiData,
    String? translatorName,
  }) {
    return TranslationEntity(
      ayahId: ayahId,
      languageCode: languageCode,
      text: apiData['text'] as String,
      translatorName: translatorName,
    );
  }

  @override
  String toString() {
    return 'TranslationEntity(id: $id, ayahId: $ayahId, lang: $languageCode)';
  }
}

/// Поддерживаемые языки переводов
class SupportedLanguages {
  static const String russian = 'ru';
  static const String english = 'en';
  static const String uzbek = 'uz';

  /// Маппинг языков на ID в AlQuran.cloud API
  static const Map<String, String> apiIdentifiers = {
    russian: 'ru.kuliev', // Кулиев перевод
    english: 'en.sahih', // Sahih International
    uzbek: 'uz.sodik', // Узбекский перевод
  };

  /// Названия переводчиков
  static const Map<String, String> translatorNames = {
    russian: 'Э. Кулиев',
    english: 'Sahih International',
    uzbek: 'М. Содик',
  };

  /// Получить API идентификатор для языка
  static String getApiId(String languageCode) {
    return apiIdentifiers[languageCode] ?? apiIdentifiers[russian]!;
  }

  /// Получить имя переводчика
  static String getTranslatorName(String languageCode) {
    return translatorNames[languageCode] ?? 'Unknown';
  }

  /// Получить список всех доступных языков
  static List<String> getAllLanguages() {
    return [russian, english, uzbek];
  }
}

