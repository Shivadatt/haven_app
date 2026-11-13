import 'package:flutter_test/flutter_test.dart';
import 'package:haven_offline/haven_offline.dart';

void main() {
  late InMemoryLocalStore store;
  late LocalTables tables;

  setUp(() async {
    store = InMemoryLocalStore();
    tables = LocalTables(store);
    await tables.open();
  });

  group('local profile store', () {
    test('load finds the row by id, update renames it', () async {
      await tables.insert('profiles', <String, Object?>{
        'id': 'user-1',
        'display_name': 'A',
      });
      final profiles = LocalProfileStore(tables);
      expect(
        (await profiles.load('user-1')).valueOrNull!['display_name'],
        'A',
      );
      await profiles.updateDisplayName('user-1', 'Ada L.');
      expect(
        (await profiles.load('user-1')).valueOrNull!['display_name'],
        'Ada L.',
      );
    });

    test('createProfile validates and creates a new profile row', () async {
      final profiles = LocalProfileStore(tables);
      final invalid = await profiles.createProfile(
        userId: 'user-2',
        displayName: 'X',
      );
      expect(invalid.isErr, isTrue);

      final valid = await profiles.createProfile(
        userId: 'user-2',
        displayName: 'Parent One',
        email: 'parent@local.test',
      );
      expect(valid.isOk, isTrue);
      final loaded = await profiles.load('user-2');
      expect(loaded.valueOrNull!['display_name'], 'Parent One');
      expect(loaded.valueOrNull!['email'], 'parent@local.test');
      expect(loaded.valueOrNull!['role'], 'parent');
    });
  });
}
