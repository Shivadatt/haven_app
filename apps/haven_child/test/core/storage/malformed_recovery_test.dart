import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';

import 'package:haven_child/core/storage/child_database.dart';
import 'package:haven_child/core/storage/child_data_resetter.dart';
import 'package:haven_child/core/storage/child_local_state.dart';
import 'package:haven_child/core/storage/child_storage_paths.dart';
import 'package:haven_child/core/storage/local_child_profile_repository.dart';

import '../../support/storage.dart';

/// Brief §7: "malformed storage recovery (typed corrupt failure, no silent
/// reset, developer reset replaces)". Everything here runs on a real temp
/// file — plain `test()` bodies use the real event loop, so no runAsync.
void main() {
  late String dir;
  setUp(() => dir = StorageTestLane.createTempDirectory());
  tearDown(() => StorageTestLane.deleteTemp(dir));

  group('a damaged document is loud, typed and untouched', () {
    test('an unparseable file fails the open with local_database_corrupt', () async {
      StorageTestLane.writeRawDocument(dir, '{"schemaVersion": 1, "tables": ');
      final opened = await ChildDatabase.openAt(dir);
      final failure = opened.failureOrNull;
      expect(failure, isA<StorageFailure>());
      expect(failure!.detail!, startsWith('local_database_corrupt'));
      expect(isCorruptLocalDatabase(failure), isTrue);
      // NO silent reset: the damaged bytes are exactly where they were.
      expect(StorageTestLane.readRawDocument(dir), contains('"tables": '));
    });

    test('a JSON array (valid JSON, wrong shape) is corrupt too', () async {
      StorageTestLane.writeRawDocument(dir, '[1, 2, 3]');
      final failure = (await ChildDatabase.openAt(dir)).failureOrNull;
      expect(isCorruptLocalDatabase(failure!), isTrue);
    });

    test('a document from a NEWER build is refused, never downgraded', () async {
      StorageTestLane.writeRawDocument(dir, '{"schemaVersion": 99, "tables": {}}');
      final failure = (await ChildDatabase.openAt(dir)).failureOrNull;
      expect(failure, isA<StorageFailure>());
      expect(failure!.detail!, contains('schema 99'));
      expect(isCorruptLocalDatabase(failure), isTrue);
    });

    test('a missing file is a first launch, not a failure', () async {
      final opened = await ChildDatabase.openAt(dir);
      expect(opened.isOk, isTrue);
      final repo = LocalChildProfileRepository(opened.valueOrNull!.tables);
      expect((await repo.read()).valueOrNull, isNull);
    });

    test('section reads pass the typed failure through, not an implicit null', () async {
      StorageTestLane.writeRawDocument(dir, 'garbage{');
      final state = ChildLocalStateStore(
        store: FileLocalStore(dir),
        tables: StorageTestLane.tablesAt(dir),
      );
      final loaded = await state.readSection(ChildLocalStateStore.onboardingSection);
      expect(loaded.isErr, isTrue);
      expect(isCorruptLocalDatabase(loaded.failureOrNull!), isTrue);
    });
  });

  group('the developer reset is explicit and complete', () {
    test('the plain wipe path REFUSES a corrupt document (readable-first)', () async {
      StorageTestLane.writeRawDocument(dir, 'garbage{');
      final refused = await ChildDataResetter.clearAll(directoryPath: dir);
      expect(refused.isErr, isTrue);
      expect(StorageTestLane.readRawDocument(dir), 'garbage{');
    });

    test('the exit hatch replaces the damage; the app then opens empty', () async {
      StorageTestLane.writeRawDocument(dir, 'garbage{');
      final done = await ChildDataResetter.clearAll(
        directoryPath: dir,
        verifyReadableFirst: false,
      );
      expect(done.isOk, isTrue);
      final opened = await ChildDatabase.openAt(dir);
      expect(opened.isOk, isTrue);
      final profiles = LocalChildProfileRepository(opened.valueOrNull!.tables);
      expect((await profiles.read()).valueOrNull, isNull);
      // And the replacement itself is a valid document on disk.
      expect(StorageTestLane.readRawDocument(dir), contains('schemaVersion'));
    });
  });

  group('ChildStoragePaths', () {
    tearDown(() => ChildStoragePaths.overrideForTests(null));

    test('the test seam redirects the whole storage lane', () async {
      ChildStoragePaths.overrideForTests(() async => dir);
      final resolved = await ChildStoragePaths.resolve();
      expect(resolved.valueOrNull, dir);
    });

    test('a resolver that throws becomes a typed failure, never a throw', () async {
      ChildStoragePaths.overrideForTests(
        () async => throw StateError('no documents directory here'),
      );
      final resolved = await ChildStoragePaths.resolve();
      final failure = resolved.failureOrNull;
      expect(failure, isA<StorageFailure>());
      expect(failure!.detail!, startsWith('storage_path_unresolved'));
    });

    test('with no seam and no plugin (test host) the answer is still typed', () async {
      // The real path_provider channel has no handler under flutter_test;
      // resolve must catch the MissingPluginException and answer honestly.
      TestWidgetsFlutterBinding.ensureInitialized();
      final resolved = await ChildStoragePaths.resolve();
      final failure = resolved.failureOrNull;
      expect(failure, isA<StorageFailure>());
      expect(failure!.message, 'Local storage is not available on this device.');
    });
  });
}
