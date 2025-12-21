import 'package:flutter/material.dart';

/// Модель аята
class Ayah {
  final int number;
  final String textArabic;
  final String textRussian;
  final String? audioUrl;
  final bool hasRubElHizb; // Маркер четверти хизба

  Ayah({
    required this.number,
    required this.textArabic,
    required this.textRussian,
    this.audioUrl,
    this.hasRubElHizb = false,
  });

  /// Создать из JSON
  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'] as int,
      textArabic: json['textArabic'] as String,
      textRussian: json['textRussian'] as String,
      audioUrl: json['audioUrl'] as String?,
      hasRubElHizb: json['hasRubElHizb'] ?? false,
    );
  }

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'textArabic': textArabic,
      'textRussian': textRussian,
      'audioUrl': audioUrl,
      'hasRubElHizb': hasRubElHizb,
    };
  }

  /// Получить арабский текст с символом Руб-эль-Хизб (۞)
  String get displayArabic {
    return hasRubElHizb ? '$textArabic ۞' : textArabic;
  }

  /// Получить текст для поделиться
  String toShareText(String surahName, int surahNumber) {
    return 'Сура $surahNumber: $surahName, аят $number\n\n'
        '$displayArabic\n\n'
        '$textRussian\n\n'
        '— EasyHajj';
  }
}

/// Модель суры
class Surah {
  final int number;
  final String nameArabic;
  final String nameRussian;
  final String meaning;
  final int ayahCount;
  final String revelation;
  final List<Ayah> ayahs;
  final Color color;

  Surah({
    required this.number,
    required this.nameArabic,
    required this.nameRussian,
    required this.meaning,
    required this.ayahCount,
    required this.revelation,
    required this.ayahs,
    required this.color,
  });

  /// Создать из JSON
  factory Surah.fromJson(Map<String, dynamic> json, Color color) {
    return Surah(
      number: json['number'] as int,
      nameArabic: json['nameArabic'] as String,
      nameRussian: json['nameRussian'] as String,
      meaning: json['meaning'] as String,
      ayahCount: json['ayahCount'] as int,
      revelation: json['revelation'] as String,
      ayahs: (json['ayahs'] as List)
          .map((ayahJson) => Ayah.fromJson(ayahJson as Map<String, dynamic>))
          .toList(),
      color: color,
    );
  }

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'nameArabic': nameArabic,
      'nameRussian': nameRussian,
      'meaning': meaning,
      'ayahCount': ayahCount,
      'revelation': revelation,
      'ayahs': ayahs.map((ayah) => ayah.toJson()).toList(),
    };
  }

  /// Получить полное название
  String get fullName => '$nameRussian ($meaning)';

  /// Получить информацию об аятах
  String get ayahInfo => '$ayahCount ${_getAyahWord(ayahCount)}';

  /// Склонение слова "аят"
  String _getAyahWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'аят';
    } else if ([2, 3, 4].contains(count % 10) && 
               ![12, 13, 14].contains(count % 100)) {
      return 'аята';
    } else {
      return 'аятов';
    }
  }
}

