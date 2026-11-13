import 'dart:convert';

import 'package:haven_api/haven_api.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_child/core/storage/child_local_state.dart';
import 'package:haven_child/features/registration/data/demo_registration_policy.dart';
import 'package:haven_child/features/registration/data/demo_registration_service.dart';
import 'package:haven_child/features/registration/data/registration_repository.dart';
import 'package:haven_child/features/registration/domain/registration_codec.dart';
import 'package:haven_child/features/registration/domain/registration_status.dart';

/// Hand-written fixtures for the registration lane — no mocking package, per
/// `docs/implementation/00-app-contract.md` ("Test conventions").
///
/// The storage side is the REAL child lane (`ChildLocalStateStore` over
/// `haven_api`'s in-memory document), because a contract test that faked its
/// own persistence would prove nothing about what reaches
/// `haven_local.json`. The clock is `haven_core`'s `FixedClock`, so expiry is
/// arithmetic rather than a sleep.
final class RegistrationTestHarness {
  RegistrationTestHarness({
    DateTime? start,
    DemoRegistrationPolicy policy = const DemoRegistrationPolicy(),
    this.persist = true,
  }) : clock = FixedClock(start ?? DateTime.utc(2026, 11, 13, 9, 30)) {
    localState = ChildLocalStateStore(store: store, tables: tables);
    repository = LocalRegistrationRepository(localState, clock: clock);
    demo = DemoRegistrationService(
      clock: clock,
      policy: policy,
      persistence: persist ? repository : null,
      localIdMinter: () => 'child-test-stable-id',
    );
  }

  static final DateTime defaultStart = DateTime.utc(2026, 11, 13, 9, 30);

  final FixedClock clock;
  final bool persist;

  /// The single document every writer in the child app shares.
  final InMemoryLocalStore store = InMemoryLocalStore();
  late final LocalTables tables = LocalTables(store);
  late final ChildLocalStateStore localState;
  late final LocalRegistrationRepository repository;
  late final DemoRegistrationService demo;

  /// Advances the frozen clock — the only way expiry is exercised here.
  void advance(Duration by) => clock.advance(by);

  /// The document exactly as it would be written to `haven_local.json`.
  Future<String> serializedDocument() async {
    final Map<String, Object?>? database = (await store.load()).valueOrNull;
    return jsonEncode(database ?? <String, Object?>{});
  }

  /// Every document handed to `save`, serialized — a failed write still shows
  /// what the lane attempted, which is what the no-plaintext scan needs.
  String serializedSaveAttempts() =>
      jsonEncode(store.saves.map((Map<String, Object?> d) => d).toList());

  /// Writes a damaged `registration` section straight into the document,
  /// without touching the engine's own corruption checks.
  Future<void> seedRawSection(Map<String, Object?> section) async {
    final Map<String, Object?> database =
        (await store.load()).valueOrNull ?? <String, Object?>{};
    database[ChildLocalStateStore.documentKey] = <String, Object?>{
      ...?((database[ChildLocalStateStore.documentKey] as Map?)
          ?.cast<String, Object?>()),
      LocalRegistrationRepository.registrationSection: section,
    };
    await store.save(database);
  }

  /// Writes a `demoPending` snapshot directly, so the expiry-at-load rule can
  /// be tested without a service in the way (used by the repository test,
  /// which is over the 200-line source rule if the helper stays there).
  Future<RegistrationSnapshot> savePendingAttempt() async {
    final RegistrationSnapshot pending = RegistrationSnapshot(
      status: DemoPending(
        startedAt: RegistrationTestHarness.defaultStart,
        expiresAt: RegistrationTestHarness.defaultStart
            .add(const Duration(minutes: 5)),
        attemptsUsed: 1,
        codeDigits: 6,
      ),
      stableLocalId: 'child-test-stable-id',
    );
    await repository.save(pending);
    return pending;
  }
}
