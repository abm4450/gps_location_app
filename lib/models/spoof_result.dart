import 'package:flutter/material.dart';
import 'location_data.dart';
import 'network_data.dart';

/// نتيجة فحص التزوير
class SpoofDetectionResult {
  final bool isSpoofed;
  final SpoofConfidence confidence;
  final List<SpoofIndicator> indicators;
  final LocationData? gpsLocation;
  final LocationData? wifiLocation;
  final LocationData? cellularLocation;
  final LocationData? ipLocation;
  final WifiData? wifiData;
  final CellTowerData? cellData;
  final IpLocationData? ipData;
  final DateTime timestamp;
  /// الجهاز مُروت (أندرويد)
  final bool isRooted;
  /// حزم تطبيقات تغيير الموقع المعروفة المثبتة
  final List<String> installedSpoofingApps;

  SpoofDetectionResult({
    required this.isSpoofed,
    required this.confidence,
    required this.indicators,
    this.gpsLocation,
    this.wifiLocation,
    this.cellularLocation,
    this.ipLocation,
    this.wifiData,
    this.cellData,
    this.ipData,
    required this.timestamp,
    this.isRooted = false,
    this.installedSpoofingApps = const [],
  });

  /// حساب نسبة الثقة كرقم
  double get confidencePercentage {
    switch (confidence) {
      case SpoofConfidence.definitelySpoofed:
        return 95;
      case SpoofConfidence.likelySpoofed:
        return 75;
      case SpoofConfidence.possiblySpoofed:
        return 50;
      case SpoofConfidence.probablyReal:
        return 25;
      case SpoofConfidence.definitelyReal:
        return 5;
      case SpoofConfidence.unknown:
        return 50;
    }
  }
}

/// مستوى الثقة في التزوير
enum SpoofConfidence {
  definitelySpoofed,
  likelySpoofed,
  possiblySpoofed,
  probablyReal,
  definitelyReal,
  unknown,
}

extension SpoofConfidenceExtension on SpoofConfidence {
  String get arabicName {
    switch (this) {
      case SpoofConfidence.definitelySpoofed:
        return '🚨 مؤكد التزوير';
      case SpoofConfidence.likelySpoofed:
        return '⚠️ مرجح التزوير';
      case SpoofConfidence.possiblySpoofed:
        return '🤔 محتمل التزوير';
      case SpoofConfidence.probablyReal:
        return '✅ مرجح حقيقي';
      case SpoofConfidence.definitelyReal:
        return '✅ مؤكد حقيقي';
      case SpoofConfidence.unknown:
        return '❓ غير محدد';
    }
  }

  Color get color {
    switch (this) {
      case SpoofConfidence.definitelySpoofed:
        return const Color(0xFFD32F2F);
      case SpoofConfidence.likelySpoofed:
        return const Color(0xFFFF5722);
      case SpoofConfidence.possiblySpoofed:
        return const Color(0xFFFF9800);
      case SpoofConfidence.probablyReal:
        return const Color(0xFF4CAF50);
      case SpoofConfidence.definitelyReal:
        return const Color(0xFF2E7D32);
      case SpoofConfidence.unknown:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// مؤشر تزوير محدد
class SpoofIndicator {
  final String title;
  final String description;
  final IndicatorSeverity severity;
  final String source;

  SpoofIndicator({
    required this.title,
    required this.description,
    required this.severity,
    required this.source,
  });
}

/// شدة المؤشر
enum IndicatorSeverity {
  critical,
  warning,
  info,
  safe,
}

extension IndicatorSeverityExtension on IndicatorSeverity {
  String get icon {
    switch (this) {
      case IndicatorSeverity.critical:
        return '🚨';
      case IndicatorSeverity.warning:
        return '⚠️';
      case IndicatorSeverity.info:
        return 'ℹ️';
      case IndicatorSeverity.safe:
        return '✅';
    }
  }

  Color get color {
    switch (this) {
      case IndicatorSeverity.critical:
        return const Color(0xFFD32F2F);
      case IndicatorSeverity.warning:
        return const Color(0xFFFF9800);
      case IndicatorSeverity.info:
        return const Color(0xFF2196F3);
      case IndicatorSeverity.safe:
        return const Color(0xFF4CAF50);
    }
  }
}
