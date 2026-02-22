import 'package:easy_hajj/models/quran_models.dart';
import 'package:flutter/material.dart';

/// Database Entity для суры
class SurahEntity {
  final int? id;
  final int number;
  final String nameArabic;
  final String nameRussian;
  final String meaning;
  final int ayahCount;
  final String revelationPlace;
  final int createdAt;

  SurahEntity({
    this.id,
    required this.number,
    required this.nameArabic,
    required this.nameRussian,
    required this.meaning,
    required this.ayahCount,
    required this.revelationPlace,
    required this.createdAt,
  });

  /// Преобразовать в Map для SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'number': number,
      'name_arabic': nameArabic,
      'name_russian': nameRussian,
      'meaning': meaning,
      'ayah_count': ayahCount,
      'revelation_place': revelationPlace,
      'created_at': createdAt,
    };
  }

  /// Создать из Map (из SQLite)
  factory SurahEntity.fromMap(Map<String, dynamic> map) {
    return SurahEntity(
      id: map['id'] as int?,
      number: map['number'] as int,
      nameArabic: map['name_arabic'] as String,
      nameRussian: map['name_russian'] as String,
      meaning: map['meaning'] as String,
      ayahCount: map['ayah_count'] as int,
      revelationPlace: map['revelation_place'] as String,
      createdAt: map['created_at'] as int,
    );
  }

  /// Создать из API ответа AlQuran.cloud
  factory SurahEntity.fromApi(Map<String, dynamic> apiData) {
    return SurahEntity(
      number: apiData['number'] as int,
      nameArabic: apiData['name'] as String? ?? '',
      nameRussian: apiData['englishName'] as String? ?? '', // Временно, потом заменим
      meaning: apiData['englishNameTranslation'] as String? ?? '',
      ayahCount: apiData['numberOfAyahs'] as int,
      revelationPlace: apiData['revelationType'] as String? ?? 'Mecca',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Преобразовать в Surah модель для UI
  Surah toModel({
    required List<Ayah> ayahs,
    required Color color,
  }) {
    return Surah(
      number: number,
      nameArabic: nameArabic,
      nameRussian: nameRussian,
      meaning: meaning,
      ayahCount: ayahCount,
      revelation: revelationPlace,
      ayahs: ayahs,
      color: color,
    );
  }

  /// Создать Entity из Surah модели
  factory SurahEntity.fromModel(Surah surah) {
    return SurahEntity(
      number: surah.number,
      nameArabic: surah.nameArabic,
      nameRussian: surah.nameRussian,
      meaning: surah.meaning,
      ayahCount: surah.ayahCount,
      revelationPlace: surah.revelation,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  String toString() {
    return 'SurahEntity(id: $id, number: $number, nameArabic: $nameArabic)';
  }
}

