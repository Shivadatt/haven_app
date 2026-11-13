import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_child/core/storage/child_local_state.dart';
import 'package:haven_child/features/registration/data/demo_registration_service.dart';
import 'package:haven_child/features/registration/data/registration_repository.dart';
import 'package:haven_child/features/registration/domain/registration_audit.dart';

import '../support/storage.dart';
import 'registration_test_support.dart';

/// Risk R-1, enforced by a test rather than by a comment.
///
/// The contract rule (`docs/implementation/00-app-contract.md:108-109`) is
/// that a pairing code is never persisted and never logged — plaintext or
/// otherwise. These tests drive the DEMO lane through every path that touches
/// a code, then read the document exactly as `haven_local.json` would hold it
/// and look for the strings.
void main() {
  /// Runs the widest code-touching sequence the DEMO lane has: an expired
  /// attempt, a wrong code, a duplicate refusal, a success, an unpair and a
  /// fresh success.
  Future<List<String>> exerciseEverything(RegistrationTestHarness lane) async {
    final DemoRegistrationService demo = lane.demo;
    final List<String> codes = <String>[];

    codes.add(demo.issueDemoCode());
    lane.advance(const Duration(minutes: 7)); // the first code is now stale
    codes.add(demo.issueDemoCode());
    await demo.submitPairingCode('000000'); // shape-ok, never minted
    await demo.submitPairingCode(codes.last); // accepted
    await demo.submitPairingCode(codes.last); // duplicate refusal
    codes.add(demo.issueDemoCode());
    await demo.submitPairingCode(codes.last); // duplicate guard again
    await demo.unpair();
    await demo.startOver();
    codes.add(demo.issueDemoCode());
    await demo.submitPairingCode(codes.last);
    return codes;
  }

  test('no persisted document ever contains a pairing code', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final List<String> codes = await exerciseEverything(lane);
    expect(codes, hasLength(4));

    final String stored = await lane.serializedDocument();
    final String attempted = lane.serializedSaveAttempts();
    for (final String code in codes) {
      expect(stored, isNot(contains(code)), reason: 'saved: $code');
      expect(attempted, isNot(contains(code)), reason: 'attempted: $code');
    }
    expect(jsonDecode(stored), isA<Map<String, Object?>>());
  });

  test('the audit lane records a digit count and nothing that identifies it', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final List<String> codes = await exerciseEverything(lane);

    for (final RegistrationAuditRow row in lane.demo.audit) {
      final Map<String, Object?> map = row.toMap();
      expect(
        map.keys.where((String k) => k.startsWith('code') && k != 'code_digits'),
        isEmpty,
      );
      if (row.codeDigits != null) expect(row.codeDigits, 6);
      for (final Object? value in map.values) {
        for (final String code in codes) {
          expect('$value', isNot(contains(code)));
        }
      }
    }
    expect(
      lane.demo.audit.map((RegistrationAuditRow r) => r.kind).toSet(),
      containsAll(<RegistrationAuditKind>[
        RegistrationAuditKind.codeSubmitted,
        RegistrationAuditKind.demoAccepted,
        RegistrationAuditKind.duplicateBlocked,
        RegistrationAuditKind.unpairedLocally,
      ]),
    );
  });

  test('the serialized registration section names only status, id and audit', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    await exerciseEverything(lane);

    final Map<String, Object?> document =
        (await lane.store.load()).valueOrNull!;
    final Map<String, Object?> state =
        (document[ChildLocalStateStore.documentKey]! as Map)
            .cast<String, Object?>();
    final Map<String, Object?> section =
        state[LocalRegistrationRepository.registrationSection]! as Map<String, Object?>;

    expect(section.keys, <String>['status', 'stable_local_id', 'audit']);
    expect(
      section.keys.where((String k) => k.contains('code') && k != 'code_digits'),
      isEmpty,
    );
    expect(section['stable_local_id'], 'child-test-stable-id');
  });

  test('on the real file lane the JSON bytes on disk hold no code either', () async {
    final String dir = StorageTestLane.createTempDirectory();
    addTearDown(() => StorageTestLane.deleteTemp(dir));

    final LocalRegistrationRepository repository = LocalRegistrationRepository(
      ChildLocalStateStore(
        store: FileLocalStore(dir),
        tables: StorageTestLane.tablesAt(dir),
      ),
      clock: FixedClock(RegistrationTestHarness.defaultStart),
    );
    final DemoRegistrationService demo = DemoRegistrationService(
      clock: FixedClock(RegistrationTestHarness.defaultStart),
      persistence: repository,
      localIdMinter: () => 'child-file-stable-id',
    );

    final List<String> codes = <String>[
      demo.issueDemoCode(),
      demo.issueDemoCode(),
    ];
    await demo.submitPairingCode(codes.first);
    await demo.unpair();
    await demo.submitPairingCode(codes.last);

    final String raw = StorageTestLane.readRawDocument(dir);
    for (final String code in codes) {
      expect(raw, isNot(contains(code)), reason: 'plaintext leaked to disk: $code');
    }
    expect(raw, contains('child-file-stable-id'));
    expect(raw, contains('code_digits'));
  });

  test('a stable local id is not derived from a code, and survives an unpair', () async {
    final RegistrationTestHarness lane = RegistrationTestHarness();
    final List<String> codes = await exerciseEverything(lane);

    expect(lane.demo.snapshot.stableLocalId, 'child-test-stable-id');
    for (final String code in codes) {
      expect(lane.demo.snapshot.stableLocalId, isNot(contains(code)));
      expect(lane.demo.snapshot.stableLocalId!.length, isNot(code.length));
    }
  });
}
