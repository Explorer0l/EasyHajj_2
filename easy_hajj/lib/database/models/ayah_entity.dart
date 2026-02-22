import 'package:easy_hajj/models/quran_models.dart';

/// Database Entity для аята
class AyahEntity {
  final int? id;
  final int surahId;
  final int number;
  final String textArabic;
  final bool hasRubElHizb;

  AyahEntity({
    this.id,
    required this.surahId,
    required this.number,
    required this.textArabic,
    this.hasRubElHizb = false,
  });

  /// Преобразовать в Map для SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'surah_id': surahId,
      'number': number,
      'text_arabic': textArabic,
      'has_rub_el_hizb': hasRubElHizb ? 1 : 0,
    };
  }

  /// Создать из Map (из SQLite)
  factory AyahEntity.fromMap(Map<String, dynamic> map) {
    return AyahEntity(
      id: map['id'] as int?,
      surahId: map['surah_id'] as int,
      number: map['number'] as int,
      textArabic: map['text_arabic'] as String,
      hasRubElHizb: (map['has_rub_el_hizb'] as int) == 1,
    );
  }

  /// Создать из API ответа AlQuran.cloud
  factory AyahEntity.fromApi({
    required int surahId,
    required Map<String, dynamic> apiData,
  }) {
    return AyahEntity(
      surahId: surahId,
      number: apiData['numberInSurah'] as int,
      textArabic: apiData['text'] as String,
      hasRubElHizb: false, // Определяем вручную или из другого источника
    );
  }

  /// Преобразовать в Ayah модель для UI
  Ayah toModel({
    required String textRussian,
    String? audioUrl,
  }) {
    return Ayah(
      number: number,
      textArabic: textArabic,
      textRussian: textRussian,
      audioUrl: audioUrl,
      hasRubElHizb: hasRubElHizb,
    );
  }

  /// Создать Entity из Ayah модели
  factory AyahEntity.fromModel({
    required int surahId,
    required Ayah ayah,
  }) {
    return AyahEntity(
      surahId: surahId,
      number: ayah.number,
      textArabic: ayah.textArabic,
      hasRubElHizb: ayah.hasRubElHizb,
    );
  }

  @override
  String toString() {
    return 'AyahEntity(id: $id, surahId: $surahId, number: $number)';
  }
}

