import 'package:haven_core/haven_core.dart';

import 'demo_registration_policy.dart';

/// The DEMO lane's code-issuance bookkeeping, split out of
/// `demo_registration_service.dart` to keep both files inside the 200-line
/// source rule without changing what the service does.
///
/// The plaintext code lives ONLY here, in memory: [issue] hands it to the
/// calling screen, [accept] and [discard] drop it. It is never persisted,
/// never logged, never placed in an audit row — contract rule
/// (`docs/implementation/00-app-contract.md:108-109`, risk R-1). The only
/// code-derived fact that ever leaves this class is the digit COUNT.
final class DemoCodeLane {
  DemoCodeLane({required this.clock, required this.policy});

  final Clock clock;
  final DemoRegistrationPolicy policy;

  String? _issuedCode;
  DateTime? _issuedAt;
  final Set<String> _redeemedCodes = <String>{};
  int _sequence = 0;
  int _attempts = 0;

  int get attemptsUsed => _attempts;

  /// Re-seeds the counter from a restored `demoPending` state, so a relaunch
  /// continues the same DEMO attempt budget rather than starting at zero.
  void restoreAttempts(int used) => _attempts = used;

  /// Mints the next deterministic DEMO code (6 digits, D-3 option (ii)).
  String issue() {
    final String code = policy.demoCodeFor(_sequence++);
    _issuedCode = code;
    _issuedAt = clock.now();
    return code;
  }

  /// Strips the typing separators — hygiene, not a second code shape.
  String normalize(String code) => code.replaceAll(RegExp(r'[\s\-]'), '');

  /// Counts this submission and says whether the attempt cap is now exceeded.
  bool countAttempt() {
    _attempts += 1;
    return _attempts > policy.maxAttempts;
  }

  /// Why this typed code cannot be accepted right now, or `null` when it can.
  ///
  /// The order of checks is the service's documented validation order —
  /// shape, expiry, never-issued, reuse, mismatch — and it is frozen by
  /// `demo_registration_service_test.dart`.
  DemoCodeRejection? rejectionFor(String typed) {
    if (!policy.matchesCodeShape(typed)) {
      return DemoCodeRejection.badShape;
    }
    final DateTime? issuedAt = _issuedAt;
    if (issuedAt != null && clock.isPast(issuedAt.add(policy.codeTtl))) {
      discard(); // the 5-minute DEMO TTL has run out
      return DemoCodeRejection.expired;
    }
    if (_issuedCode == null) return DemoCodeRejection.neverIssued;
    if (_redeemedCodes.contains(typed)) return DemoCodeRejection.alreadyRedeemed;
    if (typed != _issuedCode) return DemoCodeRejection.mismatch;
    return null;
  }

  /// Consumes the accepted code: redeemed set only, plaintext dropped, the
  /// attempt counter starts fresh for the next registration.
  void accept(String typed) {
    _redeemedCodes.add(typed);
    discard();
    _attempts = 0;
  }

  void discard() {
    _issuedCode = null;
    _issuedAt = null;
  }

  void dispose() {
    _redeemedCodes.clear();
    discard();
  }
}

/// The typed "why not" of [DemoCodeLane.rejectionFor]. The service maps each
/// one onto its `RegistrationRejectReason`; adding a case here is a contract
/// change and belongs with the transition table.
enum DemoCodeRejection { badShape, expired, neverIssued, alreadyRedeemed, mismatch }
