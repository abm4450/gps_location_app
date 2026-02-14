/// نموذج بيانات البرج الخلوي
class CellTowerData {
  final int? cellId;
  final int? lac; // Location Area Code
  final int? mcc; // Mobile Country Code
  final int? mnc; // Mobile Network Code
  final String? networkOperator;
  final String? networkType;
  final int? signalStrength;
  final bool isConnected;
  final String? error;

  /// إحداثيات البرج الخلوي من OpenCelliD/BeaconDB
  final double? towerLatitude;
  final double? towerLongitude;
  final int? towerRange; // نطاق التغطية بالمتر

  CellTowerData({
    this.cellId,
    this.lac,
    this.mcc,
    this.mnc,
    this.networkOperator,
    this.networkType,
    this.signalStrength,
    this.isConnected = false,
    this.error,
    this.towerLatitude,
    this.towerLongitude,
    this.towerRange,
  });

  bool get hasData => cellId != null || networkOperator != null;
  bool get hasError => error != null && error!.isNotEmpty;
  bool get hasTowerLocation => towerLatitude != null && towerLongitude != null;

  /// نسخة مع إضافة موقع البرج
  CellTowerData copyWithTowerLocation({
    double? towerLatitude,
    double? towerLongitude,
    int? towerRange,
  }) {
    return CellTowerData(
      cellId: cellId,
      lac: lac,
      mcc: mcc,
      mnc: mnc,
      networkOperator: networkOperator,
      networkType: networkType,
      signalStrength: signalStrength,
      isConnected: isConnected,
      error: error,
      towerLatitude: towerLatitude ?? this.towerLatitude,
      towerLongitude: towerLongitude ?? this.towerLongitude,
      towerRange: towerRange ?? this.towerRange,
    );
  }

  @override
  String toString() {
    return 'CellTowerData(cellId: $cellId, operator: $networkOperator, type: $networkType, tower: $towerLatitude,$towerLongitude)';
  }
}

/// نموذج بيانات الواي فاي
class WifiData {
  final String? ssid;
  final String? bssid;
  final String? ipAddress;
  final String? gateway;
  final String? subnet;
  final String? broadcast;
  final int? signalStrength;
  final int? frequency;
  final bool isConnected;
  final String? error;

  WifiData({
    this.ssid,
    this.bssid,
    this.ipAddress,
    this.gateway,
    this.subnet,
    this.broadcast,
    this.signalStrength,
    this.frequency,
    this.isConnected = false,
    this.error,
  });

  bool get hasData => ssid != null || ipAddress != null;
  bool get hasError => error != null && error!.isNotEmpty;

  @override
  String toString() {
    return 'WifiData(ssid: $ssid, ip: $ipAddress, connected: $isConnected)';
  }
}

/// نموذج بيانات موقع IP
class IpLocationData {
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? country;
  final String? regionName;
  final String? isp;
  final String? ipAddress;
  final bool? isProxy;
  final bool? isHosting;
  final String? error;

  IpLocationData({
    this.latitude,
    this.longitude,
    this.city,
    this.country,
    this.regionName,
    this.isp,
    this.ipAddress,
    this.isProxy,
    this.isHosting,
    this.error,
  });

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasError => error != null && error!.isNotEmpty;

  @override
  String toString() {
    return 'IpLocationData(ip: $ipAddress, city: $city, country: $country)';
  }
}
