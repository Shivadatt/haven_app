import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_models/haven_models.dart';

import 'package:haven_child/core/storage/local_child_profile_repository.dart';

import '../../support/storage.dart';

/// Brief §7: "local profile repository CRUD (create-once, update validation,
/// read role guard)" — run against the REAL reused engine (`LocalTables` over
/// `InMemoryLocalStore`), not a fake, so the registry guards and unique rules
/// are part of the proof.
void main() {
  late LocalTables tables;
  late FixedClock clock;
  late LocalChildProfileRepository repo;

  setUp(() {
    tables = StorageTestLane.memoryTables();
    clock = FixedClock(DateTime.utc(2026, 11, 6, 9));
    repo = LocalChildProfileRepository(tables, clock: clock);
  });

  group('read', () {
    test('an untouched device reads as "no profile yet", not an error', () async {
      final result = await repo.read();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('a stored non-child row is refused, honestly and unchanged', () async {
      await tables.insert(TableName.profiles, StorageTestLane.parentRoleRow());
      final result = await repo.read();
      final failure = result.failureOrNull;
      expect(failure, isA<BackendFailure>());
      expect(failure!.detail, 'child_profile_role_mismatch');
      // Nothing was changed: the foreign row is still exactly there.
      expect((await tables.count(TableName.profiles)).valueOrNull, 1);
    });
  });

  group('create', () {
    test('the first profile is written as a child row with clock stamps', () async {
      final created = await repo.create(
        displayName: '  Ada  ',
        ageBracket: '8-11',
        avatar: 'rocket',
      );
      expect(created.isOk, isTrue);
      final profile = created.valueOrNull!;
      expect(profile.displayName, 'Ada'); // trimmed before the write
      expect(profile.ageBracket, '8-11');
      expect(profile.avatar, 'rocket');
      expect(profile.profileRole, ProfileRole.child);
      expect(profile.createdAt, DateTime.utc(2026, 11, 6, 9));
      expect(profile.id, isNotEmpty);
    });

    test('create-once: a second create is refused with the typed detail', () async {
      await repo.create(displayName: 'Ada', ageBracket: '8-11');
      final second = await repo.create(displayName: 'Second', ageBracket: '4-7');
      final failure = second.failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect(failure!.detail, 'child_profile_create_once');
      // The refusal did not touch the first row.
      final reread = await repo.read();
      expect(reread.valueOrNull!.displayName, 'Ada');
    });

    test('an invalid name never reaches the table', () async {
      final failure = (await repo.create(displayName: 'A')).failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure).field, 'display_name');
      expect((await tables.count(TableName.profiles)).valueOrNull, 0);
    });

    test('blank ageBracket/avatar are stored as absent, not empty strings', () async {
      await repo.create(displayName: 'Ada', ageBracket: '', avatar: '');
      final row = (await tables.first(TableName.profiles)).valueOrNull!;
      expect(row.containsKey('age_bracket'), isFalse);
      expect(row.containsKey('avatar'), isFalse);
    });
  });

  group('update', () {
    setUp(() async => repo.create(displayName: 'Ada', ageBracket: '8-11'));

    test('updating an id that is not the stored profile is refused', () async {
      final failure = (await repo.update(id: 'nope', displayName: 'Nina')).failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect(failure!.detail, 'child_profile_missing');
    });

    test('a null patch is "leave unchanged": no write, same profile', () async {
      final before = (await repo.read()).valueOrNull!;
      final result = await repo.update(id: before.id);
      expect(result.valueOrNull!.displayName, 'Ada');
      expect(result.valueOrNull!.updatedAt, before.createdAt); // untouched
    });

    test('validation runs here, not in widgets', () async {
      final before = (await repo.read()).valueOrNull!;
      final failure = (await repo.update(id: before.id, displayName: ' ')).failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure).field, 'display_name');
    });

    test('a valid patch lands, stamps updated_at, and survives a re-read', () async {
      final before = (await repo.read()).valueOrNull!;
      clock.advance(const Duration(days: 2));
      final updated = await repo.update(
        id: before.id,
        displayName: 'Ada L.',
        ageBracket: '12-14',
        avatar: 'star',
      );
      final profile = updated.valueOrNull!;
      expect(profile.displayName, 'Ada L.');
      expect(profile.ageBracket, '12-14');
      expect(profile.avatar, 'star');
      expect(profile.updatedAt, DateTime.utc(2026, 11, 8, 9));
      // A fresh repository over the same store proves the document persisted.
      final reread = await LocalChildProfileRepository(tables, clock: clock).read();
      expect(reread.valueOrNull!.displayName, 'Ada L.');
    });

    test('the role guard protects updates too: foreign rows are not updatable', () async {
      final foreign = StorageTestLane.parentRoleRow();
      await tables.delete(TableName.profiles, eq: {'id': (await repo.read()).valueOrNull!.id});
      await tables.insert(TableName.profiles, foreign);
      final failure = (await repo.update(id: foreign['id']! as String, displayName: 'Zoe')).failureOrNull;
      expect(failure!.detail, 'child_profile_role_mismatch');
    });
  });
}
