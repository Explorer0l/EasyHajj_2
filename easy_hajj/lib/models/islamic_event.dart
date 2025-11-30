import 'package:flutter/material.dart';

/// Модель исламского события/праздника
class IslamicEvent {
  final String name;
  final String nameEn;
  final DateTime gregorianDate;
  final String hijriDate;
  final IslamicEventType type;
  final String? description;

  IslamicEvent({
    required this.name,
    required this.nameEn,
    required this.gregorianDate,
    required this.hijriDate,
    required this.type,
    this.description,
  });

  /// Получить иконку для типа события
  IconData get icon {
    switch (type) {
      case IslamicEventType.ramadan:
        return Icons.nightlight_round;
      case IslamicEventType.eidAlFitr:
        return Icons.celebration;
      case IslamicEventType.eidAlAdha:
        return Icons.mosque;
      case IslamicEventType.hijriNewYear:
        return Icons.today;
      case IslamicEventType.mawlid:
        return Icons.auto_awesome;
      case IslamicEventType.isra:
        return Icons.star;
      case IslamicEventType.lalatulBaraat:
        return Icons.wb_twilight;
      case IslamicEventType.laylatulQadr:
        return Icons.stars;
      case IslamicEventType.ashura:
        return Icons.water_drop;
      case IslamicEventType.arafat:
        return Icons.landscape;
      case IslamicEventType.other:
        return Icons.event;
    }
  }

  /// Получить цвет для типа события
  Color get color {
    switch (type) {
      case IslamicEventType.ramadan:
        return const Color(0xFF9B59B6);
      case IslamicEventType.eidAlFitr:
      case IslamicEventType.eidAlAdha:
        return const Color(0xFFE74C3C);
      case IslamicEventType.hijriNewYear:
        return const Color(0xFF3498DB);
      case IslamicEventType.mawlid:
        return const Color(0xFF2ECC71);
      case IslamicEventType.isra:
      case IslamicEventType.laylatulQadr:
        return const Color(0xFFFDB954);
      case IslamicEventType.lalatulBaraat:
        return const Color(0xFF5DBFB3);
      case IslamicEventType.ashura:
        return const Color(0xFF34495E);
      case IslamicEventType.arafat:
        return const Color(0xFF16A085);
      case IslamicEventType.other:
        return const Color(0xFF95A5A6);
    }
  }

  factory IslamicEvent.fromJson(Map<String, dynamic> json) {
    return IslamicEvent(
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      gregorianDate: DateTime.parse(json['gregorianDate'] as String),
      hijriDate: json['hijriDate'] as String,
      type: parseEventType(json['type'] as String?),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameEn': nameEn,
      'gregorianDate': gregorianDate.toIso8601String(),
      'hijriDate': hijriDate,
      'type': type.name,
      'description': description,
    };
  }

  static IslamicEventType parseEventType(String? type) {
    if (type == null) return IslamicEventType.other;
    
    switch (type.toLowerCase()) {
      case 'ramadan':
        return IslamicEventType.ramadan;
      case 'eid_al_fitr':
      case 'eidalfitr':
        return IslamicEventType.eidAlFitr;
      case 'eid_al_adha':
      case 'eidaladha':
        return IslamicEventType.eidAlAdha;
      case 'hijri_new_year':
      case 'newyear':
        return IslamicEventType.hijriNewYear;
      case 'mawlid':
      case 'mawlid_al_nabi':
        return IslamicEventType.mawlid;
      case 'isra':
      case 'isra_and_miraj':
        return IslamicEventType.isra;
      case 'lailatul_baraat':
      case 'shaban':
        return IslamicEventType.lalatulBaraat;
      case 'laylatul_qadr':
      case 'qadr':
        return IslamicEventType.laylatulQadr;
      case 'ashura':
        return IslamicEventType.ashura;
      case 'arafat':
        return IslamicEventType.arafat;
      default:
        return IslamicEventType.other;
    }
  }
}

/// Тип исламского события
enum IslamicEventType {
  ramadan,          // Начало Рамадана
  eidAlFitr,        // Ураза-байрам
  eidAlAdha,        // Курбан-байрам
  hijriNewYear,     // Исламский новый год
  mawlid,           // Маулид (день рождения Пророка)
  isra,             // Ночь Мирадж (Исра и Мирадж)
  lalatulBaraat,    // Ночь Бараат (15 Шабан)
  laylatulQadr,     // Ночь Кадр (Лейлятуль-Кадр)
  ashura,           // День Ашура (10 Мухаррам)
  arafat,           // День Арафат
  other,            // Другое событие
}

