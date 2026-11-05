import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_app/features/onboarding/data/local_onboarding_repository.dart';

import '../support/fakes.dart';

void main() {
  late InMemoryLocalStore store;
  late LocalTables tables;
  late LocalChangeFeed feed;
  late LocalRowReader rows;
  late LocalRowWriter writer;
  late LocalProfileStore profiles;
  late FakeUserAuth auth;
  late LocalOnboardingRepository subject;

  const session = AuthSession(
    userId: 'parent-1',
    email: 'parent@haven.local',
    accessToken: 'local:parent-1',
    role: 'parent',
  );

  setUp(() async {
    store = InMemoryLocalStore();
    tables = LocalTables(store);
    await tables.open();
    feed = LocalChangeFeed();
    rows = LocalRowReader(tables);
    writer = LocalRowWriter(tables, feed);
    profiles = LocalProfileStore(tables);
    auth = FakeUserAuth(session);

    subject = LocalOnboardingRepository(
      auth: () => auth,
      rows: () => rows,
      writer: () => writer,
      profiles: () => profiles,
    );

    // Initial parent profile
    await tables.insert(TableName.profiles, <String, Object?>{
      'id': 'parent-1',
      'email': 'parent@haven.local',
      'role': 'unset',
      'display_name': 'Parent One',
    });
  });

  group('LocalOnboardingRepository', () {
    test('claimParentRole updates the parent profile role', () async {
      final res = await subject.claimParentRole();
      expect(res.isOk, isTrue);

      final row = await tables.first(TableName.profiles, eq: {'id': 'parent-1'});
      expect(row.valueOrNull!['role'], 'parent');
    });

    test('createFamily inserts family and family member rows', () async {
      final res = await subject.createFamily(name: 'The Rivera Family');
      expect(res.isOk, isTrue);

      final familyRows = await tables.rows(TableName.families);
      expect(familyRows.valueOrNull!.length, 1);
      expect(familyRows.valueOrNull!.first['name'], 'The Rivera Family');

      final memberRows = await tables.rows(TableName.familyMembers);
      expect(memberRows.valueOrNull!.length, 1);
      expect(memberRows.valueOrNull!.first['user_id'], 'parent-1');
      expect(memberRows.valueOrNull!.first['role'], 'parent');
    });

    test('createFamily validates name boundaries', () async {
      final empty = await subject.createFamily(name: '   ');
      expect(empty.isErr, isTrue);

      final tooLong = await subject.createFamily(name: 'A' * 81);
      expect(tooLong.isErr, isTrue);
    });

    test('createChild inserts child profile and family member', () async {
      await subject.createFamily(name: 'The Rivera Family');

      final childResult = await subject.createChild(
        name: 'Leo',
        ageGroup: 'child',
        avatar: 'fox',
      );
      expect(childResult.isOk, isTrue);
      final childId = childResult.valueOrNull!;

      final childProfile = await tables.first(TableName.profiles, eq: {'id': childId});
      expect(childProfile.valueOrNull!['display_name'], 'Leo');
      expect(childProfile.valueOrNull!['role'], 'child');
      expect(childProfile.valueOrNull!['age_group'], 'child');
      expect(childProfile.valueOrNull!['avatar'], 'fox');

      final childMember = await tables.first(TableName.familyMembers, eq: {'user_id': childId});
      expect(childMember.valueOrNull!['role'], 'child');
      expect(childMember.valueOrNull!['status'], 'active');
    });

    test('createChild rejects invalid child names', () async {
      await subject.createFamily(name: 'The Rivera Family');

      final empty = await subject.createChild(name: ' ', ageGroup: 'child');
      expect(empty.isErr, isTrue);

      final short = await subject.createChild(name: 'L', ageGroup: 'child');
      expect(short.isErr, isTrue);

      final long = await subject.createChild(name: 'L' * 61, ageGroup: 'child');
      expect(long.isErr, isTrue);
    });
  });
}
