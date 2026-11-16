package com.haven.child.usage

import com.haven.child.UsageContract
import kotlin.math.max

/**
 * Aggregates raw package usage records into the contract response envelope.
 */
class UsageAggregator {

    companion object {
        // Threshold within which activity is considered recent (15 minutes)
        private const val RECENT_THRESHOLD_MILLIS = 15L * 60L * 1000L
    }

    fun aggregate(
        startTimeMillis: Long,
        endTimeMillis: Long,
        rawUsages: List<AppUsageInfo>,
        apiLevel: Int,
    ): Map<String, Any> {
        // Consolidate duplicate records for the same package
        val mergedMap = LinkedHashMap<String, AppUsageInfo>()
        for (raw in rawUsages) {
            val existing = mergedMap[raw.packageName]
            if (existing == null) {
                mergedMap[raw.packageName] = raw
            } else {
                mergedMap[raw.packageName] = AppUsageInfo(
                    packageName = raw.packageName,
                    totalForegroundMillis = existing.totalForegroundMillis + raw.totalForegroundMillis,
                    lastTimeUsedMillis = max(existing.lastTimeUsedMillis, raw.lastTimeUsedMillis),
                    isSystemApp = existing.isSystemApp || raw.isSystemApp,
                )
            }
        }

        // Filter out zero foreground usage and sort descending by foreground duration
        val nonZeroApps = mergedMap.values
            .filter { it.totalForegroundMillis > 0L }
            .sortedByDescending { it.totalForegroundMillis }

        val totalDuration = nonZeroApps.sumOf { it.totalForegroundMillis }

        // Determine data freshness
        val freshness = when {
            nonZeroApps.isEmpty() -> UsageContract.FRESHNESS_EMPTY
            else -> {
                val mostRecent = nonZeroApps.maxOf { it.lastTimeUsedMillis }
                if (mostRecent >= (endTimeMillis - RECENT_THRESHOLD_MILLIS)) {
                    UsageContract.FRESHNESS_RECENT
                } else {
                    UsageContract.FRESHNESS_DELAYED
                }
            }
        }

        val appsPayload = nonZeroApps.map { app ->
            mapOf(
                UsageContract.KEY_PACKAGE_NAME to app.packageName,
                UsageContract.KEY_TOTAL_FOREGROUND_MILLIS to app.totalForegroundMillis,
                UsageContract.KEY_LAST_TIME_USED_MILLIS to app.lastTimeUsedMillis,
                UsageContract.KEY_IS_SYSTEM_APP to app.isSystemApp,
            )
        }

        return mapOf(
            UsageContract.KEY_API_LEVEL to apiLevel,
            UsageContract.KEY_START_TIME_MILLIS to startTimeMillis,
            UsageContract.KEY_END_TIME_MILLIS to endTimeMillis,
            UsageContract.KEY_TOTAL_FOREGROUND_MILLIS to totalDuration,
            UsageContract.KEY_DATA_FRESHNESS to freshness,
            UsageContract.KEY_APPS to appsPayload,
        )
    }
}
