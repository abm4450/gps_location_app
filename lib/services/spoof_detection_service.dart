import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:root_check_flutter/root_check_flutter.dart';
import '../models/location_data.dart';
import '../models/spoof_result.dart';
import 'gps_service.dart';
import 'wifi_service.dart';
import 'cellular_service.dart';
import 'ip_location_service.dart';
import 'native_spoof_check.dart';

/// خدمة كشف تزوير الموقع
/// تستخدم مصادر مستقلة (IP, Native Network Provider) بدلاً من Fused Location Provider
class SpoofDetectionService {
  final GpsLocationService _gpsService = GpsLocationService();
  final WifiLocationService _wifiService = WifiLocationService();
  final CellularLocationService _cellularService = CellularLocationService();
  final IpLocationService _ipService = IpLocationService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// حد التحذير: GPS vs البرج الخلوي / Network Provider (بالمتر)
  static const double towerWarningDistance = 2000; // 2 كم - تحذير

  /// حد الحرج: GPS vs البرج الخلوي / Network Provider (بالمتر)
  static const double towerCriticalDistance = 5000; // 5 كم - حرج

  /// حد IP: GPS vs IP (بالمتر) - IP أقل دقة
  static const double maxIpDistance = 50000; // 50 كم

  /// الحد الأقصى للدقة المشبوهة
  static const double suspiciousAccuracy = 5; // 5 متر (دقة مثالية جداً)

  /// إجراء فحص شامل للتزوير
  Future<SpoofDetectionResult> performFullCheck() async {
    List<SpoofIndicator> indicators = [];
    bool isRooted = false;
    List<String> installedSpoofingApps = [];

    // 0. كشف الروت وتطبيقات التزوير المعروفة (أندرويد فقط - غير مدعوم على الويب)
    if (!kIsWeb && Platform.isAndroid) {
      try {
        isRooted = await RootCheckFlutter.isDeviceRooted;
      } catch (_) {}
      if (isRooted) {
        indicators.add(SpoofIndicator(
          title: 'الجهاز مُروت (Root)',
          description: 'الجهاز مُروت - احتمال التزوير أعلى',
          severity: IndicatorSeverity.warning,
          source: 'النظام',
        ));
      }
      try {
        installedSpoofingApps = await NativeSpoofCheck.checkKnownSpoofingApps();
        if (installedSpoofingApps.isNotEmpty) {
          indicators.add(SpoofIndicator(
            title: 'تطبيق تغيير موقع معروف مُثبت',
            description: 'تم العثور على: ${installedSpoofingApps.join(", ")}',
            severity: IndicatorSeverity.critical,
            source: 'النظام',
          ));
        }
      } catch (_) {}
    }

    // 1. جلب الموقع من جميع المصادر (مصادر مستقلة)
    final gpsLocation = await _gpsService.getGpsOnlyLocation();
    final wifiLocation = await _wifiService.getWifiBasedLocation();
    final cellularLocation = await _cellularService.getCellularBasedLocation();
    final wifiData = await _wifiService.getWifiInfo();
    final cellData = await _cellularService.getCellTowerInfo();

    // 1.1 جلب موقع IP المستقل (أهم فحص - لا يمكن تزويره بتطبيقات Mock Location)
    final ipData = await _ipService.getIpLocation();
    final ipLocation = _ipService.ipDataToLocationData(ipData);

    // 2. التحقق من علامة isMocked
    if (gpsLocation.isMocked == true) {
      indicators.add(SpoofIndicator(
        title: 'تم اكتشاف Mock Location',
        description: 'النظام يشير إلى أن الموقع مُزيف',
        severity: IndicatorSeverity.critical,
        source: 'GPS',
      ));
    } else if (gpsLocation.hasLocation && gpsLocation.isMocked == false) {
      indicators.add(SpoofIndicator(
        title: 'لا يوجد Mock Location نشط',
        description: 'النظام يشير إلى أن الموقع حقيقي',
        severity: IndicatorSeverity.safe,
        source: 'GPS',
      ));
    }

    // 3. التحقق من تطبيقات التزوير (Android)
    if (!kIsWeb && Platform.isAndroid) {
      bool hasMockApps = await _checkForMockLocationApps();
      if (hasMockApps) {
        indicators.add(SpoofIndicator(
          title: 'وضع المطور - Mock Location',
          description: 'تم تفعيل خيار Mock Location في إعدادات المطور',
          severity: IndicatorSeverity.warning,
          source: 'النظام',
        ));
      }
    }

    // 4. مقارنة GPS مع موقع IP (الفحص الأهم - مستقل تماماً)
    if (gpsLocation.hasLocation && ipLocation.hasLocation) {
      double distance = _calculateDistance(gpsLocation, ipLocation);
      if (distance > maxIpDistance) {
        indicators.add(SpoofIndicator(
          title: 'فرق كبير بين GPS وموقع IP',
          description: 'المسافة: ${(distance / 1000).toStringAsFixed(0)} كم - GPS يشير لموقع مختلف عن شبكة الإنترنت',
          severity: IndicatorSeverity.critical,
          source: 'GPS مقابل IP',
        ));
      } else {
        indicators.add(SpoofIndicator(
          title: 'تطابق GPS مع موقع IP',
          description: 'المسافة: ${(distance / 1000).toStringAsFixed(0)} كم',
          severity: IndicatorSeverity.safe,
          source: 'GPS مقابل IP',
        ));
      }
    }

    // 4.1 كشف VPN/Proxy
    if (ipData.isProxy == true) {
      indicators.add(SpoofIndicator(
        title: 'تم اكتشاف VPN/Proxy',
        description: 'الجهاز متصل عبر VPN - موقع IP قد لا يكون دقيقاً',
        severity: IndicatorSeverity.warning,
        source: 'IP',
      ));
    }

    if (ipData.isHosting == true) {
      indicators.add(SpoofIndicator(
        title: 'عنوان IP من مركز بيانات',
        description: 'عنوان IP ينتمي لمركز بيانات وليس مزود إنترنت عادي',
        severity: IndicatorSeverity.warning,
        source: 'IP',
      ));
    }

    // 5. مقارنة المسافة بين GPS و WiFi (مستقل عبر IP)
    if (gpsLocation.hasLocation && wifiLocation.hasLocation) {
      double distance = _calculateDistance(gpsLocation, wifiLocation);
      if (distance > maxIpDistance) {
        indicators.add(SpoofIndicator(
          title: 'فرق كبير بين GPS و WiFi',
          description: 'المسافة: ${(distance / 1000).toStringAsFixed(0)} كم',
          severity: IndicatorSeverity.critical,
          source: 'مقارنة المصادر',
        ));
      } else if (distance > towerCriticalDistance) {
        indicators.add(SpoofIndicator(
          title: 'فرق ملحوظ بين GPS و WiFi',
          description: 'المسافة: ${(distance / 1000).toStringAsFixed(1)} كم',
          severity: IndicatorSeverity.warning,
          source: 'مقارنة المصادر',
        ));
      } else {
        indicators.add(SpoofIndicator(
          title: 'تطابق GPS و WiFi',
          description: 'المسافة: ${distance.toStringAsFixed(0)} متر',
          severity: IndicatorSeverity.safe,
          source: 'مقارنة المصادر',
        ));
      }
    }

    // 6. مقارنة المسافة بين GPS و Cellular (مستقل عبر OpenCelliD/Network Provider/IP)
    if (gpsLocation.hasLocation && cellularLocation.hasLocation) {
      double distance = _calculateDistance(gpsLocation, cellularLocation);
      if (distance > towerCriticalDistance) {
        indicators.add(SpoofIndicator(
          title: 'فرق كبير بين GPS والشبكة الخلوية',
          description: 'المسافة: ${(distance / 1000).toStringAsFixed(1)} كم',
          severity: IndicatorSeverity.critical,
          source: 'مقارنة المصادر',
        ));
      } else if (distance > towerWarningDistance) {
        indicators.add(SpoofIndicator(
          title: 'فرق ملحوظ بين GPS والشبكة الخلوية',
          description: 'المسافة: ${(distance / 1000).toStringAsFixed(1)} كم',
          severity: IndicatorSeverity.warning,
          source: 'مقارنة المصادر',
        ));
      }
    }

    // 7. فحص MCC (كود الدولة من البرج الخلوي)
    if (gpsLocation.hasLocation && cellData.mcc != null) {
      final gpsCountryMcc = _getExpectedMcc(gpsLocation.latitude!, gpsLocation.longitude!);
      if (gpsCountryMcc != null && gpsCountryMcc != cellData.mcc) {
        indicators.add(SpoofIndicator(
          title: 'عدم تطابق كود الدولة الخلوي (MCC)',
          description: 'GPS يشير لدولة مختلفة عن شبكة الاتصالات (MCC: ${cellData.mcc})',
          severity: IndicatorSeverity.critical,
          source: 'الشبكة الخلوية',
        ));
      }
    }

    // 7.1 فحص GPS vs موقع البرج الخلوي (OpenCelliD) - الفحص الأدق
    // دقة 100-500 متر - يكشف التزوير داخل نفس المدينة
    if (gpsLocation.hasLocation && cellData.hasTowerLocation) {
      final towerLocation = LocationData(
        latitude: cellData.towerLatitude,
        longitude: cellData.towerLongitude,
        source: LocationSource.cellular,
      );
      double distance = _calculateDistance(gpsLocation, towerLocation);

      if (distance > towerCriticalDistance) {
        indicators.add(SpoofIndicator(
          title: 'GPS بعيد عن البرج الخلوي',
          description: 'المسافة: ${(distance / 1000).toStringAsFixed(1)} كم عن البرج الخلوي المتصل',
          severity: IndicatorSeverity.critical,
          source: 'GPS مقابل البرج',
        ));
      } else if (distance > towerWarningDistance) {
        indicators.add(SpoofIndicator(
          title: 'فرق ملحوظ بين GPS والبرج الخلوي',
          description: 'المسافة: ${(distance / 1000).toStringAsFixed(1)} كم عن البرج الخلوي',
          severity: IndicatorSeverity.warning,
          source: 'GPS مقابل البرج',
        ));
      } else {
        indicators.add(SpoofIndicator(
          title: 'تطابق GPS مع البرج الخلوي',
          description: 'المسافة: ${distance.toStringAsFixed(0)} متر (ضمن نطاق البرج)',
          severity: IndicatorSeverity.safe,
          source: 'GPS مقابل البرج',
        ));
      }
    }

    // 8. التحقق من الدقة المشبوهة
    if (gpsLocation.hasLocation && gpsLocation.accuracy != null) {
      if (gpsLocation.accuracy! < suspiciousAccuracy) {
        indicators.add(SpoofIndicator(
          title: 'دقة مثالية مشبوهة',
          description: 'الدقة ${gpsLocation.accuracy!.toStringAsFixed(1)} متر - نادرة في GPS الحقيقي',
          severity: IndicatorSeverity.warning,
          source: 'GPS',
        ));
      }
    }

    // 9. التحقق من الارتفاع
    if (gpsLocation.hasLocation) {
      if (gpsLocation.altitude == 0 || gpsLocation.altitude == null) {
        indicators.add(SpoofIndicator(
          title: 'لا يوجد بيانات ارتفاع',
          description: 'GPS الحقيقي عادة يوفر بيانات الارتفاع',
          severity: IndicatorSeverity.info,
          source: 'GPS',
        ));
      }
    }

    // 10. التحقق من السرعة
    if (gpsLocation.hasLocation && gpsLocation.speed != null) {
      if (gpsLocation.speed! > 0 && gpsLocation.speed! < 0.1) {
        indicators.add(SpoofIndicator(
          title: 'سرعة ثابتة مشبوهة',
          description: 'السرعة: ${gpsLocation.speed!.toStringAsFixed(2)} م/ث',
          severity: IndicatorSeverity.info,
          source: 'GPS',
        ));
      }
    }

    // 11. تحديد مستوى الثقة
    SpoofConfidence confidence = _calculateConfidence(indicators, isRooted, installedSpoofingApps);

    return SpoofDetectionResult(
      isSpoofed: confidence == SpoofConfidence.definitelySpoofed ||
                confidence == SpoofConfidence.likelySpoofed,
      confidence: confidence,
      indicators: indicators,
      gpsLocation: gpsLocation,
      wifiLocation: wifiLocation,
      cellularLocation: cellularLocation,
      ipLocation: ipLocation,
      wifiData: wifiData,
      cellData: cellData,
      ipData: ipData,
      timestamp: DateTime.now(),
      isRooted: isRooted,
      installedSpoofingApps: installedSpoofingApps,
    );
  }

  /// التحقق من وجود تطبيقات Mock Location
  Future<bool> _checkForMockLocationApps() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        return position.isMocked;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// حساب المسافة بين موقعين
  double _calculateDistance(LocationData loc1, LocationData loc2) {
    if (!loc1.hasLocation || !loc2.hasLocation) return 0;

    return Geolocator.distanceBetween(
      loc1.latitude!,
      loc1.longitude!,
      loc2.latitude!,
      loc2.longitude!,
    );
  }

  /// تقدير MCC المتوقع بناءً على الإحداثيات (تقريبي)
  int? _getExpectedMcc(double latitude, double longitude) {
    // السعودية: خطوط العرض 16-32، خطوط الطول 34-56
    if (latitude >= 16 && latitude <= 32 && longitude >= 34 && longitude <= 56) {
      return 420; // MCC السعودية
    }
    // الإمارات
    if (latitude >= 22 && latitude <= 26 && longitude >= 51 && longitude <= 56) {
      return 424;
    }
    // مصر
    if (latitude >= 22 && latitude <= 31.5 && longitude >= 25 && longitude <= 35) {
      return 602;
    }
    // البرازيل (كمثال للتزوير البعيد)
    if (latitude >= -33 && latitude <= 5 && longitude >= -74 && longitude <= -35) {
      return 724;
    }
    return null;
  }

  /// حساب مستوى الثقة بناءً على المؤشرات
  SpoofConfidence _calculateConfidence(
    List<SpoofIndicator> indicators, [
    bool isRooted = false,
    List<String> installedSpoofingApps = const [],
  ]) {
    int criticalCount = indicators.where((i) => i.severity == IndicatorSeverity.critical).length;
    int warningCount = indicators.where((i) => i.severity == IndicatorSeverity.warning).length;
    int safeCount = indicators.where((i) => i.severity == IndicatorSeverity.safe).length;

    if (installedSpoofingApps.isNotEmpty) {
      criticalCount += 1;
    }
    if (isRooted && criticalCount == 0 && warningCount == 0) {
      warningCount += 1;
    }

    if (criticalCount >= 2) {
      return SpoofConfidence.definitelySpoofed;
    } else if (criticalCount == 1) {
      return SpoofConfidence.likelySpoofed;
    } else if (warningCount >= 3) {
      return SpoofConfidence.likelySpoofed;
    } else if (warningCount >= 2) {
      return SpoofConfidence.possiblySpoofed;
    } else if (warningCount == 1) {
      if (safeCount >= 2) {
        return SpoofConfidence.probablyReal;
      }
      return SpoofConfidence.possiblySpoofed;
    } else if (safeCount >= 2) {
      return SpoofConfidence.definitelyReal;
    } else if (safeCount == 1) {
      return SpoofConfidence.probablyReal;
    }

    return SpoofConfidence.unknown;
  }

  /// الحصول على معلومات الجهاز
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return {
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'brand': androidInfo.brand,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'androidVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (!kIsWeb && Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return {
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      }
      return {};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
