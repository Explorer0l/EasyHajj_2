/// Модель чтеца Корана
class QuranReciter {
  final String id;
  final String nameArabic;
  final String nameRussian;
  final String country;
  final String quranComId; // ID для AlQuran.cloud API
  final String description;

  const QuranReciter({
    required this.id,
    required this.nameArabic,
    required this.nameRussian,
    required this.country,
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
      quranComId: 'ar.alafasy',
      description: 'Самый популярный в мире, красивый мелодичный голос',
    ),
    QuranReciter(
      id: 'abdulbasit',
      nameArabic: 'عبد الباسط عبد الصمد',
      nameRussian: 'Абдуль Басит Абдус Самад',
      country: 'Египет',
      quranComId: 'ar.abdulbasitmurattal',
      description: 'Легенда, золотой голос Корана',
    ),
    QuranReciter(
      id: 'husary',
      nameArabic: 'محمود خليل الحصري',
      nameRussian: 'Махмуд Халиль аль-Хусари',
      country: 'Египет',
      quranComId: 'ar.husary',
      description: 'Классика, четкое произношение (Tajweed)',
    ),
    QuranReciter(
      id: 'sudais',
      nameArabic: 'عبد الرحمن السديس',
      nameRussian: 'Абдуррахман ас-Судайс',
      country: 'Саудовская Аравия',
      quranComId: 'ar.abdurrahmaansudais',
      description: 'Имам Мечети аль-Харам (Мекка), мощный голос',
    ),
    QuranReciter(
      id: 'shuraim',
      nameArabic: 'سعود الشريم',
      nameRussian: 'Сауд аш-Шурайм',
      country: 'Саудовская Аравия',
      quranComId: 'ar.saoodshuraym',
      description: 'Имам Мечети аль-Харам (Мекка), выразительное чтение',
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

