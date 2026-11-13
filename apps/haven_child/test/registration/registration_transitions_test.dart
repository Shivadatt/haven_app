import 'package:flutter_test/flutter_test.dart';
import 'package:haven_core/haven_core.dart';
import 'package:haven_child/features/registration/domain/registration_status.dart';
import 'package:haven_child/features/registration/domain/registration_transitions.dart';

/// The Stage-2 registration state machine, as a table rather than as code that
/// "seemed right at the call site". Illegal moves are typed failures — never a
/// throw — because every seam in this repo answers with `Result`.
/// Reachability and the persisted-shape promise live in
/// `registration_transitions_reachable_test.dart`.
void main() {
  const RegistrationStatus unregistered = Unregistered();
  final RegistrationStatus pending = DemoPending(
    startedAt: DateTime.utc(2026, 11, 13, 9),
    expiresAt: DateTime.utc(2026, 11, 13, 9, 5),
  );
  final RegistrationStatus registered = Registered(
    stableLocalId: 'child-1',
    registeredAt: DateTime.utc(2026, 11, 13, 9, 1),
  );
  final RegistrationStatus rejected = Rejected(
    reason: RegistrationRejectReason.codeFormat,
    attemptsUsed: 1,
    at: DateTime.utc(2026, 11, 13, 9, 1),
  );
  final RegistrationStatus revoked = Revoked(
    at: DateTime.utc(2026, 11, 13, 9, 2),
  );

  group('the declared table', () {
    test('every state lists its legal moves and nothing else', () {
      expect(RegistrationTransitions.allowed.keys, RegistrationKind.values);
      expect(
        RegistrationTransitions.allowedNext(unregistered),
        containsAll(<RegistrationKind>[
          RegistrationKind.demoPending,
          RegistrationKind.rejected,
        ]),
      );
      expect(
        RegistrationTransitions.allowedNext(pending),
        contains(RegistrationKind.demoPending),
        reason: 'a retry while pending is a legal self-move with a new counter',
      );
      expect(
        RegistrationTransitions.allowedNext(registered),
        <RegistrationKind>{
          RegistrationKind.revoked,
          RegistrationKind.unregistered,
        },
      );
    });

    test('the legal moves land', () {
      for (final (RegistrationStatus from, RegistrationStatus to) in [
        (unregistered, pending),
        (pending, registered),
        (pending, rejected),
        (registered, revoked),
        (revoked, unregistered),
        (rejected, pending),
        (rejected, rejected),
      ]) {
        final Result<RegistrationStatus> moved = RegistrationTransitions.move(
          from,
          to,
        );
        expect(
          moved.isOk,
          isTrue,
          reason: '${from.kind.wire} -> ${to.kind.wire} must be legal',
        );
        expect(moved.valueOrNull, same(to));
      }
    });
  });

  group('illegal moves are refused with a typed failure', () {
    test('the table names them and the guard agrees', () {
      final List<(RegistrationStatus, RegistrationStatus)> forbidden =
          <(RegistrationStatus, RegistrationStatus)>[
            (unregistered, registered),
            (unregistered, revoked),
            (unregistered, unregistered),
            (registered, pending),
            (registered, registered),
            (registered, rejected),
            (revoked, registered),
            (revoked, revoked),
            (rejected, registered),
            (rejected, revoked),
          ];
      for (final (RegistrationStatus from, RegistrationStatus to) in forbidden) {
        expect(
          RegistrationTransitions.isAllowed(from.kind, to.kind),
          isFalse,
          reason: '${from.kind.wire} -> ${to.kind.wire}',
        );
      }
      expect(
        RegistrationTransitions.isAllowed(
          RegistrationKind.demoPending,
          RegistrationKind.demoPending,
        ),
        isTrue,
        reason: 'a retry while pending carries a new attempt count',
      );
      expect(
        RegistrationTransitions.isAllowed(
          RegistrationKind.demoPending,
          RegistrationKind.unregistered,
        ),
        isTrue,
        reason: 'an abandoned attempt clears back to unregistered',
      );
    });

    test('move() returns a ValidationFailure and never throws', () {
      final Result<RegistrationStatus> moved = RegistrationTransitions.move(
        registered,
        pending,
      );
      final HavenFailure failure = moved.failureOrNull!;
      expect(moved.isErr, isTrue);
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).field,
        'registration_transition',
      );
      expect(
        failure.detail,
        'illegal_transition: registered -> demoPending. Allowed next from '
        'registered: revoked, unregistered',
      );
      expect(failure.message, contains('not a legal registration step'));
    });

    test('a skipped step cannot be used to forge a registration', () {
      expect(
        RegistrationTransitions.isAllowed(
          RegistrationKind.unregistered,
          RegistrationKind.registered,
        ),
        isFalse,
        reason: 'registration is only ever reached from demoPending',
      );
      expect(
        RegistrationTransitions.isAllowed(
          RegistrationKind.revoked,
          RegistrationKind.registered,
        ),
        isFalse,
        reason: 'a revoked device must go through a fresh attempt',
      );
    });
  });
}
