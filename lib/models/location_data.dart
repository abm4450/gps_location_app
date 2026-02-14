/// نموذج بيانات الموقع الشامل
class LocationData {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final DateTime? timestamp;
  final String? address;
  final String? error;
  final LocationSource source;
  final bool? isMocked;

  LocationData({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.timestamp,
    this.address,
    this.error,
    required this.source,
    this.isMocked,
  });

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasError => error != null && error!.isNotEmpty;

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    DateTime? timestamp,
    String? address,
    String? error,
    LocationSource? source,
    bool? isMocked,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      address: address ?? this.address,
      error: error ?? this.error,
      source: source ?? this.source,
      isMocked: isMocked ?? this.isMocked,
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, source: $source, mocked: $isMocked)';
  }
}

/// مصدر الموقع
enum LocationSource {
  gps,
  wifi,
  cellular,
  network,
  fused,
  ip,
  unknown,
}

extension LocationSourceExtension on LocationSource {
  String get arabicName {
    switch (this) {
      case LocationSource.gps:
        return 'GPS (الأقمار الصناعية)';
      case LocationSource.wifi:
        return 'الواي فاي';
      case LocationSource.cellular:
        return 'الشبكة الخلوية';
      case LocationSource.network:
        return 'الشبكة';
      case LocationSource.fused:
        return 'مدمج';
      case LocationSource.ip:
        return 'عنوان IP';
      case LocationSource.unknown:
        return 'غير معروف';
    }
  }

  String get icon {
    switch (this) {
      case LocationSource.gps:
        return '🛰️';
      case LocationSource.wifi:
        return '📶';
      case LocationSource.cellular:
        return '📱';
      case LocationSource.network:
        return '🌐';
      case LocationSource.fused:
        return '📍';
      case LocationSource.ip:
        return '🌍';
      case LocationSource.unknown:
        return '❓';
    }
  }
}
