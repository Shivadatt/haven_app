/// Pairing-code checking, without inventing the pairing-code specification.
///
/// **BLOCKED — SPECIFICATION REQUIRED: the length and character set of a
/// human-typed pairing code.** What the evidence holds is only that the
/// *stored* artefact is a hash:
///  * `device_pairing_tokens.code_hash` / `pairing_attempts.code_hash` are
///    `text NOT NULL` with CHECK `~ '^[0-9a-f]{64}$'`
///    (docs/stage2/migrations/A3-staging-load-v1.sql:448, :476);
///  * `_shared/validation.ts` is captured as "Regexes, typed readers, CSPRNG
///    pairing code / Child ID, sha256Hex, identifierHash (HMAC with
///    PAIRING_HASH_PEPPER…)" — a 419-line module whose **source was never
///    served** in the capture, only its summary and digest
///    (docs/stage1/evidence/edge-functions/capture-20261030.json:170).
///
/// So the generator's alphabet and length are unknown, and a 64-hex shape would
/// be wrong (that is the hash, not the code). [PairingCodeFormat] therefore has
/// no default: a caller that has a real spec passes it in, and a caller that has
/// none gets [blocked] rather than a guess.
library;

import 'blocked.dart';
import 'failures.dart';
import 'result.dart';

/// Named so call sites and the traceability file point at one string.
const String pairingCodeRuleGap =
    'pairing code length and character set (_shared/validation.ts source not captured)';

/// Character sets offered when a spec exists. Deliberately narrow: a caller
/// must state which alphabet it was told to use.
enum PairingCodeCharset {
  digits('0123456789'),
  upperAlphanumeric('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
  upperAlphanumericNoAmbiguous('23456789ABCDEFGHJKLMNPQRSTUVWXYZ');

  const PairingCodeCharset(this.characters);
  final String characters;
}

/// A pairing-code rule supplied by whoever owns the specification.
final class PairingCodeFormat {
  const PairingCodeFormat({
    required this.length,
    required this.charset,
    this.separator = '-',
    this.allowUnseparatedInput = true,
  }) : assert(length > 0);

  /// Characters a caller must type, ignoring [separator].
  final int length;
  final PairingCodeCharset charset;

  /// Optional grouping character accepted in typed input and ignored.
  final String separator;
  final bool allowUnseparatedInput;

  String patternDescription() =>
      '$length characters from ${charset.name}, separators ("$separator" and spaces) ignored';
}

/// Strips the accepted separators and upper-cases, so "ab-12" and "AB 12" are
/// compared as the same string.
///
/// This is *display and typing hygiene only*. It is not the server's
/// normalisation: the captured code path hashes a "normalised" value
/// (`codeHash = sha256Hex(normalized)`, capture line 565) and the normalisation
/// itself is inside the uncaptured module. The client never hashes and never
/// transmits a code it has not been shown.
String normalizePairingCodeInput(String raw) {
  final folded = raw.toUpperCase();
  final buffer = StringBuffer();
  for (final rune in folded.runes) {
    final char = String.fromCharCode(rune);
    if (char == ' ' || char == '-' || char == '—' || char == '_') continue;
    buffer.write(char);
  }
  return buffer.toString();
}

/// Validates against an explicitly supplied [format].
///
/// With no format, returns [blocked]: the honest answer is that Haven cannot
/// tell a user their code is the right shape yet.
Result<String> validatePairingCode(
  String? raw, {
  PairingCodeFormat? format,
  String label = 'pairing code',
}) {
  if (format == null) {
    return blocked<String>(
      pairingCodeRuleGap,
      requirement:
          "Haven can't confirm the shape of a $label yet, because its length and "
          'characters are not written down anywhere we can rely on.',
    );
  }
  final typed = (raw ?? '').trim();
  if (typed.isEmpty) {
    return Err<String>(
      ValidationFailure(
        'Enter the $label shown on the other device.',
        field: 'pairing_code',
      ),
    );
  }
  final normalized = normalizePairingCodeInput(typed);
  if (!format.allowUnseparatedInput &&
      typed.contains(format.separator) == false &&
      normalized.length != typed.length) {
    return Err<String>(
      ValidationFailure(
        'Enter the $label exactly as it is shown, including its separators.',
        field: 'pairing_code',
      ),
    );
  }
  if (normalized.length != format.length) {
    return Err<String>(
      ValidationFailure(
        'A $label is ${format.length} characters long. Yours has ${normalized.length}.',
        field: 'pairing_code',
      ),
    );
  }
  for (final char in normalized.split('')) {
    if (!format.charset.characters.contains(char)) {
      return Err<String>(
        ValidationFailure(
          'A $label uses only the characters in ${format.charset.name}.',
          field: 'pairing_code',
        ),
      );
    }
  }
  return Ok<String>(normalized);
}
