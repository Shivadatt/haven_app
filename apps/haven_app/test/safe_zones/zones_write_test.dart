import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import '../support/data_fakes.dart';
import 'fakes.dart';
import 'harness.dart';

/// The write half of this lane, which is the only place in the app where a
/// parent's keystroke reaches the database: five columns, an id and a family
/// filter, and two refusals that never turn into a silent success.
void main() {
  group('SafeZonesRepository.save', () {
    test('writes only the five columns the captured grant names', () async {
      final Harness harness = Harness(tables: zonesTables());

      final Result<void> written = await harness.subject.save(
        zoneId: 'z1',
        draft: draft(name: '  School  ', radiusM: '200'),
      );

      expect(written.isOk, isTrue);
      expect(harness.writer.writtenTables.single, TableName.safeZones);
      expect(harness.writer.lastPayload, {
        'name': 'School',
        'lat': 37.7749,
        'lng': -122.4194,
        'radius_m': 200.0,
        'active': true,
      });
      expect(harness.writer.matchers.single, {'id': 'z1', 'family_id': 'f1'});
    });

    test('a draft that will not parse is never sent', () async {
      final Harness harness = Harness(tables: zonesTables());

      final Result<void> written = await harness.subject.save(
        zoneId: 'z1',
        draft: draft(lat: 'north-ish'),
      );

      expect(written.failureOrNull, isA<ValidationFailure>());
      expect(harness.writer.writtenTables, isEmpty);
    });

    test('a write refused by the backend is reported, not swallowed', () async {
      final Harness harness = Harness(
        tables: zonesTables(),
        withWriter: FakeRowWriter(
          failWith: const PermissionFailure('fake: rls denied'),
        ),
      );

      final Result<void> written = await harness.subject.save(
        zoneId: 'z1',
        draft: draft(),
      );

      expect(written.failureOrNull, isA<PermissionFailure>());
    });

    test('an account with no family writes nothing', () async {
      final Harness harness = Harness.withoutFamily();

      final Result<void> written = await harness.subject.save(
        zoneId: 'z1',
        draft: draft(),
      );

      expect(written.isOk, isFalse);
      expect(harness.writer.writtenTables, isEmpty);
    });
  });

  group('SafeZonesRepository.remove', () {
    test('deletes with the family filter attached', () async {
      final Harness harness = Harness(tables: zonesTables());

      final Result<void> removed = await harness.subject.remove(zoneId: 'z1');

      expect(removed.isOk, isTrue);
      expect(harness.writer.matchers.single, {'id': 'z1', 'family_id': 'f1'});
    });

    test('an account with no family deletes nothing', () async {
      final Harness harness = Harness.withoutFamily();

      final Result<void> removed = await harness.subject.remove(zoneId: 'z1');

      expect(removed.isOk, isFalse);
      expect(harness.writer.writtenTables, isEmpty);
    });
  });

  group('SafeZonesRepository.create', () {
    test('is refused with the captured evidence, and writes nothing', () async {
      final Harness harness = Harness(tables: zonesTables());

      final Result<void> created = await harness.subject.create(draft: draft());

      expect(created.isOk, isFalse);
      final BlockedFailure gap = created.failureOrNull! as BlockedFailure;
      expect(gap.message, 'Haven cannot name a new place in this build yet.');
      expect(gap.missing, contains('04-rls-matrix.md:33, :147'));
      expect(gap.detail, startsWith('BLOCKED — SPECIFICATION REQUIRED:'));
      expect(harness.writer.writtenTables, isEmpty);
    });
  });
}
