package com.haven.child

import android.util.Log
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Step 4 Infrastructure Verification Test.
 *
 * Verifies that the local JVM JUnit 4 test runner executes properly,
 * assertions function as expected, and testOptions are active without
 * requiring Robolectric, Android framework mocks, or an emulator.
 */
class NativeTestLaneSanityTest {

    @Test
    fun testJvmUnitTestLaneIsOperational() {
        val expected = "haven_child_jvm_test_lane"
        val actual = "haven_child_jvm_test_lane"
        assertEquals("JVM unit test string assertion should match", expected, actual)
    }

    @Test
    fun testAssertionFrameworkIsActive() {
        val timestamp = System.currentTimeMillis()
        assertTrue("System clock should be positive", timestamp > 0L)
        assertNotNull("System property java.version should not be null", System.getProperty("java.version"))
    }

    @Test
    fun testReturnDefaultValuesAllowsAndroidFrameworkCallsWithoutMocking() {
        // With isReturnDefaultValues = true, unmocked Android framework methods
        // return default values (0 for Int) instead of throwing
        // "RuntimeException: Method ... not mocked".
        val logResult = Log.d("SanityTest", "Verifying default value return")
        assertEquals(0, logResult)
    }
}

