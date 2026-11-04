import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/core/errors/captured_gaps.dart';
import 'package:haven_app/features/safe_zones/data/zones_models.dart';
import 'package:haven_app/features/safe_zones/data/zones_repository.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import '../support/data_fakes.dart';
import 'fakes.dart';
import 'harness.dart';

void main() {
  group('SafeZonesRepository.load', () {
    test('reads this family\'s places and carries both refusals', () async {
      final Harness harness = Harness(
        tables: zonesTables(zones: [zoneRow('z1'), zoneRow('z2')]),
      );

      final ZoneBoard board = await harness.okBoard();

      expect(board.familyId, 'f1');
      expect(board.zones, hasLength(2));
      expect(harness.rows.lastTable, TableName.safeZones);
      // The family id comes from the caller's own membership row, never from a
      // value the screen could have been handed — so the read filter carries it.
      expect(harness.rows.filters.first, {'user_id': 'u1'});
      expect(harness.rows.filters.last, {'family_id': 'f1'});
      expect(
        board.createGap.missing,
        contains(HavenSafeZonesRepository.createMissing),
      );
      expect(
        board.presenceGap.missing,
        contains(CapturedGaps.presenceLaneMissing),
      );
    });

    test('orders newest first inside a bounded window', () async {
      final Harness harness = Harness(
        tables: zonesTables(
          zones: [
            zoneRow('old', createdAt: '2026-01-01T00:00:00.000Z'),
            zoneRow('new', createdAt: '2026-06-01T00:00:00.000Z'),
          ],
        ),
      );

      final ZoneBoard board = await harness.okBoard();

      expect(harness.rows.orderings.last, 'created_at');
      expect(harness.rows.limits.last, 50);
      expect(board.zones.first.id, 'new');
    });

    test(
      'an account with no family is a first-run answer, not a failure',
      () async {
        final Result<ZoneBoard?> read = await Harness.withoutFamily().subject
            .load();

        expect(read.valueOrNull, isNull);
        expect(read.failureOrNull, isNull);
      },
    );

    test(
      'a refused read stays a refusal instead of becoming an empty list',
      () async {
        final Harness harness = Harness(
          withRows: FakeRowReader(zonesTables(), {
            TableName.safeZones: const BackendFailure('fake: rows unreadable'),
          }),
        );

        final Result<ZoneBoard?> read = await harness.subject.load();

        expect(read.valueOrNull, isNull);
        expect(read.failureOrNull, isA<BackendFailure>());
      },
    );

    test(
      'the count says places named, and is honest about one place',
      () async {
        final ZoneBoard one = await Harness(
          tables: zonesTables(zones: [zoneRow('z1')]),
        ).okBoard();
        final ZoneBoard none = await Harness(tables: zonesTables()).okBoard();

        expect(one.counted, '1 place named for this family.');
        expect(none.counted, '0 places named for this family.');
        expect(none.hasZones, isFalse);
        expect(one.activeCount, 1);
      },
    );
  });

  group('SafeZonesRepository.zone', () {
    test('reads one place by id, filtered to this family', () async {
      final Harness harness = Harness(
        tables: zonesTables(zones: [zoneRow('z1')]),
      );

      final SafeZone found = await harness.okZone('z1');

      expect(found.id, 'z1');
      expect(harness.rows.filters.last, {'id': 'z1', 'family_id': 'f1'});
    });

    test('a place outside this family answers "not in your family"', () async {
      final Harness harness = Harness(
        tables: zonesTables(zones: [zoneRow('z2', familyId: 'other')]),
      );

      final Result<SafeZone> read = await harness.subject.zone('z2');

      expect(read.valueOrNull, isNull);
      final HavenFailure? failure = read.failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, contains('not in your family'));
    });

    test('an empty id is refused without reading the zone table', () async {
      final Harness harness = Harness(tables: zonesTables());

      final Result<SafeZone> read = await harness.subject.zone('');

      expect(read.failureOrNull, isA<ValidationFailure>());
      expect(harness.rows.readTables, hasLength(1));
      expect(harness.rows.readTables.single, TableName.familyMembers);
    });
  });
}
