import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';

import 'package:haven_child/core/session/child_local_session.dart';
import 'package:haven_child/core/storage/child_local_state.dart';
import 'package:haven_child/core/storage/onboarding_state_store.dart';

/// Brief §7: "storage serialization/deserialization round-trips" and
/// "session init/persistence/cleanup" — all against the real engine, in
/// memory. The file-backed write-coexistence proof lives in
/// `storage_coexistence_test.dart` (line-count rule).
void main() {
  group('OnboardingDraft map round-trip', () {
    test('toMap/fromMap preserve every field', () {
      const draft = OnboardingDraft(
        stepIndex: 2,
        displayName: 'Ada',
        ageBracket: '8-11',
        avatar: 'star',
      );
      final back = OnboardingDraft.fromMap(draft.toMap());
      expect(back.stepIndex, 2);
      expect(back.displayName, 'Ada');
      expect(back.ageBracket, '8-11');
      expect(back.avatar, 'star');
    });

    test('absent fields decode to nulls, a bare index to 0', () {
      final empty = OnboardingDraft.fromMap(const <String, Object?>{});
      expect(empty.stepIndex, 0);
      expect(empty.displayName, isNull);
      expect(empty.toMap(), const <String, Object?>{'step_index': 0});
    });

    test('a JSON int arrives as a num and still reads as an int', () {
      // jsonDecode hands back num; asInt must not choke on it.
      final draft = OnboardingDraft.fromMap(
        const <String, Object?>{'step_index': 3.0, 'display_name': 'Ada'},
      );
      expect(draft.stepIndex, 3);
    });

    test('LocalOnboardingStateStore round-trips through the document', () async {
      final state = ChildLocalStateStore(
        store: InMemoryLocalStore(),
        tables: LocalTables(InMemoryLocalStore()),
      );
      final store = LocalOnboardingStateStore(state);
      expect((await store.read()).valueOrNull, isNull);
      await store.save(const OnboardingDraft(stepIndex: 1, displayName: 'Ada'));
      final read = (await store.read()).valueOrNull;
      expect(read!.stepIndex, 1);
      expect(read.displayName, 'Ada');
      await store.clear();
      expect((await store.read()).valueOrNull, isNull);
    });
  });

  group('ChildLocalSession map round-trip', () {
    test('the session survives its stored form exactly', () {
      final session = ChildLocalSession(
        profileId: 'p1',
        createdAt: DateTime.utc(2026, 11, 6, 12, 30),
      );
      final back = ChildLocalSession.fromMap(session.toMap())!;
      expect(back.profileId, 'p1');
      expect(back.createdAt, DateTime.utc(2026, 11, 6, 12, 30));
    });

    test('a malformed session decodes to null — back through onboarding', () {
      expect(ChildLocalSession.fromMap(const {}), isNull);
      expect(ChildLocalSession.fromMap(const {'profile_id': ''}), isNull);
      expect(
        ChildLocalSession.fromMap(
          const {'profile_id': 'p1', 'created_at': 'not a date'},
        ),
        isNull,
      );
    });

    test('init, persist, re-read and cleanup through the store', () async {
      final state = ChildLocalStateStore(
        store: InMemoryLocalStore(),
        tables: LocalTables(InMemoryLocalStore()),
      );
      final store = LocalChildSessionStore(state);
      expect((await store.read()).valueOrNull, isNull);
      final session = ChildLocalSession(
        profileId: 'p9',
        createdAt: DateTime.utc(2026, 11, 6),
      );
      await store.save(session);
      expect((await store.read()).valueOrNull!.profileId, 'p9');
      await store.clear();
      expect((await store.read()).valueOrNull, isNull);
    });

    test('a damaged session section reads as null, never a crash', () async {
      final store = InMemoryLocalStore();
      await store.save(<String, Object?>{
        'schemaVersion': 1,
        'tables': <String, Object?>{},
        ChildLocalStateStore.documentKey: <String, Object?>{
          ChildLocalStateStore.sessionSection: <String, Object?>{'oops': true},
        },
      });
      final result = await LocalChildSessionStore(
        ChildLocalStateStore(store: store, tables: LocalTables(store)),
      ).read();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('the honest labels are fixed strings for every screen', () {
      expect(ChildLocalSession.parentConnectionLabel, 'Parent connection');
      expect(ChildLocalSession.parentConnectionStatus, 'Not connected');
    });
  });
}
