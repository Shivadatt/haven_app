import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';

import 'package:haven_child/core/session/child_local_session.dart';
import 'package:haven_child/core/storage/child_data_resetter.dart';
import 'package:haven_child/core/storage/child_local_state.dart';
import 'package:haven_child/core/storage/child_profile_repository.dart';
import 'package:haven_child/core/storage/local_child_profile_repository.dart';
import 'package:haven_child/core/storage/onboarding_state_store.dart';

import '../../support/storage.dart';

/// Brief §7: "storage write-coexistence (childLocalState vs tables never
/// clobber)" — on the real engine against a temp file, plus the explicit
/// developer reset clearing BOTH lanes at once. The pure serialization
/// round-trips live in `storage_roundtrip_test.dart`.
void main() {
  group('childLocalState and tables share one file without clobbering', () {
    late String dir;
    late FileLocalStore store;
    late LocalTables tables;
    late ChildLocalStateStore state;
    late ChildProfileRepository profiles;

    setUp(() {
      dir = StorageTestLane.createTempDirectory();
      addTearDown(() => StorageTestLane.deleteTemp(dir));
      store = FileLocalStore(dir);
      tables = LocalTables(store);
      state = ChildLocalStateStore(store: store, tables: tables);
      profiles = LocalChildProfileRepository(tables);
    });

    Future<void> reopen() async => tables.open();

    test('a section write keeps the table rows, and vice versa', () async {
      await profiles.create(displayName: 'Ada', ageBracket: '8-11');
      await state.writeSection(
        ChildLocalStateStore.onboardingSection,
        const OnboardingDraft(stepIndex: 2).toMap(),
      );

      // The section writer dropped the cache — the table reader must now see
      // BOTH its own row (from disk) and the section (from the same doc).
      await reopen();
      expect((await profiles.read()).valueOrNull!.displayName, 'Ada');
      expect(
        (await state.readSection(ChildLocalStateStore.onboardingSection))
            .valueOrNull!['step_index'],
        2,
      );

      // And the table writer must not drop the section either.
      await state.writeSection(
        ChildLocalStateStore.sessionSection,
        ChildLocalSession(
          profileId: 'p1',
          createdAt: DateTime.utc(2026, 11, 6),
        ).toMap(),
      );
      await reopen();
      expect((await profiles.read()).valueOrNull!.displayName, 'Ada');
      expect((await state.readSection(ChildLocalStateStore.sessionSection)).isOk, isTrue);
      expect(
        (await state.readSection(ChildLocalStateStore.onboardingSection)).valueOrNull,
        isNotNull,
      );
    });

    test('removing the last section removes the document key entirely', () async {
      await state.writeSection(ChildLocalStateStore.sessionSection, const {'a': 1});
      await state.writeSection(ChildLocalStateStore.sessionSection, null);
      final doc = (await store.load()).valueOrNull!;
      expect(doc.containsKey(ChildLocalStateStore.documentKey), isFalse);
    });

    test('a developer reset removes profile, sections, everything (delete lane)', () async {
      await profiles.create(displayName: 'Ada', ageBracket: '8-11');
      await state.writeSection(ChildLocalStateStore.onboardingSection, const {'x': 1});
      final done = await ChildDataResetter.clearAll(
        directoryPath: dir,
        verifyReadableFirst: false,
      );
      expect(done.isOk, isTrue);
      final fresh = LocalChildProfileRepository(StorageTestLane.tablesAt(dir));
      expect((await fresh.read()).valueOrNull, isNull);
      final freshState = ChildLocalStateStore(
        store: FileLocalStore(dir),
        tables: StorageTestLane.tablesAt(dir),
      );
      expect(
        (await freshState.readSection(ChildLocalStateStore.onboardingSection)).valueOrNull,
        isNull,
      );
    });
  });
}
