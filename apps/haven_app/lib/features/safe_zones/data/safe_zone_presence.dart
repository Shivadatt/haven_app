import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart' show SafeZone;

/// Status and distance result for a single safe zone evaluation.
final class SafeZonePresenceResult {
  const SafeZonePresenceResult({
    required this.zone,
    required this.distanceMeters,
    required this.isInside,
  });

  final SafeZone zone;
  final double distanceMeters;
  final bool isInside;

  String get summary => isInside
      ? 'Inside ${zone.name} (${distanceMeters.toStringAsFixed(0)} m from center)'
      : 'Outside ${zone.name} (${distanceMeters.toStringAsFixed(0)} m away)';
}

/// Evaluates coordinates against safe zones using Haversine distance.
///
/// Converts refusal #11 by calculating presence locally on the device.
abstract final class SafeZonePresenceCalculator {
  /// Evaluates whether a coordinate is inside a specific safe zone.
  static SafeZonePresenceResult evaluate({
    required SafeZone zone,
    required double lat,
    required double lng,
  }) {
    final double dist = haversineMeters(
      lat1: zone.lat,
      lon1: zone.lng,
      lat2: lat,
      lon2: lng,
    );
    final bool inside = dist <= zone.radiusM;
    return SafeZonePresenceResult(
      zone: zone,
      distanceMeters: dist,
      isInside: inside,
    );
  }

  /// Evaluates coordinates against all provided zones, active zones first.
  static List<SafeZonePresenceResult> evaluateAll({
    required List<SafeZone> zones,
    required double lat,
    required double lng,
  }) {
    final List<SafeZonePresenceResult> results = [];
    for (final SafeZone zone in zones) {
      if (!zone.active) continue;
      results.add(evaluate(zone: zone, lat: lat, lng: lng));
    }
    return results;
  }

  /// Produces a human-readable summary of presence across all safe zones.
  static String summarizePresence({
    required List<SafeZone> zones,
    required double lat,
    required double lng,
  }) {
    final List<SafeZonePresenceResult> activeResults = evaluateAll(
      zones: zones,
      lat: lat,
      lng: lng,
    );
    if (activeResults.isEmpty) {
      return 'No active safe zones to evaluate.';
    }

    final List<SafeZonePresenceResult> insideList =
        activeResults.where((r) => r.isInside).toList();

    if (insideList.isNotEmpty) {
      final names = insideList.map((r) => r.zone.name).join(', ');
      return 'Inside: $names';
    }

    // Outside all: find closest
    activeResults.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    final SafeZonePresenceResult closest = activeResults.first;
    return 'Outside (nearest: ${closest.zone.name}, ${closest.distanceMeters.toStringAsFixed(0)} m away)';
  }
}
