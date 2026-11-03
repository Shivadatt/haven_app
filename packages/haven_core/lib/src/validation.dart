/// Input validation the parent can actually act on.
///
/// Rules are grounded where evidence exists; where it does not, the check is
/// permissive and the caller is told the rule is unspecified rather than the
/// input being rejected on an invented basis.
library;

/// Postgres `citext`/`text` email column: shape only, no provider guesses.
String? validateEmail(String? raw) {
  final v = raw?.trim();
  if (v == null || v.isEmpty) return 'Enter an email address.';
  if (v.length > 254) return 'That email address is too long.';
  final at = v.indexOf('@');
  if (at <= 0 || at == v.length - 1 || !v.substring(at + 1).contains('.')) {
    return 'Enter a complete email address, like name@example.com.';
  }
  return null;
}

/// `profiles.display_name` is capped by `profiles_display_name_check`
/// (`char_length` 1..60, `docs/stage2/migrations/A3-staging-load-v1.sql:478`),
/// so the app refuses a longer name instead of letting the write fail. The
/// two-character floor is a product choice, stricter than the constraint.
String? validateDisplayName(String? raw) {
  final v = raw?.trim();
  if (v == null || v.isEmpty) return 'Enter a name.';
  if (v.length < 2) return 'Use at least 2 characters.';
  if (v.length > 60) return 'Use 60 characters or fewer.';
  return null;
}

String? validateRequired(String? raw, {required String emptyMessage}) =>
    (raw == null || raw.trim().isEmpty) ? emptyMessage : null;

String? validatePassword(String? raw) {
  final v = raw;
  if (v == null || v.isEmpty) return 'Enter a password.';
  if (v.length < 8) return 'Use at least 8 characters.';
  if (v.length > 72) return 'Use 72 characters or fewer.';
  return null;
}

/// `safe_zones.radius_m` is a non-null `float8`; only positivity is a fact.
String? validateRadiusM(String? raw) {
  final v = double.tryParse((raw ?? '').trim());
  if (v == null) return 'Enter the radius in metres.';
  if (v <= 0) return 'The radius must be greater than 0 metres.';
  if (v > 100000)
    return 'That radius is too large — check the units are metres.';
  return null;
}

String? validateLatitude(String? raw) =>
    validateCoordinate(raw, max: 90, label: 'latitude');

String? validateLongitude(String? raw) =>
    validateCoordinate(raw, max: 180, label: 'longitude');

String? validateCoordinate(
  String? raw, {
  required double max,
  required String label,
}) {
  final v = double.tryParse((raw ?? '').trim());
  if (v == null) return 'Enter a number for the $label.';
  if (v < -max || v > max) return 'The $label must be between -$max and $max.';
  return null;
}

/// Pairing codes are stored hashed (`code_hash`); the displayed length and
/// alphabet are NOT captured anywhere in the evidence, so this only rejects
/// obviously unusable input and leaves the real rule to the backend.
String? validatePairingCode(String? raw) {
  final v = raw?.trim();
  if (v == null || v.isEmpty)
    return 'Enter the code shown on the other device.';
  if (v.length < 4) return 'That code looks too short.';
  if (v.length > 64) return 'That code looks too long.';
  return null;
}

bool isUuid(String? raw) {
  final v = raw;
  if (v == null) return false;
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(v);
}
