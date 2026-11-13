import 'package:flutter_test/flutter_test.dart';
import 'package:haven_child/features/registration/domain/registration_status.dart';
import 'package:haven_child/features/registration/domain/registration_transitions.dart';

/// Split off `registration_transitions_test.dart` under the 200-line source
/// rule (behaviour unchanged): reachability — "not yet" versus "never" — and
/// the storage-shape promise that a persisted status carries its kind and a
/// digit COUNT, never anything about the code itself.
void main() {
  final RegistrationStatus pending = DemoPending(
    startedAt: DateTime.utc(2026, 11, 13, 9),
    expiresAt: DateTime.utc(2026, 11, 13, 9, 5),
  );
  final RegistrationStatus registered = Registered(
    stableLocalId: 'child-1',
    registeredAt: DateTime.utc(2026, 11, 13, 9, 1),
  );

  test('reachable() separates "not yet" from "never"', () {
    // One step away: refused by the table, but reachable through it.
    expect(
      RegistrationTransitions.isAllowed(
        RegistrationKind.unregistered,
        RegistrationKind.registered,
      ),
      isFalse,
    );
    expect(
      RegistrationTransitions.reachable(
        RegistrationKind.unregistered,
        RegistrationKind.registered,
      ),
      isTrue,
      reason: 'unregistered -> demoPending -> registered',
    );

    // A registered device cannot be pushed back into an attempt, and the
    // only way out of `registered` is an unpair first.
    expect(
      RegistrationTransitions.isAllowed(
        RegistrationKind.registered,
        RegistrationKind.demoPending,
      ),
      isFalse,
    );
    expect(
      RegistrationTransitions.allowedNext(registered),
      isNot(contains(RegistrationKind.demoPending)),
    );

    // A self-move is a path of length zero plus one: pending retries
    // itself, so a pending device is never told "you cannot get there".
    expect(
      RegistrationTransitions.reachable(
        RegistrationKind.demoPending,
        RegistrationKind.demoPending,
      ),
      isTrue,
      reason: 'a retry while pending is a legal self-move',
    );
  });

  test('every status persists its kind and nothing else about the code', () {
    for (final RegistrationStatus status in <RegistrationStatus>[
      const Unregistered(),
      pending,
      registered,
      Rejected(
        reason: RegistrationRejectReason.codeFormat,
        attemptsUsed: 1,
        at: DateTime.utc(2026, 11, 13, 9, 1),
      ),
      Revoked(at: DateTime.utc(2026, 11, 13, 9, 2)),
    ]) {
      expect(status.toMap()['kind'], status.kind.wire);
      expect(
        status.toMap().keys.where((String k) =>
            k.contains('code') && k != 'code_digits'),
        isEmpty,
        reason: 'a stored status may hold a digit COUNT, never a code',
      );
    }
    expect(pending.toMap()['code_digits'], 6);
  });
}
