import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/safe_zones/data/safe_zone_presence.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

void main() {
  group('Haversine distance calculation via haven_core', () {
    test('calculates accurate distance between known coordinates', () {
      // Coordinates: Golden Gate Bridge to Alcatraz Island (~4.8 km)
      final d = haversineMeters(
        lat1: 37.8199,
        lon1: -122.4783,
        lat2: 37.8267,
        lon2: -122.4230,
      );
      // Distance is ~4.89 km
      expect(d, inInclusiveRange(4800.0, 5000.0));
    });

    test('same coordinate yields 0 meters', () {
      final d = haversineMeters(
        lat1: 37.7749,
        lon1: -122.4194,
        lat2: 37.7749,
        lon2: -122.4194,
      );
      expect(d, closeTo(0.0, 0.001));
    });
  });

  group('SafeZonePresenceCalculator - Local Inside/Outside (Converts Refusal #11)', () {
    final school = SafeZone(
      id: 'z_school',
      familyId: 'f1',
      name: 'School',
      lat: 37.7749,
      lng: -122.4194,
      radiusM: 200.0,
      active: true,
      createdAt: DateTime.now(),
    );

    final home = SafeZone(
      id: 'z_home',
      familyId: 'f1',
      name: 'Home',
      lat: 37.7800,
      lng: -122.4100,
      radiusM: 100.0,
      active: true,
      createdAt: DateTime.now(),
    );

    final pausedPark = SafeZone(
      id: 'z_park',
      familyId: 'f1',
      name: 'Park',
      lat: 37.7750,
      lng: -122.4195,
      radiusM: 500.0,
      active: false, // Paused
      createdAt: DateTime.now(),
    );

    test('detects inside when distance is within radius', () {
      // 50 meters away from center of School
      final res = SafeZonePresenceCalculator.evaluate(
        zone: school,
        lat: 37.7752,
        lng: -122.4194,
      );
      expect(res.isInside, isTrue);
      expect(res.distanceMeters, lessThan(school.radiusM));
      expect(res.summary, contains('Inside School'));
    });

    test('detects outside when distance exceeds radius', () {
      // ~800 meters away from School
      final res = SafeZonePresenceCalculator.evaluate(
        zone: school,
        lat: 37.7820,
        lng: -122.4194,
      );
      expect(res.isInside, isFalse);
      expect(res.distanceMeters, greaterThan(school.radiusM));
      expect(res.summary, contains('Outside School'));
    });

    test('evaluateAll skips paused zones', () {
      final results = SafeZonePresenceCalculator.evaluateAll(
        zones: [school, home, pausedPark],
        lat: 37.7750,
        lng: -122.4195,
      );
      expect(results.length, 2);
      expect(results.any((r) => r.zone.id == 'z_park'), isFalse);
    });

    test('summarizePresence returns inside status when inside active zone', () {
      final summary = SafeZonePresenceCalculator.summarizePresence(
        zones: [school, home],
        lat: 37.7749,
        lng: -122.4194,
      );
      expect(summary, 'Inside: School');
    });

    test('summarizePresence returns nearest zone when outside all zones', () {
      final summary = SafeZonePresenceCalculator.summarizePresence(
        zones: [school, home],
        lat: 37.7900,
        lng: -122.4300,
      );
      expect(summary, startsWith('Outside (nearest:'));
    });

    test('summarizePresence handles empty or inactive zones list', () {
      final summary = SafeZonePresenceCalculator.summarizePresence(
        zones: [pausedPark],
        lat: 37.7749,
        lng: -122.4194,
      );
      expect(summary, 'No active safe zones to evaluate.');
    });
  });
}
