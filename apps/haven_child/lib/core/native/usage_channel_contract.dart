/// The Dart mirror of the child device's usage stats native channel contract.
///
/// Decision D-4, option B: Kotlin under `apps/haven_child/android/` is
/// authoritative, this file is the copy the Dart side codes against, and the
/// two are checked against each other by a test that reads the Kotlin source off
/// disk (`test/native/usage_cross_language_agreement_test.dart`). A rename on
/// either side is therefore a failing test, not a channel that silently drifts.
library;

/// Relative path to the authoritative Kotlin contract from the repo root.
abstract final class UsageKotlinSource {
  static const String contractPath =
      'apps/haven_child/android/app/src/main/kotlin/com/haven/child/UsageContract.kt';
}

/// Channel identifier for child usage statistics MethodChannel.
abstract final class UsageChannelName {
  static const String channelName = 'haven.dev/child_usage_stats';
  static const String kotlinConstant = 'CHANNEL_NAME';
}

/// The three methods answered by the native usage lane.
abstract final class UsageMethod {
  static const String getPermissionStatus = 'usage.getPermissionStatus';
  static const String openSettings = 'usage.openSettings';
  static const String queryDailyUsage = 'usage.queryDailyUsage';

  static const List<String> all = <String>[
    getPermissionStatus,
    openSettings,
    queryDailyUsage,
  ];

  static const Map<String, String> kotlinConstants = <String, String>{
    getPermissionStatus: 'METHOD_GET_PERMISSION_STATUS',
    openSettings: 'METHOD_OPEN_SETTINGS',
    queryDailyUsage: 'METHOD_QUERY_DAILY_USAGE',
  };
}

/// Request and response envelope keys for MethodChannel payloads.
abstract final class UsageEnvelopeKey {
  static const String apiLevel = 'apiLevel';
  static const String status = 'status';
  static const String intentLaunched = 'intentLaunched';
  static const String openedPackageSettings = 'openedPackageSettings';
  static const String startTimeMillis = 'startTimeMillis';
  static const String endTimeMillis = 'endTimeMillis';
  static const String totalForegroundMillis = 'totalForegroundMillis';
  static const String dataFreshness = 'dataFreshness';
  static const String apps = 'apps';
  static const String packageName = 'packageName';
  static const String lastTimeUsedMillis = 'lastTimeUsedMillis';
  static const String isSystemApp = 'isSystemApp';

  static const List<String> all = <String>[
    apiLevel,
    status,
    intentLaunched,
    openedPackageSettings,
    startTimeMillis,
    endTimeMillis,
    totalForegroundMillis,
    dataFreshness,
    apps,
    packageName,
    lastTimeUsedMillis,
    isSystemApp,
  ];

  static const Map<String, String> kotlinConstants = <String, String>{
    apiLevel: 'KEY_API_LEVEL',
    status: 'KEY_STATUS',
    intentLaunched: 'KEY_INTENT_LAUNCHED',
    openedPackageSettings: 'KEY_OPENED_PACKAGE_SETTINGS',
    startTimeMillis: 'KEY_START_TIME_MILLIS',
    endTimeMillis: 'KEY_END_TIME_MILLIS',
    totalForegroundMillis: 'KEY_TOTAL_FOREGROUND_MILLIS',
    dataFreshness: 'KEY_DATA_FRESHNESS',
    apps: 'KEY_APPS',
    packageName: 'KEY_PACKAGE_NAME',
    lastTimeUsedMillis: 'KEY_LAST_TIME_USED_MILLIS',
    isSystemApp: 'KEY_IS_SYSTEM_APP',
  };
}

/// Error codes returned across the MethodChannel boundary.
abstract final class UsageErrorCode {
  static const String unknownMethod = 'unknown-method';
  static const String noContext = 'no-context';
  static const String permissionDenied = 'permission-denied';
  static const String invalidRange = 'invalid-range';
  static const String sectionFailed = 'section-failed';

  static const List<String> all = <String>[
    unknownMethod,
    noContext,
    permissionDenied,
    invalidRange,
    sectionFailed,
  ];

  static const Map<String, String> kotlinConstants = <String, String>{
    unknownMethod: 'ERROR_UNKNOWN_METHOD',
    noContext: 'ERROR_NO_CONTEXT',
    permissionDenied: 'ERROR_PERMISSION_DENIED',
    invalidRange: 'ERROR_INVALID_RANGE',
    sectionFailed: 'ERROR_SECTION_FAILED',
  };
}

/// Standardized permission status values.
abstract final class UsagePermissionStatusValue {
  static const String granted = 'granted';
  static const String denied = 'denied';
  static const String unsupported = 'unsupported';

  static const List<String> all = <String>[
    granted,
    denied,
    unsupported,
  ];

  static const Map<String, String> kotlinConstants = <String, String>{
    granted: 'PERMISSION_GRANTED',
    denied: 'PERMISSION_DENIED',
    unsupported: 'PERMISSION_UNSUPPORTED',
  };
}

/// Standardized data freshness indicator tokens.
abstract final class UsageDataFreshnessValue {
  static const String recent = 'recent';
  static const String delayed = 'delayed';
  static const String empty = 'empty';

  static const List<String> all = <String>[
    recent,
    delayed,
    empty,
  ];

  static const Map<String, String> kotlinConstants = <String, String>{
    recent: 'FRESHNESS_RECENT',
    delayed: 'FRESHNESS_DELAYED',
    empty: 'FRESHNESS_EMPTY',
  };
}

/// Usage response section names.
abstract final class UsageSectionName {
  static const String apps = 'apps';
  static const String dailySummary = 'dailySummary';
  static const String permission = 'permission';

  static const List<String> all = <String>[
    apps,
    dailySummary,
    permission,
  ];

  static const Map<String, String> kotlinConstants = <String, String>{
    apps: 'SECTION_APPS',
    dailySummary: 'SECTION_DAILY_SUMMARY',
    permission: 'SECTION_PERMISSION',
  };
}
