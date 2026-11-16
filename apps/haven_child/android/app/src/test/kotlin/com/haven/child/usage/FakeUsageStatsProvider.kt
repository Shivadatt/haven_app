package com.haven.child.usage

import android.content.Context

/**
 * Hand-written fake for UsageStatsProvider testing without Android system services.
 */
class FakeUsageStatsProvider(
    var simulatedStats: List<AppUsageInfo> = emptyList(),
    var exceptionToThrow: Exception? = null,
) : UsageStatsProvider {

    var lastStartTime: Long? = null
    var lastEndTime: Long? = null

    override fun queryUsage(
        context: Context,
        startTimeMillis: Long,
        endTimeMillis: Long,
    ): List<AppUsageInfo> {
        exceptionToThrow?.let { throw it }
        lastStartTime = startTimeMillis
        lastEndTime = endTimeMillis
        return simulatedStats
    }
}
