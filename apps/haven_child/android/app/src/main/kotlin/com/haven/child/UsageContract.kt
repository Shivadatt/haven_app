package com.haven.child

/**
 * Authoritative native contract for the child usage stats MethodChannel (D-4).
 *
 * Kotlin is the authoritative source of truth. The Dart mirror in
 * `usage_channel_contract.dart` must agree on every channel name, method name,
 * envelope key, error code, section name, and status token. Cross-language
 * agreement tests parse this file directly from disk to enforce parity and
 * prevent silent drift.
 */
object UsageContract {
    /** The MethodChannel name for child usage statistics. */
    const val CHANNEL_NAME = "haven.dev/child_usage_stats"

    /** Method to check the current Usage Access permission status. */
    const val METHOD_GET_PERMISSION_STATUS = "usage.getPermissionStatus"

    /** Method to launch the Android Usage Access Settings screen. */
    const val METHOD_OPEN_SETTINGS = "usage.openSettings"

    /** Method to query daily screen time and per-app foreground usage. */
    const val METHOD_QUERY_DAILY_USAGE = "usage.queryDailyUsage"

    // Request & response envelope keys
    const val KEY_API_LEVEL = "apiLevel"
    const val KEY_STATUS = "status"
    const val KEY_INTENT_LAUNCHED = "intentLaunched"
    const val KEY_OPENED_PACKAGE_SETTINGS = "openedPackageSettings"
    const val KEY_START_TIME_MILLIS = "startTimeMillis"
    const val KEY_END_TIME_MILLIS = "endTimeMillis"
    const val KEY_TOTAL_FOREGROUND_MILLIS = "totalForegroundMillis"
    const val KEY_DATA_FRESHNESS = "dataFreshness"
    const val KEY_APPS = "apps"
    const val KEY_PACKAGE_NAME = "packageName"
    const val KEY_LAST_TIME_USED_MILLIS = "lastTimeUsedMillis"
    const val KEY_IS_SYSTEM_APP = "isSystemApp"

    // Error codes returned by MethodChannel
    const val ERROR_UNKNOWN_METHOD = "unknown-method"
    const val ERROR_NO_CONTEXT = "no-context"
    const val ERROR_PERMISSION_DENIED = "permission-denied"
    const val ERROR_INVALID_RANGE = "invalid-range"
    const val ERROR_SECTION_FAILED = "section-failed"

    // Permission status values
    const val PERMISSION_GRANTED = "granted"
    const val PERMISSION_DENIED = "denied"
    const val PERMISSION_UNSUPPORTED = "unsupported"

    // Data freshness values
    const val FRESHNESS_RECENT = "recent"
    const val FRESHNESS_DELAYED = "delayed"
    const val FRESHNESS_EMPTY = "empty"

    // Usage response section names
    const val SECTION_APPS = "apps"
    const val SECTION_DAILY_SUMMARY = "dailySummary"
    const val SECTION_PERMISSION = "permission"
}
