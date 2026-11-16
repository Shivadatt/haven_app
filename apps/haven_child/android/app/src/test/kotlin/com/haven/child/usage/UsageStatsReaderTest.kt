package com.haven.child.usage

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

class UsageStatsReaderTest {

    private val context = FakeTestContext()
    private val fakeProvider = FakeUsageStatsProvider()
    private val reader = UsageStatsReader(provider = fakeProvider)

    @Test
    fun testValidRangeDelegatesToProvider() {
        val expected = listOf(
            AppUsageInfo("com.example.app1", 3600000L, 1000000L, false),
            AppUsageInfo("com.android.settings", 120000L, 950000L, true),
        )
        fakeProvider.simulatedStats = expected

        val actual = reader.queryUsage(context, 1000L, 5000L)

        assertEquals(expected, actual)
        assertEquals(1000L, fakeProvider.lastStartTime)
        assertEquals(5000L, fakeProvider.lastEndTime)
    }

    @Test
    fun testNegativeStartTimeThrowsIllegalArgumentException() {
        try {
            reader.queryUsage(context, -1L, 1000L)
            fail("Expected IllegalArgumentException for negative start time")
        } catch (e: IllegalArgumentException) {
            assertTrue(e.message?.contains("non-negative") == true)
        }
    }

    @Test
    fun testNegativeEndTimeThrowsIllegalArgumentException() {
        try {
            reader.queryUsage(context, 1000L, -500L)
            fail("Expected IllegalArgumentException for negative end time")
        } catch (e: IllegalArgumentException) {
            assertTrue(e.message?.contains("non-negative") == true)
        }
    }

    @Test
    fun testStartEqualEndTimeThrowsIllegalArgumentException() {
        try {
            reader.queryUsage(context, 1000L, 1000L)
            fail("Expected IllegalArgumentException when start == end")
        } catch (e: IllegalArgumentException) {
            assertTrue(e.message?.contains("strictly less than") == true)
        }
    }

    @Test
    fun testStartGreaterThanEndTimeThrowsIllegalArgumentException() {
        try {
            reader.queryUsage(context, 2000L, 1000L)
            fail("Expected IllegalArgumentException when start > end")
        } catch (e: IllegalArgumentException) {
            assertTrue(e.message?.contains("strictly less than") == true)
        }
    }

    @Test
    fun testEmptyResultsReturnsEmptyList() {
        fakeProvider.simulatedStats = emptyList()

        val actual = reader.queryUsage(context, 100L, 200L)

        assertTrue(actual.isEmpty())
    }

    @Test
    fun testProviderExceptionIsPropagated() {
        fakeProvider.exceptionToThrow = SecurityException("Permission denied by system")

        try {
            reader.queryUsage(context, 100L, 200L)
            fail("Expected SecurityException to propagate")
        } catch (e: SecurityException) {
            assertEquals("Permission denied by system", e.message)
        }
    }
}
