import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/family/data/family_models.dart';
import 'package:haven_app/features/family/data/family_repository.dart';
import 'package:haven_app/features/family/data/family_scope.dart';
import 'package:haven_core/haven_core.dart';

import '../support/fakes.dart';

void main() {
  const AuthSession session = AuthSession(
    userId: 'u1',
    email: 'parent@example.com',
    accessToken: 'test-token',
  );

  late LocalTables tables;
  late LocalRowReader rows;
  late LocalRowWriter writer;
  late FakeUserAuth auth;
  late FamilyScopeReader scope;
  late LocalFamilyRepository repository;

  setUp(() async {
    tables = LocalTables(InMemoryLocalStore());
    await tables.open();
    rows = LocalRowReader(tables);
    writer = LocalRowWriter(tables, LocalChangeFeed());
    auth = FakeUserAuth(session);
    scope = FamilyScopeReader(auth: () => auth, rows: () => rows);
    repository = LocalFamilyRepository(
      scope: () => scope,
      rows: () => rows,
      writer: () => writer,
    );
  });

  group('LocalFamilyRepository', () {
    test('createFamily creates a family and adds the signed-in parent', () async {
      final Result<void> result = await repository.createFamily(name: 'Rivera');
      expect(result.isOk, isTrue);

      final Result<FamilyBundle?> loaded = await repository.load();
      final FamilyBundle? bundle = loaded.valueOrNull;
      expect(bundle, isNotNull);
      expect(bundle!.family.name, 'Rivera');
      expect(bundle.parents.length, 1);
      expect(bundle.parents.first.userId, 'u1');
    });

    test('createFamily validates name bounds', () async {
      final Result<void> empty = await repository.createFamily(name: '   ');
      expect(empty.isErr, isTrue);
      expect(empty.failureOrNull, isA<ValidationFailure>());

      final Result<void> tooLong = await repository.createFamily(name: 'a' * 81);
      expect(tooLong.isErr, isTrue);
    });

    test('rename updates the family name in the local store', () async {
      await repository.createFamily(name: 'Initial');
      final Result<void> renameResult = await repository.rename(name: 'Updated Name');
      expect(renameResult.isOk, isTrue);

      final FamilyBundle? bundle = (await repository.load()).valueOrNull;
      expect(bundle?.family.name, 'Updated Name');
    });

    test('addChild creates profile and membership with avatar and age bracket', () async {
      await repository.createFamily(name: 'Rivera');
      final Result<FamilyPerson> added = await repository.addChild(
        name: 'Ivy',
        ageBracket: '8–11',
        avatar: '🦊',
      );
      expect(added.isOk, isTrue);
      final FamilyPerson child = added.valueOrNull!;
      expect(child.name, 'Ivy');
      expect(child.ageBracket, '8–11');
      expect(child.avatar, '🦊');

      final FamilyBundle? bundle = (await repository.load()).valueOrNull;
      expect(bundle!.children.length, 1);
      expect(bundle.children.first.name, 'Ivy');
      expect(bundle.children.first.ageBracket, '8–11');
      expect(bundle.children.first.avatar, '🦊');
    });

    test('addChild validates child name length between 1 and 60 chars', () async {
      await repository.createFamily(name: 'Rivera');
      final Result<FamilyPerson> empty = await repository.addChild(name: '');
      expect(empty.isErr, isTrue);
      expect(empty.failureOrNull, isA<ValidationFailure>());

      final Result<FamilyPerson> tooLong = await repository.addChild(name: 'c' * 61);
      expect(tooLong.isErr, isTrue);
    });

    test('updateChild updates display_name, age_bracket and avatar', () async {
      await repository.createFamily(name: 'Rivera');
      final FamilyPerson child = (await repository.addChild(
        name: 'Ivy',
        ageBracket: '4–7',
        avatar: '🦊',
      )).valueOrNull!;

      final Result<void> updated = await repository.updateChild(
        childUserId: child.userId,
        name: 'Ivy Rivera',
        ageBracket: '8–11',
        avatar: '🦁',
      );
      expect(updated.isOk, isTrue);

      final FamilyBundle? bundle = (await repository.load()).valueOrNull;
      final FamilyPerson read = bundle!.children.first;
      expect(read.name, 'Ivy Rivera');
      expect(read.ageBracket, '8–11');
      expect(read.avatar, '🦁');
    });

    test('unlinkChild marks member as removed when execute is true', () async {
      await repository.createFamily(name: 'Rivera');
      final FamilyPerson child = (await repository.addChild(name: 'Ivy')).valueOrNull!;

      // Probing without execute does not remove
      final Result<void> probe = await repository.unlinkChild(child.userId, execute: false);
      expect(probe.isOk, isTrue);
      expect((await repository.load()).valueOrNull!.children.length, 1);

      // Executing unlinks
      final Result<void> removed = await repository.unlinkChild(child.userId, execute: true);
      expect(removed.isOk, isTrue);
      expect((await repository.load()).valueOrNull!.children.isEmpty, isTrue);
    });

    test('inviteParent and removeParent stay honest refusals', () async {
      await repository.createFamily(name: 'Rivera');
      expect((await repository.inviteParent()).failureOrNull, isA<BlockedFailure>());
      expect((await repository.removeParent()).failureOrNull, isA<BlockedFailure>());
    });
  });
}
