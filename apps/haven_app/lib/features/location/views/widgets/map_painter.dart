import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:haven_models/haven_models.dart' show SafeZone;
import '../../data/location_models.dart';

/// Custom painter for rendering the offline interactive coordinate canvas.
class MapPainter extends CustomPainter {
  MapPainter({
    required this.fix,
    required this.zones,
    required this.selectedZone,
    required this.zoom,
    required this.panOffset,
    required this.colorScheme,
  });

  final FixLine? fix;
  final List<SafeZone> zones;
  final SafeZone? selectedZone;
  final double zoom;
  final Offset panOffset;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + panOffset;
    _drawGrid(canvas, size, center);
    _drawConcentricRings(canvas, center);

    // Reference lat/lng is the fix's point or first zone
    final double refLat = fix?.fix.lat ?? (zones.isNotEmpty ? zones.first.lat : 0.0);
    final double refLng = fix?.fix.lng ?? (zones.isNotEmpty ? zones.first.lng : 0.0);
    const double metersPerPixelAtZoom1 = 5.0;
    final double metersPerPixel = metersPerPixelAtZoom1 / zoom;

    // Draw safe zones
    for (final zone in zones) {
      final offset = _latLngToOffset(zone.lat, zone.lng, refLat, refLng, center, metersPerPixel);
      final radiusPx = zone.radiusM / metersPerPixel;
      final isSel = selectedZone?.id == zone.id;
      _drawZone(canvas, zone, offset, radiusPx, isSel);
    }

    // Draw distance line if selected zone and fix exist
    if (fix != null && selectedZone != null) {
      final childOffset = center;
      final zoneOffset = _latLngToOffset(
        selectedZone!.lat,
        selectedZone!.lng,
        refLat,
        refLng,
        center,
        metersPerPixel,
      );
      _drawDistanceLine(canvas, childOffset, zoneOffset);
    }

    // Draw child marker
    if (fix != null) {
      _drawChildMarker(canvas, center, fix!.whose);
    }

    _drawCompass(canvas, size);
    _drawScaleBar(canvas, size, metersPerPixel);
  }

  void _drawGrid(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    const step = 40.0;
    for (double x = center.dx % step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = center.dy % step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawConcentricRings(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (double r = 60.0 * zoom; r <= 240.0 * zoom; r += 60.0 * zoom) {
      canvas.drawCircle(center, r, paint);
    }
  }

  void _drawZone(Canvas canvas, SafeZone zone, Offset offset, double radiusPx, bool isSelected) {
    final fillPaint = Paint()
      ..color = (isSelected ? Colors.teal : Colors.blue).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = isSelected ? Colors.teal : Colors.blue.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5;

    canvas.drawCircle(offset, radiusPx, fillPaint);
    canvas.drawCircle(offset, radiusPx, strokePaint);

    final textSpan = TextSpan(
      text: zone.name,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.teal.shade900 : Colors.blue.shade900,
        backgroundColor: Colors.white70,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, offset - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  void _drawChildMarker(Canvas canvas, Offset center, String name) {
    final pulsePaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18, pulsePaint);

    final pinPaint = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7, pinPaint);

    final textSpan = TextSpan(
      text: name,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        backgroundColor: Colors.white,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, center + const Offset(10, -6));
  }

  void _drawDistanceLine(Canvas canvas, Offset p1, Offset p2) {
    final linePaint = Paint()
      ..color = Colors.deepOrange.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p1, p2, linePaint);
  }

  void _drawCompass(Canvas canvas, Size size) {
    const pos = Offset(40, 40);
    final paint = Paint()..color = colorScheme.primary..strokeWidth = 2;
    canvas.drawLine(pos, pos + const Offset(0, -16), paint);
    final textSpan = TextSpan(
      text: 'N',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, pos + const Offset(-4, -30));
  }

  void _drawScaleBar(Canvas canvas, Size size, double metersPerPixel) {
    final barWidthPx = 80.0;
    final meters = barWidthPx * metersPerPixel;
    final p1 = Offset(16, size.height - 20);
    final p2 = Offset(16 + barWidthPx, size.height - 20);
    final paint = Paint()..color = Colors.black54..strokeWidth = 2;
    canvas.drawLine(p1, p2, paint);
    canvas.drawLine(p1, p1 + const Offset(0, -5), paint);
    canvas.drawLine(p2, p2 + const Offset(0, -5), paint);

    final text = meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '${meters.round()} m';
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(fontSize: 10, color: Colors.black87)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(20, size.height - 35));
  }

  Offset _latLngToOffset(double lat, double lng, double refLat, double refLng, Offset center, double mPerPx) {
    const double metersPerDegreeLat = 111132.92;
    final double metersPerDegreeLng = 111412.84 * math.cos(refLat * math.pi / 180.0);
    final double dy = -(lat - refLat) * metersPerDegreeLat / mPerPx;
    final double dx = (lng - refLng) * metersPerDegreeLng / mPerPx;
    return center + Offset(dx, dy);
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) => true;
}
