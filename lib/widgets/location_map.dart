import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// خريطة تفاعلية تعرض موقعاً واحداً بعلامة (marker)
class LocationMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String title;
  final Color markerColor;

  const LocationMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.markerColor = const Color(0xFF0D9488),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final point = LatLng(latitude, longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.map_rounded, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.location_spoof_detector',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.location_on_rounded,
                        color: markerColor,
                        size: 48,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
