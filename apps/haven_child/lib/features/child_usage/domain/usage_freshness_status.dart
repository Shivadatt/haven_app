import '../../../core/native/usage_envelope_models.dart';

/// Domain representation of Usage Access data freshness.
///
/// Reflects Android `UsageStatsManager` batching and reporting cadence:
/// - [recent]: Usage stats were updated recently and accurately.
/// - [delayed]: Stats are older due to Android OS batching or throttling.
/// - [empty]: No usage statistics were returned for the queried interval.
enum UsageFreshnessStatus {
  recent,
  delayed,
  empty;

  /// Wire token constants mirroring the authoritative contract.
  static const String wireRecent = 'recent';
  static const String wireDelayed = 'delayed';
  static const String wireEmpty = 'empty';

  /// Safe conversion from the native envelope's [UsageDataFreshness].
  static UsageFreshnessStatus? fromDataFreshness(
    UsageDataFreshness? freshness,
  ) =>
      switch (freshness) {
        UsageDataFreshness.recent => UsageFreshnessStatus.recent,
        UsageDataFreshness.delayed => UsageFreshnessStatus.delayed,
        UsageDataFreshness.empty => UsageFreshnessStatus.empty,
        null => null,
      };

  /// Safe conversion from raw wire token string.
  /// Returns null for unrecognised or malformed values.
  static UsageFreshnessStatus? parse(String? raw) => switch (raw) {
        wireRecent => UsageFreshnessStatus.recent,
        wireDelayed => UsageFreshnessStatus.delayed,
        wireEmpty => UsageFreshnessStatus.empty,
        _ => null,
      };

  /// Converts back to [UsageDataFreshness].
  UsageDataFreshness toDataFreshness() => switch (this) {
        UsageFreshnessStatus.recent => UsageDataFreshness.recent,
        UsageFreshnessStatus.delayed => UsageDataFreshness.delayed,
        UsageFreshnessStatus.empty => UsageDataFreshness.empty,
      };

  /// The wire string token representing this freshness status.
  String get wireToken => switch (this) {
        UsageFreshnessStatus.recent => wireRecent,
        UsageFreshnessStatus.delayed => wireDelayed,
        UsageFreshnessStatus.empty => wireEmpty,
      };
}
