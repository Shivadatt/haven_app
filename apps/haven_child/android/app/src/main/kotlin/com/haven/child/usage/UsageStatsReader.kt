package com.haven.child.usage

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Build

/**
 * Data model for package foreground usage.
 */
data class AppUsageInfo(
    val packageName: String,
    val totalForegroundMillis: Long,
    val lastTimeUsedMillis: Long,
    val isSystemApp: Boolean,
)

/**
 * Interface abstracting UsageStatsManager querying for testability.
 */
interface UsageStatsProvider {
    fun queryUsage(context: Context, startTimeMillis: Long, endTimeMillis: Long): List<AppUsageInfo>
}

/**
 * Production implementation querying Android's UsageStatsManager.
 */
class SystemUsageStatsProvider : UsageStatsProvider {
    override fun queryUsage(
        context: Context,
        startTimeMillis: Long,
        endTimeMillis: Long,
    ): List<AppUsageInfo> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return emptyList()
        }
        val usageManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return emptyList()

        val statsList: List<UsageStats>? = usageManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTimeMillis,
            endTimeMillis,
        )

        if (statsList.isNullOrEmpty()) {
            return emptyList()
        }

        val pm = context.packageManager
        val results = ArrayList<AppUsageInfo>(statsList.size)

        for (stats in statsList) {
            val foreground = stats.totalTimeInForeground
            val lastUsed = stats.lastTimeUsed
            var isSystem = false
            try {
                val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getApplicationInfo(stats.packageName, android.content.pm.PackageManager.ApplicationInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    pm.getApplicationInfo(stats.packageName, 0)
                }
                isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            } catch (_: Exception) {
                // If package uninstalled or query fails, leave isSystem as false
            }

            results.add(
                AppUsageInfo(
                    packageName = stats.packageName,
                    totalForegroundMillis = foreground,
                    lastTimeUsedMillis = lastUsed,
                    isSystemApp = isSystem,
                )
            )
        }
        return results
    }
}

/**
 * Queries Android UsageStatsManager with timestamp validation.
 */
class UsageStatsReader(
    private val provider: UsageStatsProvider = SystemUsageStatsProvider(),
) {
    fun queryUsage(
        context: Context,
        startTimeMillis: Long,
        endTimeMillis: Long,
    ): List<AppUsageInfo> {
        if (startTimeMillis < 0L || endTimeMillis < 0L) {
            throw IllegalArgumentException("Timestamps must be non-negative")
        }
        if (startTimeMillis >= endTimeMillis) {
            throw IllegalArgumentException("startTimeMillis must be strictly less than endTimeMillis")
        }
        return provider.queryUsage(context, startTimeMillis, endTimeMillis)
    }
}
