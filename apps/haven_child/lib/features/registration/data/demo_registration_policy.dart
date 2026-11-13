/// The DEMO lane's numbers, and where each one came from.
///
/// Stage 2 may simulate, but it may not invent a rule silently. Every value
/// below carries the decision or file that produced it, and every value that
/// is NOT verified is filed separately as a Phase-4 target.
final class DemoRegistrationPolicy {
  const DemoRegistrationPolicy({
    this.codeDigits = 6,
    this.codeTtl = const Duration(minutes: 5),
    this.maxAttempts = 10,
  });

  /// DEMO code shape: 6 digits.
  ///
  /// This is the parent simulation's existing shape
  /// (`apps/haven_app/lib/features/device_pairing/data/pairing_simulation_service.dart:22-24`),
  /// kept as DEMO by decision D-3 option (ii). It is NOT a verified contract.
  final int codeDigits;

  /// DEMO expiry: 5 minutes, same citation and same decision.
  final Duration codeTtl;

  /// Attempts the DEMO tolerates before it refuses further tries.
  ///
  /// `10` is taken from `backend/supabase/functions/pairing/shared.ts:12`
  /// (`MAX_ATTEMPTS_PER_CODE`), which that file itself labels
  /// "RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION", and which
  /// describes a backend with 0 deployed functions. It is therefore recorded
  /// as the PROPOSED Phase-4 target, not a canonical rule: the parent's own
  /// simulation has no attempt cap at all.
  final int maxAttempts;

  // ---- The Phase-4 target, recorded, deliberately unused by this lane ----
  //
  // `shared.ts:10` is `CODE_TTL_MINUTES = 10`; the backend code shape is 8
  // characters from a 30-symbol alphabet
  // (`backend/supabase/functions/_shared/identifiers.ts:24-25`). `haven_core`
  // cannot even express that alphabet today — its narrowest set is 32 symbols
  // (`packages/haven_core/lib/src/pairing_code.dart:34`, differs by `L` and
  // `U`) — and per D-3 item 3 `PairingCodeFormat` / `validatePairingCode` stay
  // unexported and caller-less until a spec is verified from a DEPLOYED
  // backend. These are documentation-only constants; no code path reads them.
  static const int phase4TargetCodeLength = 8;
  static const int phase4TargetCharsetSymbols = 30;
  static const Duration phase4TargetCodeTtl = Duration(minutes: 10);
  static const int phase4TargetMaxAttempts = 10;

  /// The banner every DEMO screen must show. Kept here so a fabricated value
  /// cannot reach a screen without the word DEMO on it (risk R-9).
  static const String demoBanner = 'DEMO — simulated, local to this device';

  /// The footnote that stops "registered" being read as two phones meeting.
  static const String demoLandingNote =
      'DEMO: this device never contacted a parent phone, a QR code, a '
      'Bluetooth link, a shared file, or a server. Real pairing is BLOCKED '
      '(decision D-5).';

  /// The one deterministic DEMO code for [sequence], zero-padded to
  /// [codeDigits]. Deterministic on purpose: a contract test that cannot
  /// reproduce its own input is not a contract test.
  String demoCodeFor(int sequence) {
    final int base = 100000;
    return (base + sequence).toString().padLeft(codeDigits, '0');
  }

  /// True when [normalized] has the DEMO shape (digits only, exactly
  /// [codeDigits] long). Input must already have separators stripped.
  bool matchesCodeShape(String normalized) {
    if (normalized.length != codeDigits) return false;
    return RegExp(r'^\d+$').hasMatch(normalized);
  }
}
