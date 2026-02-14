import 'package:flutter/material.dart';
import '../models/spoof_result.dart';
import '../models/location_data.dart';

class SpoofResultCard extends StatelessWidget {
  final SpoofDetectionResult result;

  const SpoofResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMainResult(context),
        const SizedBox(height: 20),
        _buildIndicatorsCard(context),
        const SizedBox(height: 20),
        _buildComparisonCard(context),
      ],
    );
  }

  Widget _buildMainResult(BuildContext context) {
    final theme = Theme.of(context);
    Color bgColor;
    Color textColor;
    IconData icon;
    String title;

    switch (result.confidence) {
      case SpoofConfidence.definitelySpoofed:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        icon = Icons.warning_rounded;
        title = 'تم اكتشاف تزوير الموقع!';
        break;
      case SpoofConfidence.likelySpoofed:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        icon = Icons.warning_amber_rounded;
        title = 'يُرَجح أن الموقع مُزيف';
        break;
      case SpoofConfidence.possiblySpoofed:
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        icon = Icons.help_outline_rounded;
        title = 'احتمال التزوير موجود';
        break;
      case SpoofConfidence.probablyReal:
        bgColor = Colors.lightGreen.shade50;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle_outline_rounded;
        title = 'الموقع يبدو حقيقياً';
        break;
      case SpoofConfidence.definitelyReal:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        icon = Icons.verified_rounded;
        title = 'الموقع مؤكد حقيقي';
        break;
      default:
        bgColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurface;
        icon = Icons.help_rounded;
        title = 'غير محدد';
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: textColor.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: textColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildConfidenceBar(context),
          const SizedBox(height: 10),
          Text(
            'مستوى الشك: ${result.confidencePercentage.toStringAsFixed(0)}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (result.confidence == SpoofConfidence.probablyReal ||
              result.confidence == SpoofConfidence.definitelyReal) ...[
            const SizedBox(height: 10),
            Text(
              'التزوير عبر تطبيقات روت قد لا يُكتشف.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LinearProgressIndicator(
        value: result.confidencePercentage / 100,
        minHeight: 14,
        backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        valueColor: AlwaysStoppedAnimation<Color>(_getConfidenceColor()),
      ),
    );
  }

  Color _getConfidenceColor() {
    if (result.confidencePercentage >= 75) return Colors.red.shade600;
    if (result.confidencePercentage >= 50) return Colors.orange.shade600;
    if (result.confidencePercentage >= 25) return Colors.amber.shade600;
    return Colors.green.shade600;
  }

  Widget _buildIndicatorsCard(BuildContext context) {
    if (result.indicators.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.checklist_rounded, color: Colors.indigo.shade600, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'المؤشرات المكتشفة',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...result.indicators.map((i) => _buildIndicatorTile(context, i)),
        ],
      ),
    );
  }

  Widget _buildIndicatorTile(BuildContext context, SpoofIndicator indicator) {
    final theme = Theme.of(context);
    Color color;
    IconData icon;

    switch (indicator.severity) {
      case IndicatorSeverity.critical:
        color = Colors.red.shade600;
        icon = Icons.error_rounded;
        break;
      case IndicatorSeverity.warning:
        color = Colors.orange.shade600;
        icon = Icons.warning_amber_rounded;
        break;
      case IndicatorSeverity.info:
        color = Colors.blue.shade600;
        icon = Icons.info_outline_rounded;
        break;
      case IndicatorSeverity.safe:
        color = Colors.green.shade600;
        icon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indicator.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  indicator.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              indicator.source,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const purple = Color(0xFF8B5CF6);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.compare_arrows_rounded, color: purple, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'مقارنة مصادر الموقع',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSourceRow(context, 'GPS', Icons.satellite_alt_rounded, const Color(0xFF0EA5E9), result.gpsLocation),
          _buildSourceRow(context, 'WiFi', Icons.wifi_rounded, const Color(0xFF10B981), result.wifiLocation),
          _buildSourceRow(context, 'الخلوي', Icons.cell_tower_rounded, const Color(0xFFF59E0B), result.cellularLocation),
          _buildSourceRow(context, 'IP', Icons.language_rounded, const Color(0xFF8B5CF6), result.ipLocation),
          if (_canCalculateDistance()) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: colorScheme.outline.withOpacity(0.4)),
            const SizedBox(height: 16),
            _buildDistanceInfo(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceRow(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
    LocationData? location,
  ) {
    final theme = Theme.of(context);

    String status;
    Color statusColor;

    if (location == null) {
      status = 'غير متاح';
      statusColor = theme.colorScheme.onSurface.withOpacity(0.5);
    } else if (location.hasError) {
      status = 'خطأ';
      statusColor = Colors.red.shade600;
    } else if (!location.hasLocation) {
      status = 'لا يوجد بيانات';
      statusColor = theme.colorScheme.onSurface.withOpacity(0.5);
    } else {
      status = '${location.latitude!.toStringAsFixed(4)}, ${location.longitude!.toStringAsFixed(4)}';
      statusColor = location.isMocked == true ? Colors.red.shade600 : Colors.green.shade600;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            name,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (location?.isMocked == true) ...[
            const SizedBox(width: 6),
            Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 18),
          ],
        ],
      ),
    );
  }

  bool _canCalculateDistance() {
    return (result.gpsLocation?.hasLocation == true &&
            result.wifiLocation?.hasLocation == true) ||
        (result.gpsLocation?.hasLocation == true &&
            result.cellularLocation?.hasLocation == true) ||
        (result.gpsLocation?.hasLocation == true &&
            result.ipLocation?.hasLocation == true);
  }

  Widget _buildDistanceInfo(BuildContext context) {
    final theme = Theme.of(context);

    List<Widget> distances = [];

    if (result.gpsLocation?.hasLocation == true &&
        result.wifiLocation?.hasLocation == true) {
      double dist = _calculateDistance(result.gpsLocation!, result.wifiLocation!);
      distances.add(_buildDistanceRow(context, 'GPS ↔ WiFi', dist));
    }

    if (result.gpsLocation?.hasLocation == true &&
        result.cellularLocation?.hasLocation == true) {
      double dist = _calculateDistance(result.gpsLocation!, result.cellularLocation!);
      distances.add(_buildDistanceRow(context, 'GPS ↔ الخلوي', dist));
    }

    if (result.wifiLocation?.hasLocation == true &&
        result.cellularLocation?.hasLocation == true) {
      double dist = _calculateDistance(result.wifiLocation!, result.cellularLocation!);
      distances.add(_buildDistanceRow(context, 'WiFi ↔ الخلوي', dist));
    }

    if (result.gpsLocation?.hasLocation == true &&
        result.ipLocation?.hasLocation == true) {
      double dist = _calculateDistance(result.gpsLocation!, result.ipLocation!);
      distances.add(_buildDistanceRow(context, 'GPS ↔ IP', dist));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المسافة بين المصادر:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        ...distances,
      ],
    );
  }

  Widget _buildDistanceRow(BuildContext context, String label, double distance) {
    final theme = Theme.of(context);
    Color color;
    String status;
    String distanceText;

    if (distance > 50000) {
      color = Colors.red.shade600;
      status = 'فرق كبير!';
    } else if (distance > 1000) {
      color = Colors.orange.shade600;
      status = 'ملحوظ';
    } else {
      color = Colors.green.shade600;
      status = 'طبيعي';
    }

    // عرض بالكيلومتر إذا كانت المسافة كبيرة
    if (distance >= 1000) {
      distanceText = '${(distance / 1000).toStringAsFixed(1)} كم';
    } else {
      distanceText = '${distance.toStringAsFixed(0)} متر';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
          const Spacer(),
          Text(
            distanceText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateDistance(LocationData loc1, LocationData loc2) {
    const double earthRadius = 6371000;
    double lat1 = loc1.latitude! * 3.14159265359 / 180;
    double lat2 = loc2.latitude! * 3.14159265359 / 180;
    double dLat = lat2 - lat1;
    double dLon = (loc2.longitude! - loc1.longitude!) * 3.14159265359 / 180;

    double a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(lat1) * _cos(lat2) * _sin(dLon / 2) * _sin(dLon / 2);
    double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadius * c;
  }

  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorSin(x + 1.5707963267949);
  double _sqrt(double x) => _newtonSqrt(x);
  double _atan2(double y, double x) => _approximateAtan2(y, x);

  double _taylorSin(double x) {
    x = x % 6.28318530718;
    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _newtonSqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _approximateAtan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (y > 0) return 1.5707963267949;
    if (y < 0) return -1.5707963267949;
    return 0;
  }

  double _atan(double x) {
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 1.5707963267949 - _atan(1 / x);
    }
    double result = x;
    double term = x;
    for (int i = 1; i < 20; i++) {
      term *= -x * x;
      result += term / (2 * i + 1);
    }
    return result;
  }
}
