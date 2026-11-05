import 'package:flutter/material.dart';
import '../../../../app/theme/haven_spacing.dart';

/// Interactive visual preview of a safe-zone boundary circle with tap-to-pin.
class ZoneBoundaryPreviewCanvas extends StatelessWidget {
  const ZoneBoundaryPreviewCanvas({
    required this.radiusM,
    required this.onCoordinateSelected,
    this.lat,
    this.lng,
    super.key,
  });

  final double radiusM;
  final double? lat;
  final double? lng;
  final void Function(double lat, double lng) onCoordinateSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTapUp: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final local = details.localPosition;
                final center = Offset(box.size.width / 2, box.size.height / 2);
                final dx = local.dx - center.dx;
                final dy = local.dy - center.dy;
                // Offset by approx 0.0001 deg per 10 pixels
                final curLat = lat ?? 37.7749;
                final curLng = lng ?? -122.4194;
                final newLat = curLat - (dy * 0.00002);
                final newLng = curLng + (dx * 0.00002);
                onCoordinateSelected(newLat, newLng);
              },
              child: CustomPaint(
                painter: _BoundaryPainter(
                  radiusM: radiusM,
                  colorScheme: colorScheme,
                ),
              ),
            ),
          ),
          Positioned(
            top: HavenSpacing.xs,
            left: HavenSpacing.xs,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                lat != null && lng != null
                    ? 'Center: ${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}'
                    : 'Tap canvas to set pin',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            bottom: HavenSpacing.xs,
            left: HavenSpacing.xs,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Boundary: ${radiusM >= 1000 ? '${(radiusM / 1000).toStringAsFixed(1)} km' : '${radiusM.round()} m'}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoundaryPainter extends CustomPainter {
  _BoundaryPainter({required this.radiusM, required this.colorScheme});

  final double radiusM;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Subtle coordinate grid
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Concentric guide rings
    final guidePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 30, guidePaint);
    canvas.drawCircle(center, 60, guidePaint);

    // Radius circle (scaled to fit nicely in 100 height)
    final clampedRadius = (radiusM / 5000.0 * 30.0 + 15.0).clamp(15.0, 42.0);
    final fillPaint = Paint()
      ..color = Colors.teal.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, clampedRadius, fillPaint);
    canvas.drawCircle(center, clampedRadius, strokePaint);

    // Center pin
    final pinPaint = Paint()..color = Colors.red.shade700..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, pinPaint);
  }

  @override
  bool shouldRepaint(covariant _BoundaryPainter oldDelegate) =>
      oldDelegate.radiusM != radiusM;
}
