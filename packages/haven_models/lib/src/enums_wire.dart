/// Shared plumbing for the wire enums in `enums_identity.dart` and
/// `enums_device.dart`.
///
/// Those enums mirror CHECK constraints in
/// `docs/stage2/migrations/A3-staging-load-v1.sql` (section 20). A value outside
/// the constraint cannot be stored, so [matchWire] returns `null` rather than
/// guessing — a screen then shows the raw text instead of a wrong label.
library;

/// A database token plus the words a parent should see instead of it.
abstract interface class WireLabel {
  String get wire;
  String get label;
}

/// Exact match on the stored token; never a fuzzy or case-insensitive guess.
T? matchWire<T extends WireLabel>(List<T> values, String? wire) {
  if (wire == null) return null;
  for (final value in values) {
    if (value.wire == wire) return value;
  }
  return null;
}

/// Renders a wire value we have no enum for — either a column with no CHECK
/// constraint (e.g. `location_events.source`) or a token added since capture.
String labelOrRaw(WireLabel? known, String? raw) =>
    known?.label ?? (raw == null || raw.isEmpty ? 'unknown' : raw);
