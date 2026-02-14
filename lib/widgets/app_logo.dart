import 'package:flutter/material.dart';

/// شعار التطبيق: دبوس موقع + علامة تحقق
class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: size * 0.92,
            color: c,
          ),
          Positioned(
            right: -size * 0.08,
            bottom: -size * 0.05,
            child: Container(
              padding: EdgeInsets.all(size * 0.12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_rounded,
                size: size * 0.38,
                color: Colors.green.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
