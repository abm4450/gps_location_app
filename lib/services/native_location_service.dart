import 'dart:io';
import 'package:flutter/services.dart';
import '../models/location_data.dart';
import '../models/network_data.dart';

/// خدمة الوصول المباشر لنظام أندرويد عبر Platform Channel
/// تتجاوز Fused Location Provider للحصول على بيانات حقيقية
class NativeLocationService {
  static const MethodChannel _channel =
      MethodChannel('location_spoof_detector/native');

  /// الحصول على بيانات البرج الخلوي الحقيقية من TelephonyManager
  static Future<CellTowerData> getCellTowerInfo() async {
    if (!Platform.isAndroid) {
      return CellTowerData(
        isConnected: false,
        error: 'متاح فقط على أندرويد',
      );
    }

    try {
      final dynamic raw = await _channel.invokeMethod('getCellTowerInfo');
      if (raw is! Map) {
        return CellTowerData(isConnected: false, error: 'بيانات غير صالحة');
      }

      final Map<dynamic, dynamic> result = raw;

      return CellTowerData(
        cellId: result['cellId'] as int?,
        lac: result['lac'] as int?,
        mcc: result['mcc'] as int?,
        mnc: result['mnc'] as int?,
        networkOperator: result['operatorName'] as String?,
        networkType: result['type'] as String?,
        signalStrength: result['signalStrength'] as int?,
        isConnected: true,
        error: result['error'] as String?,
      );
    } on PlatformException catch (e) {
      return CellTowerData(
        isConnected: false,
        error: 'خطأ في النظام: ${e.message}',
      );
    } catch (e) {
      return CellTowerData(
        isConnected: false,
        error: 'حدث خطأ: $e',
      );
    }
  }

  /// الحصول على الموقع من Android LocationManager NETWORK_PROVIDER
  /// يتجاوز Fused Location Provider
  static Future<LocationData> getNetworkProviderLocation() async {
    if (!Platform.isAndroid) {
      return LocationData(
        source: LocationSource.network,
        error: 'متاح فقط على أندرويد',
      );
    }

    try {
      final dynamic raw =
          await _channel.invokeMethod('getNetworkProviderLocation');
      if (raw is! Map) {
        return LocationData(
          source: LocationSource.network,
          error: 'بيانات غير صالحة',
        );
      }

      final Map<dynamic, dynamic> result = raw;

      return LocationData(
        latitude: result['latitude'] as double?,
        longitude: result['longitude'] as double?,
        accuracy: result['accuracy'] as double?,
        isMocked: result['isMocked'] as bool?,
        source: LocationSource.network,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (result['time'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } on PlatformException catch (e) {
      return LocationData(
        source: LocationSource.network,
        error: e.message ?? 'تعذر الحصول على موقع الشبكة',
      );
    } catch (e) {
      return LocationData(
        source: LocationSource.network,
        error: 'حدث خطأ: $e',
      );
    }
  }

  /// الحصول على قوة إشارة الواي فاي (RSSI)
  static Future<int?> getWifiSignalStrength() async {
    if (!Platform.isAndroid) return null;

    try {
      return await _channel.invokeMethod<int>('getWifiSignalStrength');
    } catch (_) {
      return null;
    }
  }
}
