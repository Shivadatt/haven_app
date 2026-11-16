package com.haven.child.usage

import com.haven.child.UsageContract
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class UsageAggregatorTest {

    private val aggregator = UsageAggregator()
    private val endTime = 1731512400000L
    private val startTime = 1731456000000L

    @Test
    fun testEmptyRawUsagesReturnsEmptyFreshnessAndZeroTotal() {
        val result = aggregator.aggregate(startTime, endTime, emptyList(), 34)

        assertEquals(34, result[UsageContract.KEY_API_LEVEL])
        assertEquals(startTime, result[UsageContract.KEY_START_TIME_MILLIS])
        assertEquals(endTime, result[UsageContract.KEY_END_TIME_MILLIS])
        assertEquals(0L, result[UsageContract.KEY_TOTAL_FOREGROUND_MILLIS])
        assertEquals(UsageContract.FRESHNESS_EMPTY, result[UsageContract.KEY_DATA_FRESHNESS])

        @Suppress("UNCHECKED_CAST")
        val apps = result[UsageContract.KEY_APPS] as List<Map<String, Any>>
        assertTrue(apps.isEmpty())
    }

    @Test
    fun testDuplicatePackageRecordsAreMergedAndSummed() {
        val raw = listOf(
            AppUsageInfo("com.example.game", 1000L, 500L, false),
            AppUsageInfo("com.example.game", 2000L, 800L, false),
            AppUsageInfo("com.android.chrome", 5000L, 900L, true),
        )

        val result = aggregator.aggregate(startTime, endTime, raw, 34)

        assertEquals(8000L, result[UsageContract.KEY_TOTAL_FOREGROUND_MILLIS])

        @Suppress("UNCHECKED_CAST")
        val apps = result[UsageContract.KEY_APPS] as List<Map<String, Any>>
        assertEquals(2, apps.size)

        // Chrome has 5000ms, should be first
        assertEquals("com.android.chrome", apps[0][UsageContract.KEY_PACKAGE_NAME])
        assertEquals(5000L, apps[0][UsageContract.KEY_TOTAL_FOREGROUND_MILLIS])
        assertEquals(true, apps[0][UsageContract.KEY_IS_SYSTEM_APP])

        // Game has merged 3000ms and max lastTimeUsed of 800L
        assertEquals("com.example.game", apps[1][UsageContract.KEY_PACKAGE_NAME])
        assertEquals(3000L, apps[1][UsageContract.KEY_TOTAL_FOREGROUND_MILLIS])
        assertEquals(800L, apps[1][UsageContract.KEY_LAST_TIME_USED_MILLIS])
    }

    @Test
    fun testZeroForegroundRecordsAreFilteredOut() {
        val raw = listOf(
            AppUsageInfo("com.example.zero", 0L, 100L, false),
            AppUsageInfo("com.example.used", 1500L, 200L, false),
        )

        val result = aggregator.aggregate(startTime, endTime, raw, 34)

        assertEquals(1500L, result[UsageContract.KEY_TOTAL_FOREGROUND_MILLIS])

        @Suppress("UNCHECKED_CAST")
        val apps = result[UsageContract.KEY_APPS] as List<Map<String, Any>>
        assertEquals(1, apps.size)
        assertEquals("com.example.used", apps[0][UsageContract.KEY_PACKAGE_NAME])
    }

    @Test
    fun testFreshnessRecentWhenLastUsedWithin15Minutes() {
        // 5 minutes before endTime
        val recentTime = endTime - (5L * 60L * 1000L)
        val raw = listOf(AppUsageInfo("com.example.app", 3000L, recentTime, false))

        val result = aggregator.aggregate(startTime, endTime, raw, 34)

        assertEquals(UsageContract.FRESHNESS_RECENT, result[UsageContract.KEY_DATA_FRESHNESS])
    }

    @Test
    fun testFreshnessDelayedWhenLastUsedOlderThan15Minutes() {
        // 20 minutes before endTime
        val oldTime = endTime - (20L * 60L * 1000L)
        val raw = listOf(AppUsageInfo("com.example.app", 3000L, oldTime, false))

        val result = aggregator.aggregate(startTime, endTime, raw, 34)

        assertEquals(UsageContract.FRESHNESS_DELAYED, result[UsageContract.KEY_DATA_FRESHNESS])
    }
}
