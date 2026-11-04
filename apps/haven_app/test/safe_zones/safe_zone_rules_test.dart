import 'package:flutter_test/flutter_test.dart';
import 'package:haven_app/features/safe_zones/data/safe_zone_rules.dart';

void main() {
  group('SafeZoneRules.name', () {
    test('accepts a name inside the bounds', () {
      expect(SafeZoneRules.name('School'), isNull);
      expect(SafeZoneRules.name('a' * SafeZoneRules.nameMax), isNull);
    });

    test('refuses an empty or whitespace-only name', () {
      expect(SafeZoneRules.name(''), isNotNull);
      expect(SafeZoneRules.name('   '), isNotNull);
    });

    test('refuses a name longer than the column holds', () {
      expect(
        SafeZoneRules.name('a' * (SafeZoneRules.nameMax + 1)),
        contains('${SafeZoneRules.nameMax} characters'),
      );
    });
  });

  group('SafeZoneRules.radius', () {
    test('accepts the smallest and the largest circle the schema allows', () {
      expect(
        SafeZoneRules.radius('${SafeZoneRules.radiusMin.toInt()}'),
        isNull,
      );
      expect(
        SafeZoneRules.radius('${SafeZoneRules.radiusMax.toInt()}'),
        isNull,
      );
    });

    test('refuses below the floor, where GPS error would flicker the zone', () {
      expect(SafeZoneRules.radius('49'), isNotNull);
      expect(SafeZoneRules.radius('0'), isNotNull);
    });

    test('refuses above the ceiling and refuses text that is not a number', () {
      expect(SafeZoneRules.radius('5001'), isNotNull);
      expect(SafeZoneRules.radius('a hundred'), isNotNull);
      expect(SafeZoneRules.radius(''), isNotNull);
    });
  });

  group('SafeZoneRules lat and lng', () {
    test('bind to the hemisphere limits', () {
      expect(SafeZoneRules.lat('90'), isNull);
      expect(SafeZoneRules.lat('-90'), isNull);
      expect(SafeZoneRules.lat('90.1'), isNotNull);
      expect(SafeZoneRules.lng('180'), isNull);
      expect(SafeZoneRules.lng('-180'), isNull);
      expect(SafeZoneRules.lng('181'), isNotNull);
    });

    test(
      'say which field is wrong, so the message lands under the right box',
      () {
        expect(SafeZoneRules.lat('91'), contains('latitude'));
        expect(SafeZoneRules.lng('181'), contains('longitude'));
      },
    );

    test('refuse a value that is not a number at all', () {
      expect(SafeZoneRules.lat('north'), isNotNull);
    });
  });

  group('SafeZoneRules.all', () {
    test('answers every column the editor holds', () {
      final Map<String, String?> errors = SafeZoneRules.all(
        name: 'School',
        lat: '37.7749',
        lng: '-122.4194',
        radiusM: '150',
      );

      expect(errors.keys, ['name', 'lat', 'lng', 'radius_m']);
      expect(SafeZoneRules.isClean(errors), isTrue);
    });

    test('reports each broken column and not the others', () {
      final Map<String, String?> errors = SafeZoneRules.all(
        name: '',
        lat: '37.7749',
        lng: 'nope',
        radiusM: '10',
      );

      expect(errors['name'], isNotNull);
      expect(errors['lat'], isNull);
      expect(errors['lng'], isNotNull);
      expect(errors['radius_m'], isNotNull);
      expect(SafeZoneRules.isClean(errors), isFalse);
    });
  });

  group('SafeZoneRules.point and metres', () {
    test('parse the pair only when both are numbers', () {
      expect(SafeZoneRules.point(' 37.7749 ', '-122.4194'), (
        37.7749,
        -122.4194,
      ));
      expect(SafeZoneRules.point('37.7749', 'x'), isNull);
      expect(SafeZoneRules.metres('150'), 150);
      expect(SafeZoneRules.metres(''), isNull);
    });
  });
}
