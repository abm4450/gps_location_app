import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_data.dart';

/// خدمة تحديد الموقع عبر GPS مع كشف التزوير
class GpsLocationService {
  
  /// التحقق من الصلاحيات
  Future<bool> requestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
      }

      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return status.isGranted;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  /// الحصول على الموقع عبر GPS فقط (بدون Network)
  Future<LocationData> getGpsOnlyLocation() async {
    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        return LocationData(
          source: LocationSource.gps,
          error: serviceEnabled 
              ? 'لم يتم منح صلاحية الموقع'
              : 'خدمة الموقع غير مفعلة',
        );
      }

      // استخدام دقة عالية للحصول على GPS فقط
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );

      // التحقق من التزوير
      bool isMocked = position.isMocked;

      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          address = _formatAddress(placemarks.first);
        }
      } catch (e) {
        print('Geocoding error: $e');
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: position.timestamp,
        address: address,
        source: LocationSource.gps,
        isMocked: isMocked,
      );
    } catch (e) {
      return LocationData(
        source: LocationSource.gps,
        error: _handleError(e),
      );
    }
  }

  /// الحصول على الموقع بدقة منخفضة (Network-based)
  Future<LocationData> getNetworkLocation() async {
    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        return LocationData(
          source: LocationSource.network,
          error: 'لم يتم منح صلاحية الموقع',
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.lowest, // يستخدم الشبكة
        timeLimit: const Duration(seconds: 15),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: position.timestamp,
        source: LocationSource.network,
        isMocked: position.isMocked,
      );
    } catch (e) {
      return LocationData(
        source: LocationSource.network,
        error: _handleError(e),
      );
    }
  }

  /// التحقق من وجود تطبيقات تزوير الموقع
  Future<bool> checkMockLocationEnabled() async {
    try {
      // في Android، يمكن التحقق من إعداد Mock Location
      if (Platform.isAndroid) {
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
  double calculateDistance(LocationData loc1, LocationData loc2) {
    if (!loc1.hasLocation || !loc2.hasLocation) return -1;
    
    return Geolocator.distanceBetween(
      loc1.latitude!,
      loc1.longitude!,
      loc2.latitude!,
      loc2.longitude!,
    );
  }

  String _formatAddress(Placemark place) {
    List<String> parts = [];
    if (place.street?.isNotEmpty == true) parts.add(place.street!);
    if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
    if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
    if (place.administrativeArea?.isNotEmpty == true) parts.add(place.administrativeArea!);
    if (place.country?.isNotEmpty == true) parts.add(place.country!);
    return parts.join('، ');
  }

  String _handleError(dynamic error) {
    if (error.toString().contains('Permission')) {
      return 'تم رفض صلاحية الوصول للموقع';
    } else if (error.toString().contains('disabled')) {
      return 'خدمة الموقع غير مفعلة';
    } else if (error.toString().contains('timeout')) {
      return 'انتهت المهلة - تعذر الحصول على إشارة GPS';
    }
    return 'حدث خطأ: ${error.toString()}';
  }
}
