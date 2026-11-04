import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/safe_zones/data/zones_models.dart';
import 'package:haven_app/features/safe_zones/data/zones_repository.dart';
import 'package:haven_core/haven_core.dart';

import 'fakes.dart';

void main() {
  group('ZoneDraft', () {
    test('a draft seeded from a row is valid as it stands', () {
      final ZoneDraft copy = ZoneDraft.of(zone('z1'));

      expect(copy.isValid, isTrue);
      expect(copy.errors.values, everyElement(isNull));
    });

    test(
      'toRow carries exactly the five columns the grant lets this app write',
      () {
        final Map<String, Object?>? row = draft(
          name: ' Home ',
          radiusM: '220',
        ).toRow();

        expect(row?.keys, ['name', 'lat', 'lng', 'radius_m', 'active']);
        expect(row?['name'], 'Home');
        expect(row?['radius_m'], 220.0);
      },
    );

    test('toRow refuses a position that will not parse', () {
      expect(draft(lat: '').toRow(), isNull);
      expect(draft(lng: 'west').toRow(), isNull);
      expect(draft(radiusM: 'wide').toRow(), isNull);
    });

    test('an out-of-bounds value is refused before it is sent', () {
      expect(draft(lat: '91').isValid, isFalse);
      expect(draft(lng: '-181').isValid, isFalse);
      expect(draft(radiusM: '49').isValid, isFalse);
      expect(draft(name: '').isValid, isFalse);
    });

    test('copyWith changes one field and keeps the rest', () {
      final ZoneDraft paused = draft().copyWith(active: false);

      expect(paused.active, isFalse);
      expect(paused.name, 'School');
      expect(paused.lat, '37.7749');
    });
  });

  group('ZoneBoard', () {
    test(
      'says how many places are named, in the plural only when there are two',
      () {
        expect(
          board(zones: [zone('z1')]).counted,
          '1 place named for this family.',
        );
        expect(
          board(zones: [zone('z1'), zone('z2')]).counted,
          '2 places named for this family.',
        );
      },
    );

    test('counts active places separately from places named', () {
      final ZoneBoard mixed = board(
        zones: [zone('z1'), zone('z2', active: false)],
      );

      expect(mixed.zones, hasLength(2));
      expect(mixed.activeCount, 1);
      expect(mixed.hasZones, isTrue);
    });

    test('carries both refusals, so no widget has to invent the words', () {
      final ZoneBoard read = board();

      expect(read.createGap, isA<BlockedFailure>());
      expect(read.presenceGap, isA<BlockedFailure>());
      expect(
        read.createGap.detail,
        contains(HavenSafeZonesRepository.createMissing),
      );
      expect(read.presenceGap.detail, contains('safe_zone_states'));
    });
  });
}
