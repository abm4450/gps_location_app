import 'dart:io';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../models/network_data.dart';
import '../models/location_data.dart';
import 'ip_location_service.dart';

/// خدمة معلومات الواي فاي وتقدير الموقع
/// تستخدم IP Geolocation بدلاً من Fused Location Provider للحصول على موقع مستقل
class WifiLocationService {
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();
  final IpLocationService _ipService = IpLocationService();

  /// التحقق من الصلاحيات
  Future<bool> requestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      if (Platform.isAndroid) {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.location,
          Permission.locationWhenInUse,
        ].request();
        return statuses.values.every((s) => s == PermissionStatus.granted);
      }

      if (Platform.isIOS) {
        var status = await Permission.locationWhenInUse.status;
        if (status.isDenied) {
          status = await Permission.locationWhenInUse.request();
        }
        return status.isGranted;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// التحقق من الاتصال بالواي فاي
  Future<bool> isConnectedToWifi() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.contains(ConnectivityResult.wifi);
    } catch (e) {
      return false;
    }
  }

  /// الحصول على معلومات الواي فاي
  Future<WifiData> getWifiInfo() async {
    try {
      bool isConnected = await isConnectedToWifi();
      if (!isConnected) {
        return WifiData(
          isConnected: false,
          error: 'الجهاز غير متصل بشبكة واي فاي',
        );
      }

      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        return WifiData(
          isConnected: true,
          error: serviceEnabled
              ? 'يجب منح صلاحية الموقع للوصول لمعلومات الواي فاي'
              : 'يجب تفعيل خدمة الموقع',
        );
      }

      String? ssid;
      String? bssid;
      String? ipAddress;
      String? gateway;
      String? subnet;
      String? broadcast;

      try {
        ssid = await _networkInfo.getWifiName();
        if (ssid != null) {
          ssid = ssid.replaceAll('"', '').replaceAll('<', '').replaceAll('>', '');
          if (ssid.isEmpty || ssid == 'unknown') ssid = null;
        }
      } catch (_) {}

      try {
        bssid = await _networkInfo.getWifiBSSID();
        if (bssid == '02:00:00:00:00:00') bssid = null;
      } catch (_) {}

      try { ipAddress = await _networkInfo.getWifiIP(); } catch (_) {}
      try { gateway = await _networkInfo.getWifiGatewayIP(); } catch (_) {}
      try { subnet = await _networkInfo.getWifiSubmask(); } catch (_) {}
      try { broadcast = await _networkInfo.getWifiBroadcast(); } catch (_) {}

      if (ssid == null && bssid == null && ipAddress == null) {
        return WifiData(
          isConnected: true,
          error: 'تعذر جلب معلومات الشبكة',
        );
      }

      return WifiData(
        ssid: ssid,
        bssid: bssid,
        ipAddress: ipAddress,
        gateway: gateway,
        subnet: subnet,
        broadcast: broadcast,
        isConnected: true,
      );
    } on PlatformException catch (e) {
      return WifiData(
        isConnected: false,
        error: 'خطأ في النظام: ${e.message}',
      );
    } catch (e) {
      return WifiData(
        isConnected: false,
        error: 'حدث خطأ: ${e.toString()}',
      );
    }
  }

  /// تقدير الموقع عبر الواي فاي باستخدام IP Geolocation
  /// مستقل تماماً عن GPS و Fused Location Provider
  Future<LocationData> getWifiBasedLocation() async {
    try {
      bool isConnected = await isConnectedToWifi();
      if (!isConnected) {
        return LocationData(
          source: LocationSource.wifi,
          error: 'غير متصل بشبكة واي فاي',
        );
      }

      // استخدام IP Geolocation - مستقل تماماً عن GPS
      // عنوان IP يعكس الموقع الحقيقي للشبكة المتصلة
      final ipData = await _ipService.getIpLocation();

      if (ipData.hasLocation) {
        return LocationData(
          latitude: ipData.latitude,
          longitude: ipData.longitude,
          source: LocationSource.wifi,
          timestamp: DateTime.now(),
          address: _formatLocationAddress(ipData),
        );
      }

      return LocationData(
        source: LocationSource.wifi,
        error: ipData.error ?? 'تعذر تحديد الموقع عبر الواي فاي',
      );
    } catch (e) {
      return LocationData(
        source: LocationSource.wifi,
        error: 'تعذر تحديد الموقع عبر الواي فاي: $e',
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

  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;
}
