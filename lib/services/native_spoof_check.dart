import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// استدعاء الكود الأصلي أندرويد للتحقق من تطبيقات التزوير المعروفة
class NativeSpoofCheck {
  static const MethodChannel _channel = MethodChannel('location_spoof_detector/native');

  /// قائمة حزم تطبيقات تغيير الموقع المعروفة (للعرض فقط)
  static const List<String> knownSpoofingPackageNames = [
    'com.lexa.fakegps',
    'com.dummy.fakegps',
    'com.lerist.fakelocation',
    'com.easy.fakegps',
    'ninja.fakegps',
    'com.fakegps.go',
    // ... الباقي يظهر كـ "تطبيق تغيير موقع"
  ];

  /// التحقق من تثبيت تطبيقات تزوير معروفة (أندرويد فقط)
  static Future<List<String>> checkKnownSpoofingApps() async {
    if (kIsWeb || !Platform.isAndroid) return [];
    try {
      final dynamic raw = await _channel.invokeMethod('checkKnownSpoofingApps');
      if (raw is! List) return [];
      return List<String>.from(raw.map((e) => e.toString()));
    } on PlatformException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }
}
