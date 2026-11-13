import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_child/core/storage/child_local_state.dart';
import 'package:haven_child/features/registration/data/registration_repository.dart';
import 'package:haven_child/features/registration/domain/registration_audit.dart';
import 'package:haven_child/features/registration/domain/registration_codec.dart';
import 'package:haven_child/features/registration/domain/registration_status.dart';

import '../support/storage.dart';
import 'registration_test_support.dart';

/// Persistence contract: only the status, the stable local id and the audit
/// rows cross the storage boundary, through the child app's ONE existing lane
/// (`childLocalState` inside `haven_local.json`) — never a second database.
void main() {
  late RegistrationTestHarness lane;
  setUp(() => lane = RegistrationTestHarness());

  test('a snapshot survives the round trip through the real section writer', () async {
    final RegistrationSnapshot snapshot = RegistrationSnapshot(
      status: Registered(
        stableLocalId: 'child-test-stable-id',
        registeredAt: RegistrationTestHarness.defaultStart,
      ),
      stableLocalId: 'child-test-stable-id',
      audit: <RegistrationAuditRow>[
        RegistrationAuditRow(
          kind: RegistrationAuditKind.codeSubmitted,
          at: RegistrationTestHarness.defaultStart,
          codeDigits: 6,
        ),
        RegistrationAuditRow(
          kind: RegistrationAuditKind.demoAccepted,
          at: RegistrationTestHarness.defaultStart,
          codeDigits: 6,
        ),
      ],
    );

    expect((await lane.repository.save(snapshot)).isOk, isTrue);
    final RegistrationSnapshot back = (await lane.repository.load()).valueOrNull!;

    expect(back.status, isA<Registered>());
    expect((back.status as Registered).stableLocalId, 'child-test-stable-id');
    expect(
      (back.status as Registered).registeredAt,
      RegistrationTestHarness.defaultStart,
    );
    expect(back.stableLocalId, 'child-test-stable-id');
    expect(back.audit.length, 2);
    expect(back.audit.first.kind, RegistrationAuditKind.codeSubmitted);
    expect(back.audit.last.at, RegistrationTestHarness.defaultStart);

    // And it really is the additive section inside the shared document key.
    final String document = await lane.serializedDocument();
    expect(document, contains(ChildLocalStateStore.documentKey));
    expect(document, contains(LocalRegistrationRepository.registrationSection));
  });

  test('a missing section is "never registered", not a failure', () async {
    final RegistrationSnapshot loaded = (await lane.repository.load()).valueOrNull!;
    expect(loaded.status, isA<Unregistered>());
    expect(loaded.audit, isEmpty);
    expect(loaded.stableLocalId, isNull);
  });

  test('the two writers of one document do not resurrect each other', () async {
    await lane.localState.writeSection(
      ChildLocalStateStore.sessionSection,
      <String, Object?>{
        'profile_id': 'p1',
        'created_at': '2026-11-06T00:00:00.000Z',
      },
    );
    await lane.repository.save(RegistrationSnapshot.empty());

    final Map<String, Object?>? state = (await lane.localState
        .readSection(ChildLocalStateStore.sessionSection)).valueOrNull;
    expect(state?['profile_id'], 'p1', reason: 'registration did not clobber the session');

    await lane.localState.writeSection(
      ChildLocalStateStore.sessionSection,
      <String, Object?>{
        'profile_id': 'p2',
        'created_at': '2026-11-06T00:00:00.000Z',
      },
    );
    final RegistrationSnapshot again = (await lane.repository.load()).valueOrNull!;
    expect(again.status, isA<Unregistered>());
  });

  test('a malformed section recovers to unregistered and says it did', () async {
    await lane.seedRawSection(<String, Object?>{
      'status': <String, Object?>{'kind': 'registered-by-a-future-build'},
    });

    final RegistrationSnapshot loaded = (await lane.repository.load()).valueOrNull!;
    expect(loaded.status, isA<Unregistered>());
    expect(loaded.audit.single.kind,
        RegistrationAuditKind.stateRestoredFromMalformed);
    expect(loaded.audit.single.note, 'registration_section_unreadable');

    // The repair is written back, so the next launch is not stuck on garbage.
    final RegistrationSnapshot second = (await lane.repository.load()).valueOrNull!;
    expect(second.audit, hasLength(1));
    expect(second.status, isA<Unregistered>());
  });

  test('a malformed audit entry is refused as a whole, never guessed row by row', () async {
    await lane.seedRawSection(<String, Object?>{
      'status': const Unregistered().toMap(),
      'audit': <Object?>[
        <String, Object?>{'event': 'code-submitted'}, // no timestamp: malformed
      ],
    });
    final RegistrationSnapshot loaded = (await lane.repository.load()).valueOrNull!;
    expect(loaded.status, isA<Unregistered>());
    expect(loaded.audit.single.kind,
        RegistrationAuditKind.stateRestoredFromMalformed);
  });

  test('a pending DEMO attempt that outlived its TTL loads as expired', () async {
    final RegistrationSnapshot stored = await lane.savePendingAttempt();
    expect(stored.status, isA<DemoPending>());

    lane.advance(const Duration(minutes: 6));
    final RegistrationSnapshot loaded = (await lane.repository.load()).valueOrNull!;
    expect(loaded.status, isA<Rejected>());
    expect(
      (loaded.status as Rejected).reason,
      RegistrationRejectReason.codeExpired,
      reason: 'a relaunch must not offer an attempt that already timed out',
    );
    expect((loaded.status as Rejected).attemptsUsed, 1);
  });

  group('on the real file lane', () {
    late String dir;
    late LocalRegistrationRepository repository;

    setUp(() {
      dir = StorageTestLane.createTempDirectory();
      addTearDown(() => StorageTestLane.deleteTemp(dir));
      repository = LocalRegistrationRepository(
        ChildLocalStateStore(
          store: FileLocalStore(dir),
          tables: StorageTestLane.tablesAt(dir),
        ),
        clock: FixedClock(RegistrationTestHarness.defaultStart),
      );
    });

    test('a damaged DOCUMENT is a typed failure and is never reset', () async {
      StorageTestLane.writeRawDocument(dir, '{"schemaVersion": 1, "tables": ');
      final Result<RegistrationSnapshot> loaded = await repository.load();
      expect(loaded.isErr, isTrue);
      expect(loaded.failureOrNull, isA<StorageFailure>());
      expect(
        StorageTestLane.readRawDocument(dir),
        contains('"tables": '),
        reason: 'the registration lane does not own the engine\'s reset rule',
      );
    });

    test('a write and a read round-trip through the JSON file', () async {
      expect(
        (await repository.save(
          RegistrationSnapshot(
            status: const Unregistered(),
            stableLocalId: 'child-file-id',
          ),
        )).isOk,
        isTrue,
      );
      expect(StorageTestLane.readRawDocument(dir), contains('child-file-id'));
      final RegistrationSnapshot loaded = (await repository.load()).valueOrNull!;
      expect(loaded.stableLocalId, 'child-file-id');
    });

    test('clear removes the section and leaves the document valid', () async {
      await repository.save(RegistrationSnapshot.empty());
      expect((await repository.clear()).isOk, isTrue);
      final RegistrationSnapshot loaded = (await repository.load()).valueOrNull!;
      expect(loaded.status, isA<Unregistered>());
      expect(StorageTestLane.readRawDocument(dir), contains('schemaVersion'));
    });
  });
}
