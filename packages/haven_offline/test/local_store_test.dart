import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haven_offline/haven_offline.dart';
import 'package:haven_core/haven_core.dart';

/// A complete database document, shaped exactly as the store persists it.
Map<String, Object?> _databaseWith(String table, List<Map<String, Object?>> rows) =>
    <String, Object?>{
      localSchemaVersionKey: localSchemaVersion,
      localTablesKey: <String, Object?>{table: rows},
    };

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('haven_local_store');
  });
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  File dataFile(FileLocalStore store) =>
      File('${store.directoryPath}/${store.fileName}');

  group('LocalStore missing file', () {
    test('a missing file loads as an empty database, not a failure', () async {
      final store = FileLocalStore(dir.path);
      final loaded = await store.load();
      expect(loaded.isOk, isTrue);
      final db = loaded.valueOrNull!;
      expect(db[localSchemaVersionKey], localSchemaVersion);
      expect(LocalQueries_tablesOfIsEmpty(db), isTrue);
    });
  });

  group('LocalStore save + reopen', () {
    test('a second store instance over the same temp dir sees saved rows', () async {
      final first = FileLocalStore(dir.path);
      final saved = await first.save(
        _databaseWith('families', [
          <String, Object?>{'id': 'f1', 'name': 'Ada'},
        ]),
      );
      expect(saved.isOk, isTrue);

      final second = FileLocalStore(dir.path);
      final loaded = await second.load();
      expect(loaded.isOk, isTrue);
      final rows = (loaded.valueOrNull![localTablesKey]!
              as Map<String, Object?>)['families']!
          as List<Object?>;
      expect(rows.single, <String, Object?>{'id': 'f1', 'name': 'Ada'});
    });

    test('the in-memory store round-trips the document it is given', () async {
      final store = InMemoryLocalStore();
      await store.save(_databaseWith('profiles', [
        <String, Object?>{'id': 'p1'},
      ]));
      final loaded = await store.load();
      final rows = (loaded.valueOrNull![localTablesKey]!
              as Map<String, Object?>)['profiles']!
          as List<Object?>;
      expect((rows.single as Map<String, Object?>)['id'], 'p1');
    });
  });

  group('LocalStore atomic write', () {
    test('a stale .tmp artifact is ignored; the original stays loadable', () async {
      final store = FileLocalStore(dir.path);
      await store.save(_databaseWith('families', [
        <String, Object?>{'id': 'good'},
      ]));
      // Simulate a crash mid-write: the rename never ran, so a torn .tmp is left
      // beside a complete original file.
      File('${dataFile(store).path}.tmp').writeAsStringSync('{ "trunc');

      final reopened = await FileLocalStore(dir.path).load();
      expect(reopened.isOk, isTrue, reason: 'the .tmp must not shadow the real file');
      final rows = (reopened.valueOrNull![localTablesKey]!
              as Map<String, Object?>)['families']!
          as List<Object?>;
      expect((rows.single as Map<String, Object?>)['id'], 'good');
    });
  });

  group('LocalStore corrupt document', () {
    test('unparseable JSON is a typed failure and the bytes are untouched', () async {
      final store = FileLocalStore(dir.path);
      const bytes = '{ this is not json';
      dataFile(store).writeAsStringSync(bytes);

      final loaded = await store.load();
      expect(loaded.isErr, isTrue);
      final failure = loaded.failureOrNull!;
      expect(failure, isA<StorageFailure>());
      expect(isCorruptLocalDatabase(failure), isTrue);
      // Loud, never silent: the original bytes are still exactly on disk.
      expect(dataFile(store).readAsStringSync(), bytes);
    });

    test('a top-level JSON array is refused, not auto-reset', () async {
      final store = FileLocalStore(dir.path);
      dataFile(store).writeAsStringSync(jsonEncode([1, 2, 3]));

      final loaded = await store.load();
      expect(isCorruptLocalDatabase(loaded.failureOrNull!), isTrue);
      expect(dataFile(store).existsSync(), isTrue);
    });

    test('a document from a newer schema version is refused', () async {
      final store = FileLocalStore(dir.path);
      dataFile(store).writeAsStringSync(
        jsonEncode(<String, Object?>{
          localSchemaVersionKey: localSchemaVersion + 1,
          localTablesKey: <String, Object?>{},
        }),
      );
      final loaded = await store.load();
      expect(isCorruptLocalDatabase(loaded.failureOrNull!), isTrue);
    });
  });
}

/// Empty-tables probe kept local to the test so the assertion reads plainly.
bool LocalQueries_tablesOfIsEmpty(Map<String, Object?> database) {
  final tables = database[localTablesKey];
  return tables is Map && tables.isEmpty;
}
