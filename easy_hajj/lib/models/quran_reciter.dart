/// Модель чтеца Корана
class QuranReciter {
  final String id;
  final String nameArabic;
  final String nameRussian;
  final String country;
  final String apiPath;
  final String quranComId; // ID для Quran.com CDN API
  final String description;

  const QuranReciter({
    required this.id,
    required this.nameArabic,
    required this.nameRussian,
    required this.country,
    required this.apiPath,
    required this.quranComId,
    required this.description,
  });

  /// ТОП-5 популярных чтецов мира
  static const List<QuranReciter> popularReciters = [
    QuranReciter(
      id: 'mishary',
      nameArabic: 'مشاري راشد العفاسي',
      nameRussian: 'Мишари Рашид аль-Афаси',
      country: 'Кувейт',
      apiPath: 'Mishary_Rashid_Alafasy_64kbps',
      quranComId: 'ar.alafasy', // Islamic Network CDN format
      description: 'Самый популярный в мире, красивый мелодичный голос',
    ),
    QuranReciter(
      id: 'sudais',
      nameArabic: 'عبد الرحمن السديس',
      nameRussian: 'Абдуррахман ас-Судайс',
      country: 'Саудовская Аравия',
      apiPath: 'Abdurrahmaan_As-Sudais_64kbps',
      quranComId: 'ar.abdurrahmaansudais',
      description: 'Имам Мечети аль-Харам (Мекка), мощный голос',
    ),
    QuranReciter(
      id: 'husary',
      nameArabic: 'محمود خليل الحصري',
      nameRussian: 'Махмуд Халиль аль-Хусари',
      country: 'Египет',
      apiPath: 'Mahmood_Khaleel_Al-Husaree_64kbps',
      quranComId: 'ar.husary',
      description: 'Классика, четкое произношение (Tajweed)',
    ),
    QuranReciter(
      id: 'minshawi',
      nameArabic: 'محمد صديق المنشاوي',
      nameRussian: 'Мухаммад Сиддик аль-Миншави',
      country: 'Египет',
      apiPath: 'Mohammad_al_Tablaway_64kbps',
      quranComId: 'ar.minshawi',
      description: 'Эмоциональное чтение, красивая мелодия',
    ),
    QuranReciter(
      id: 'abdulbasit',
      nameArabic: 'عبد الباسط عبد الصمد',
      nameRussian: 'Абдуль Басит Абдус Самад',
      country: 'Египет',
      apiPath: 'Abdul_Basit_Murattal_64kbps',
      quranComId: 'ar.abdulbasitmurattal',
      description: 'Легенда, золотой голос Корана',
    ),
  ];

  /// Получить чтеца по ID
  static QuranReciter getById(String id) {
    try {
      return popularReciters.firstWhere((r) => r.id == id);
    } catch (e) {
      // По умолчанию возвращаем Мишари
      return popularReciters.first;
    }
  }

  /// Получить список всех чтецов
  static List<QuranReciter> getAll() {
    return popularReciters;
  }

  /// Полное имя (арабское + русское)
  String get fullName => '$nameRussian\n$nameArabic';

  /// Краткое имя
  String get shortName => nameRussian;
}

