import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_data.dart';
import '../models/network_data.dart';

/// خدمة تحديد الموقع عبر عنوان IP
/// مستقلة تماماً عن GPS و Fused Location Provider
class IpLocationService {
  /// الحصول على الموقع عبر عنوان IP (ip-api.com - مجاني بدون مفتاح)
  Future<IpLocationData> getIpLocation() async {
    try {
      // المصدر الأساسي: ip-api.com (مجاني، 45 طلب/دقيقة، بدون مفتاح)
      final response = await http.get(
        Uri.parse(
          'http://ip-api.com/json/?fields=status,message,country,regionName,city,lat,lon,isp,org,query,proxy,hosting',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return IpLocationData(
            latitude: (data['lat'] as num?)?.toDouble(),
            longitude: (data['lon'] as num?)?.toDouble(),
            city: data['city'] as String?,
            country: data['country'] as String?,
            regionName: data['regionName'] as String?,
            isp: data['isp'] as String?,
            ipAddress: data['query'] as String?,
            isProxy: data['proxy'] as bool?,
            isHosting: data['hosting'] as bool?,
          );
        }
      }

      // المصدر البديل: ipinfo.io
      return await _fallbackIpInfo();
    } catch (e) {
      // محاولة المصدر البديل
      try {
        return await _fallbackIpInfo();
      } catch (_) {
        return IpLocationData(
          error: 'تعذر تحديد الموقع عبر IP: $e',
        );
      }
    }
  }

  /// المصدر البديل: ipinfo.io
  Future<IpLocationData> _fallbackIpInfo() async {
    try {
      final response = await http.get(
        Uri.parse('https://ipinfo.io/json'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // ipinfo.io يرجع الإحداثيات كـ "loc": "24.4539,39.6142"
        double? lat;
        double? lon;
        final loc = data['loc'] as String?;
        if (loc != null && loc.contains(',')) {
          final parts = loc.split(',');
          lat = double.tryParse(parts[0]);
          lon = double.tryParse(parts[1]);
        }

        return IpLocationData(
          latitude: lat,
          longitude: lon,
          city: data['city'] as String?,
          country: data['country'] as String?,
          regionName: data['region'] as String?,
          isp: data['org'] as String?,
          ipAddress: data['ip'] as String?,
        );
      }

      return IpLocationData(error: 'فشل الاتصال بخدمة IP البديلة');
    } catch (e) {
      return IpLocationData(error: 'تعذر الاتصال بخدمة IP: $e');
    }
  }

  /// تحويل بيانات IP إلى LocationData
  LocationData ipDataToLocationData(IpLocationData ipData) {
    if (ipData.hasLocation) {
      return LocationData(
        latitude: ipData.latitude,
        longitude: ipData.longitude,
        source: LocationSource.ip,
        timestamp: DateTime.now(),
        address: _formatIpAddress(ipData),
      );
    }
    return LocationData(
      source: LocationSource.ip,
      error: ipData.error ?? 'لا تتوفر بيانات موقع IP',
    );
  }

  String _formatIpAddress(IpLocationData data) {
    List<String> parts = [];
    if (data.city != null) parts.add(data.city!);
    if (data.regionName != null) parts.add(data.regionName!);
    if (data.country != null) parts.add(data.country!);
    return parts.join('، ');
  }
}
