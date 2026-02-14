import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/location_data.dart';

class LocationCard extends StatelessWidget {
  final LocationData location;
  final String title;
  final Color color;

  const LocationCard({
    super.key,
    required this.location,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (location.hasError) {
      return _buildErrorCard(context);
    }

    if (!location.hasLocation) {
      return _buildNoDataCard(context);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getSourceIcon(),
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildMockStatus(context),
                      ],
                    ),
                  ),
                  Material(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _copyCoordinates(context),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.copy_rounded, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: colorScheme.outline.withOpacity(0.5)),
              const SizedBox(height: 16),
              _buildCoordinateRow(
                context,
                'خط العرض',
                location.latitude!.toStringAsFixed(6),
                Icons.north_rounded,
              ),
              _buildCoordinateRow(
                context,
                'خط الطول',
                location.longitude!.toStringAsFixed(6),
                Icons.east_rounded,
              ),
              _buildCoordinateRow(
                context,
                'الدقة',
                _getAccuracyText(),
                Icons.adjust_rounded,
              ),
              if (location.altitude != null && location.altitude != 0)
                _buildCoordinateRow(
                  context,
                  'الارتفاع',
                  '${location.altitude!.toStringAsFixed(1)} متر',
                  Icons.height_rounded,
                ),
              if (location.speed != null && location.speed! > 0)
                _buildCoordinateRow(
                  context,
                  'السرعة',
                  '${(location.speed! * 3.6).toStringAsFixed(1)} كم/س',
                  Icons.speed_rounded,
                ),
              if (location.timestamp != null)
                _buildCoordinateRow(
                  context,
                  'التوقيت',
                  _formatTime(location.timestamp!),
                  Icons.access_time_rounded,
                ),
              if (location.address != null && location.address!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: colorScheme.outline.withOpacity(0.5)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          location.address!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockStatus(BuildContext context) {
    final theme = Theme.of(context);

    if (location.isMocked == null) {
      return Text(
        'حالة التزوير: غير محدد',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          fontSize: 12,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: location.isMocked!
            ? Colors.red.shade50
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: location.isMocked!
              ? Colors.red.shade200
              : Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Text(
        location.isMocked! ? 'موقع مُزيف' : 'موقع حقيقي',
        style: theme.textTheme.labelSmall?.copyWith(
          color: location.isMocked! ? Colors.red.shade700 : Colors.green.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCoordinateRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              location.error!,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 24),
          const SizedBox(width: 14),
          Text(
            'لا توجد بيانات',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _getAccuracyText() {
    if (location.accuracy != null && location.accuracy! > 0) {
      return '${location.accuracy!.toStringAsFixed(1)} متر';
    }
    switch (location.source) {
      case LocationSource.wifi:
        return 'تقريبية (شبكة)';
      case LocationSource.cellular:
        return 'تقريبية (شبكة)';
      default:
        return 'غير متوفرة';
    }
  }

  IconData _getSourceIcon() {
    switch (location.source) {
      case LocationSource.gps:
        return Icons.satellite_alt_rounded;
      case LocationSource.wifi:
        return Icons.wifi_rounded;
      case LocationSource.cellular:
        return Icons.cell_tower_rounded;
      case LocationSource.network:
        return Icons.language_rounded;
      case LocationSource.fused:
        return Icons.gps_fixed_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  void _copyCoordinates(BuildContext context) {
    final coords = '${location.latitude}, ${location.longitude}';
    Clipboard.setData(ClipboardData(text: coords));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ الإحداثيات'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
