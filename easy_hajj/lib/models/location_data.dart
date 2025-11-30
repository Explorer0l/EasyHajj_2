/// Модель данных о местоположении
class LocationData {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    required this.timestamp,
  });

  /// Преобразование в JSON для хранения
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Создание из JSON
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      city: json['city'] as String?,
      country: json['country'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Проверка, актуальна ли геолокация (не старше 1 дня)
  bool isValid() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours < 24;
  }

  /// Копирование с изменением полей
  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    DateTime? timestamp,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, city: $city, country: $country)';
  }
}

