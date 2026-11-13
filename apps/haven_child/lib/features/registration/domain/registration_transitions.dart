import 'package:haven_core/haven_core.dart';

import 'registration_status.dart';

/// The explicit registration transition table.
///
/// Stage 2 is a contracts workstream, so the rules a later backend will have to
/// satisfy are written down HERE rather than inferred from a screen. Illegal
/// moves are a typed [ValidationFailure] — never a throw, never a silent
/// no-op — because the contract says every seam answers with `Result`.
abstract final class RegistrationTransitions {
  /// The one table. Anything not listed here is refused.
  ///
  /// Reading of the rows:
  /// * `unregistered` can start a DEMO attempt, or be refused outright by the
  ///   BLOCKED lane without ever entering `demoPending`;
  /// * `demoPending` resolves to `registered`, falls to `rejected`, can be
  ///   retried (self-transition with a higher attempt count), or be cleared
  ///   back to `unregistered`;
  /// * `registered` only ever leaves through `revoked` (local unpair) or a
  ///   full local reset back to `unregistered`;
  /// * `rejected` can move to `demoPending`, to another `rejected` (a further
  ///   failed attempt, which is how the attempt cap is reported), or be
  ///   cleared;
  /// * `revoked` can start clean again. It never returns to `registered` by
  ///   itself — a revoked device must go through a fresh attempt.
  static const Map<RegistrationKind, Set<RegistrationKind>> allowed =
      <RegistrationKind, Set<RegistrationKind>>{
        RegistrationKind.unregistered: <RegistrationKind>{
          RegistrationKind.demoPending,
          RegistrationKind.rejected,
        },
        RegistrationKind.demoPending: <RegistrationKind>{
          RegistrationKind.demoPending,
          RegistrationKind.registered,
          RegistrationKind.rejected,
          RegistrationKind.unregistered,
        },
        RegistrationKind.registered: <RegistrationKind>{
          RegistrationKind.revoked,
          RegistrationKind.unregistered,
        },
        RegistrationKind.rejected: <RegistrationKind>{
          RegistrationKind.demoPending,
          // A further failed attempt is a fresh rejection carrying a higher
          // attempt counter — `rejected -> rejected` is legal, and the only
          // way an attempt cap can be reported after the first rejection.
          RegistrationKind.rejected,
          RegistrationKind.unregistered,
        },
        RegistrationKind.revoked: <RegistrationKind>{
          RegistrationKind.unregistered,
          RegistrationKind.demoPending,
        },
      };

  static bool isAllowed(RegistrationKind from, RegistrationKind to) =>
      allowed[from]?.contains(to) ?? false;

  static Set<RegistrationKind> allowedNext(RegistrationStatus from) =>
      allowed[from.kind] ?? const <RegistrationKind>{};

  /// The gate every service must pass through before it stores anything.
  ///
  /// `from == to` is refused on purpose except for `demoPending`, whose retry
  /// carries a different attempt count: same-kind state changes go through
  /// [isAllowed], which lists `demoPending -> demoPending` explicitly.
  static Result<RegistrationStatus> move(
    RegistrationStatus from,
    RegistrationStatus to,
  ) {
    if (isAllowed(from.kind, to.kind)) return Ok<RegistrationStatus>(to);
    return Err<RegistrationStatus>(
      illegalTransition(from, to),
    );
  }

  /// The typed error an illegal move produces. Field and detail are stable so
  /// a test can name the exact refusal it expects.
  static ValidationFailure illegalTransition(
    RegistrationStatus from,
    RegistrationStatus to,
  ) => ValidationFailure(
    'Haven cannot take this device from "${from.kind.wire}" to '
    '"${to.kind.wire}" — that is not a legal registration step.',
    field: 'registration_transition',
    detail:
        'illegal_transition: ${from.kind.wire} -> ${to.kind.wire}. Allowed next '
        'from ${from.kind.wire}: '
        '${(allowed[from.kind] ?? const <RegistrationKind>{}).map((RegistrationKind k) => k.wire).join(', ')}',
  );

  /// True when SOME legal path — one step or several — leads from [from] to
  /// [target]. This is the difference between "not yet" and "never": `move`
  /// answers the single-step question, this answers the reachability one, and
  /// a screen that offers "keep trying" must be able to tell them apart.
  static bool reachable(RegistrationKind from, RegistrationKind target) {
    final Set<RegistrationKind> seen = <RegistrationKind>{};
    final List<RegistrationKind> queue = <RegistrationKind>[from];
    while (queue.isNotEmpty) {
      final RegistrationKind current = queue.removeLast();
      if (current == target) return true;
      if (!seen.add(current)) continue;
      queue.addAll(allowed[current] ?? const <RegistrationKind>{});
    }
    return false;
  }
}
