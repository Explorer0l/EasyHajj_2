import 'package:dio/dio.dart';
import 'package:easy_hajj/database/models/surah_entity.dart';
import 'package:easy_hajj/database/models/ayah_entity.dart';
import 'package:easy_hajj/database/models/translation_entity.dart';
import 'package:easy_hajj/database/surah_names_data.dart';

/// Сервис для работы с AlQuran.cloud API
class QuranApiService {
  static final QuranApiService _instance = QuranApiService._internal();
  factory QuranApiService() => _instance;
  QuranApiService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.alquran.cloud/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  /// Получить метаданные всех сур
  Future<List<SurahEntity>> fetchAllSurahsMetadata() async {
    try {
      print('📡 Загрузка метаданных всех сур...');
      
      final response = await _dio.get('/surah');
      
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final List<dynamic> data = response.data['data'] as List;
        
        final surahs = data.map((surahData) {
          return SurahEntity.fromApi(surahData as Map<String, dynamic>);
        }).toList();
        
        print('✅ Загружено ${surahs.length} сур (метаданные)');
        return surahs;
      } else {
        throw Exception('API вернул ошибку: ${response.data}');
      }
    } on DioException catch (e) {
      print('❌ DioException при загрузке метаданных: ${e.type} - ${e.message}');
      throw Exception('Ошибка сети: ${e.message}');
    } catch (e) {
      print('❌ Ошибка загрузки метаданных: $e');
      rethrow;
    }
  }

  /// Получить суру с аятами и переводом
  Future<Map<String, dynamic>> fetchSurahWithTranslation(
    int surahNumber,
    String languageCode,
  ) async {
    try {
      final translationId = SupportedLanguages.getApiId(languageCode);
      
      print('📡 Загрузка суры $surahNumber с переводом $languageCode...');
      
      // Запрашиваем арабский текст и перевод одновременно
      final url = '/surah/$surahNumber/editions/quran-uthmani,$translationId';
      final response = await _dio.get(url);
      
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final List<dynamic> editions = response.data['data'] as List;
        
        if (editions.length < 2) {
          throw Exception('API вернул неполные данные');
        }
        
        // Первый элемент - арабский текст
        final arabicEdition = editions[0] as Map<String, dynamic>;
        // Второй элемент - перевод
        final translationEdition = editions[1] as Map<String, dynamic>;
        
        print('✅ Сура $surahNumber загружена с ${(arabicEdition['ayahs'] as List).length} аятами');
        
        return {
          'surah': arabicEdition,
          'translation': translationEdition,
          'languageCode': languageCode,
        };
      } else {
        throw Exception('API вернул ошибку: ${response.data}');
      }
    } on DioException catch (e) {
      print('❌ DioException при загрузке суры: ${e.type} - ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Сура $surahNumber не найдена');
      }
      throw Exception('Ошибка сети: ${e.message}');
    } catch (e) {
      print('❌ Ошибка загрузки суры: $e');
      rethrow;
    }
  }

  /// Получить один аят с переводом
  Future<Map<String, dynamic>> fetchAyahWithTranslation(
    int surahNumber,
    int ayahNumber,
    String languageCode,
  ) async {
    try {
      final translationId = SupportedLanguages.getApiId(languageCode);
      
      print('📡 Загрузка аята $surahNumber:$ayahNumber с переводом...');
      
      final url = '/ayah/$surahNumber:$ayahNumber/editions/quran-uthmani,$translationId';
      final response = await _dio.get(url);
      
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final List<dynamic> editions = response.data['data'] as List;
        
        if (editions.length < 2) {
          throw Exception('API вернул неполные данные');
        }
        
        return {
          'arabic': editions[0] as Map<String, dynamic>,
          'translation': editions[1] as Map<String, dynamic>,
          'languageCode': languageCode,
        };
      } else {
        throw Exception('API вернул ошибку: ${response.data}');
      }
    } on DioException catch (e) {
      print('❌ DioException при загрузке аята: ${e.type} - ${e.message}');
      throw Exception('Ошибка сети: ${e.message}');
    } catch (e) {
      print('❌ Ошибка загрузки аята: $e');
      rethrow;
    }
  }

  /// Парсинг суры из API ответа в Entity модели
  Future<Map<String, dynamic>> parseSurahResponse(
    Map<String, dynamic> apiResponse,
    int surahDbId,
  ) async {
    try {
      final surahData = apiResponse['surah'] as Map<String, dynamic>;
      final translationData = apiResponse['translation'] as Map<String, dynamic>;
      final languageCode = apiResponse['languageCode'] as String;
      
      final List<dynamic> arabicAyahs = surahData['ayahs'] as List;
      final List<dynamic> translationAyahs = translationData['ayahs'] as List;
      
      if (arabicAyahs.length != translationAyahs.length) {
        throw Exception('Количество аятов не совпадает');
      }
      
      // Создаем Entity для аятов
      final List<AyahEntity> ayahEntities = [];
      final List<TranslationEntity> translationEntities = [];
      
      for (int i = 0; i < arabicAyahs.length; i++) {
        final arabicAyah = arabicAyahs[i] as Map<String, dynamic>;
        final translationAyah = translationAyahs[i] as Map<String, dynamic>;
        
        // Создаем аят (без id, т.к. он будет назначен базой данных)
        final ayahEntity = AyahEntity.fromApi(
          surahId: surahDbId,
          apiData: arabicAyah,
        );
        
        ayahEntities.add(ayahEntity);
        
        // Перевод будем добавлять после вставки аята (нужен ayah_id)
        translationEntities.add(
          TranslationEntity(
            ayahId: -1, // Временное значение, будет заменено
            languageCode: languageCode,
            text: translationAyah['text'] as String,
            translatorName: SupportedLanguages.getTranslatorName(languageCode),
          ),
        );
      }
      
      return {
        'ayahs': ayahEntities,
        'translations': translationEntities,
      };
    } catch (e) {
      print('❌ Ошибка парсинга ответа API: $e');
      rethrow;
    }
  }

  /// Получить информацию о конкретной суре (метаданные)
  Future<SurahEntity> fetchSurahMetadata(int surahNumber) async {
    try {
      print('📡 Загрузка метаданных суры $surahNumber...');
      
      final response = await _dio.get('/surah/$surahNumber');
      
      if (response.statusCode == 200 && response.data['code'] == 200) {
        final surahData = response.data['data'] as Map<String, dynamic>;
        return SurahEntity.fromApi(surahData);
      } else {
        throw Exception('API вернул ошибку: ${response.data}');
      }
    } on DioException catch (e) {
      print('❌ DioException при загрузке метаданных: ${e.type} - ${e.message}');
      throw Exception('Ошибка сети: ${e.message}');
    } catch (e) {
      print('❌ Ошибка загрузки метаданных: $e');
      rethrow;
    }
  }

  /// Проверить доступность API
  Future<bool> checkApiAvailability() async {
    try {
      final response = await _dio.get(
        '/surah/1',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ API недоступен: $e');
      return false;
    }
  }

  /// Обновить Entity суры с русскими названиями
  SurahEntity enrichSurahWithRussianNames(SurahEntity entity) {
    return SurahEntity(
      id: entity.id,
      number: entity.number,
      nameArabic: entity.nameArabic,
      nameRussian: SurahNamesData.getName(entity.number),
      meaning: SurahNamesData.getMeaning(entity.number),
      ayahCount: entity.ayahCount,
      revelationPlace: entity.revelationPlace == 'Meccan' ? 'Мекка' : 'Медина',
      createdAt: entity.createdAt,
    );
  }
}

