import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_data.dart';
import '../models/network_data.dart';

/// خدمة تحديد الموقع الجغرافي للبرج الخلوي
/// تحول بيانات البرج (CellID, LAC, MCC, MNC) إلى إحداثيات حقيقية
/// الدقة: 100-500 متر (أفضل بكثير من IP geolocation)
class CellTowerLocationService {
  /// ==========================================
  /// مفتاح OpenCelliD API (مجاني)
  /// سجل مجاناً في: https://opencellid.org
  /// واستبدل هذا المفتاح بمفتاحك الخاص
  /// ==========================================
  static const String _openCellIdApiKey = 'pk.5edb66aba0f1be6d51991a82803e12ec';

  /// تحديد موقع البرج الخلوي من بياناته
  /// يستخدم OpenCelliD أولاً، ثم BeaconDB كبديل
  Future<CellTowerLocationResult> getCellTowerLocation(CellTowerData cellData) async {
    if (cellData.mcc == null || cellData.mnc == null) {
      return CellTowerLocationResult(
        error: 'بيانات البرج الخلوي غير مكتملة (MCC/MNC مفقود)',
      );
    }

    // المحاولة الأولى: OpenCelliD API (الأدق)
    if (cellData.cellId != null && cellData.lac != null) {
      final result = await _lookupOpenCelliD(cellData);
      if (result.hasLocation) return result;
    }

    // المحاولة الثانية: BeaconDB (بديل مجاني بدون مفتاح)
    if (cellData.cellId != null && cellData.lac != null) {
      final result = await _lookupBeaconDB(cellData);
      if (result.hasLocation) return result;
    }

    return CellTowerLocationResult(
      error: 'تعذر تحديد موقع البرج الخلوي',
    );
  }

  /// OpenCelliD API - الأساسي (مجاني، 1000 طلب/يوم)
  Future<CellTowerLocationResult> _lookupOpenCelliD(CellTowerData cellData) async {
    try {
      final uri = Uri.parse(
        'https://opencellid.org/cell/get'
        '?key=$_openCellIdApiKey'
        '&mcc=${cellData.mcc}'
        '&mnc=${cellData.mnc}'
        '&lac=${cellData.lac}'
        '&cellid=${cellData.cellId}'
        '&format=json',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // التحقق من وجود خطأ في الاستجابة
        if (data['error'] != null) {
          return CellTowerLocationResult(
            error: 'OpenCelliD: ${data['error']}',
          );
        }

        final lat = (data['lat'] as num?)?.toDouble();
        final lon = (data['lon'] as num?)?.toDouble();

        if (lat != null && lon != null) {
          return CellTowerLocationResult(
            latitude: lat,
            longitude: lon,
            range: (data['range'] as num?)?.toInt(),
            source: 'OpenCelliD',
          );
        }
      }

      return CellTowerLocationResult(
        error: 'OpenCelliD: استجابة غير صالحة (${response.statusCode})',
      );
    } catch (e) {
      return CellTowerLocationResult(
        error: 'OpenCelliD: $e',
      );
    }
  }

  /// BeaconDB API - بديل مجاني بدون مفتاح (بيانات MLS القديمة)
  Future<CellTowerLocationResult> _lookupBeaconDB(CellTowerData cellData) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.beacondb.net/v1/geolocate'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'LocationSpoofDetector/1.0',
        },
        body: json.encode({
          'cellTowers': [
            {
              'mobileCountryCode': cellData.mcc,
              'mobileNetworkCode': cellData.mnc,
              'locationAreaCode': cellData.lac,
              'cellId': cellData.cellId,
              if (cellData.networkType != null)
                'radioType': _radioTypeFromNetworkType(cellData.networkType!),
            }
          ],
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['location'];

        if (location != null) {
          final lat = (location['lat'] as num?)?.toDouble();
          final lng = (location['lng'] as num?)?.toDouble();
          final accuracy = (data['accuracy'] as num?)?.toDouble();

          if (lat != null && lng != null) {
            return CellTowerLocationResult(
              latitude: lat,
              longitude: lng,
              range: accuracy?.toInt(),
              source: 'BeaconDB',
            );
          }
        }
      }

      return CellTowerLocationResult(
        error: 'BeaconDB: استجابة غير صالحة (${response.statusCode})',
      );
    } catch (e) {
      return CellTowerLocationResult(
        error: 'BeaconDB: $e',
      );
    }
  }

  /// تحويل نوع الشبكة إلى radioType المطلوب
  String _radioTypeFromNetworkType(String type) {
    switch (type.toUpperCase()) {
      case 'GSM':
        return 'gsm';
      case 'WCDMA':
      case 'UMTS':
        return 'wcdma';
      case 'LTE':
        return 'lte';
      case 'NR':
        return 'nr';
      default:
        return 'gsm';
    }
  }

  /// تحويل النتيجة إلى LocationData
  LocationData toLocationData(CellTowerLocationResult result) {
    if (result.hasLocation) {
      return LocationData(
        latitude: result.latitude,
        longitude: result.longitude,
        accuracy: result.range?.toDouble(),
        source: LocationSource.cellular,
        timestamp: DateTime.now(),
        address: 'موقع البرج الخلوي (${result.source})',
      );
    }
    return LocationData(
      source: LocationSource.cellular,
      error: result.error ?? 'تعذر تحديد موقع البرج',
    );
  }
}

/// نتيجة تحديد موقع البرج الخلوي
class CellTowerLocationResult {
  final double? latitude;
  final double? longitude;
  final int? range; // نطاق التغطية بالمتر
  final String? source; // OpenCelliD أو BeaconDB
  final String? error;

  CellTowerLocationResult({
    this.latitude,
    this.longitude,
    this.range,
    this.source,
    this.error,
  });

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasError => error != null && error!.isNotEmpty;
}
