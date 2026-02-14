import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../models/network_data.dart';
import '../models/location_data.dart';
import 'native_location_service.dart';
import 'ip_location_service.dart';
import 'cell_tower_location_service.dart';

/// خدمة معلومات الشبكة الخلوية وتقدير الموقع
/// تستخدم OpenCelliD API + Native Platform Channel + IP Geolocation
class CellularLocationService {
  final IpLocationService _ipService = IpLocationService();
  final CellTowerLocationService _cellTowerService = CellTowerLocationService();

  /// التحقق من الصلاحيات
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.location,
          Permission.phone,
        ].request();
        return statuses[Permission.location] == PermissionStatus.granted;
      }

      if (Platform.isIOS) {
        var status = await Permission.location.status;
        if (status.isDenied) {
          status = await Permission.location.request();
        }
        return status.isGranted;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على معلومات البرج الخلوي الحقيقية من TelephonyManager
  /// + تحديد موقع البرج عبر OpenCelliD API
  Future<CellTowerData> getCellTowerInfo() async {
    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        return CellTowerData(
          isConnected: false,
          error: 'لم يتم منح صلاحية الهاتف',
        );
      }

      if (Platform.isAndroid) {
        // الحصول على بيانات البرج من Native
        CellTowerData cellData = await NativeLocationService.getCellTowerInfo();

        // تحديد موقع البرج عبر OpenCelliD
        if (cellData.cellId != null && cellData.lac != null && cellData.mcc != null) {
          try {
            final towerResult = await _cellTowerService.getCellTowerLocation(cellData);
            if (towerResult.hasLocation) {
              cellData = cellData.copyWithTowerLocation(
                towerLatitude: towerResult.latitude,
                towerLongitude: towerResult.longitude,
                towerRange: towerResult.range,
              );
            }
          } catch (_) {
            // فشل تحديد موقع البرج - نكمل ببيانات البرج الأساسية
          }
        }

        return cellData;
      }

      if (Platform.isIOS) {
        return CellTowerData(
          isConnected: true,
          error: 'iOS لا يسمح بالوصول لمعلومات البرج الخلوي مباشرة',
        );
      }

      return CellTowerData(
        isConnected: false,
        error: 'منصة غير مدعومة',
      );
    } catch (e) {
      return CellTowerData(
        isConnected: false,
        error: 'حدث خطأ: ${e.toString()}',
      );
    }
  }

  /// تقدير الموقع عبر الشبكة الخلوية
  /// ترتيب الأولوية:
  /// 1. OpenCelliD API (دقة 100-500م) - الأدق
  /// 2. Native Network Provider (دقة 50-500م)
  /// 3. IP Geolocation (دقة 5-50 كم) - البديل الأخير
  Future<LocationData> getCellularBasedLocation() async {
    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        return LocationData(
          source: LocationSource.cellular,
          error: 'لم يتم منح الصلاحيات المطلوبة',
        );
      }

      if (Platform.isAndroid) {
        // المحاولة الأولى: OpenCelliD API (الأدق - 100-500م)
        try {
          final cellData = await NativeLocationService.getCellTowerInfo();
          if (cellData.cellId != null && cellData.lac != null && cellData.mcc != null) {
            final towerResult = await _cellTowerService.getCellTowerLocation(cellData);
            if (towerResult.hasLocation) {
              return LocationData(
                latitude: towerResult.latitude,
                longitude: towerResult.longitude,
                accuracy: towerResult.range?.toDouble(),
                source: LocationSource.cellular,
                timestamp: DateTime.now(),
                address: 'موقع البرج الخلوي (${towerResult.source})',
              );
            }
          }
        } catch (_) {
          // فشل OpenCelliD، ننتقل للبديل
        }

        // المحاولة الثانية: Native Network Provider (50-500م)
        try {
          final networkLocation =
              await NativeLocationService.getNetworkProviderLocation();
          if (networkLocation.hasLocation) {
            return networkLocation.copyWith(source: LocationSource.cellular);
          }
        } catch (_) {
          // فشل Network Provider، ننتقل للبديل
        }
      }

      // المحاولة الثالثة: IP Geolocation (5-50 كم - البديل الأخير)
      final ipData = await _ipService.getIpLocation();
      if (ipData.hasLocation) {
        return LocationData(
          latitude: ipData.latitude,
          longitude: ipData.longitude,
          source: LocationSource.cellular,
          timestamp: DateTime.now(),
          address: _formatLocationAddress(ipData),
        );
      }

      return LocationData(
        source: LocationSource.cellular,
        error: ipData.error ?? 'تعذر تحديد الموقع عبر الشبكة الخلوية',
      );
    } catch (e) {
      return LocationData(
        source: LocationSource.cellular,
        error: 'تعذر تحديد الموقع عبر الشبكة الخلوية: $e',
      );
    }
  }

  String _formatLocationAddress(IpLocationData data) {
    List<String> parts = [];
    if (data.city != null) parts.add(data.city!);
    if (data.regionName != null) parts.add(data.regionName!);
    if (data.country != null) parts.add(data.country!);
    return parts.join('، ');
  }
}
