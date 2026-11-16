package com.haven.child.usage

import com.haven.child.UsageContract
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SettingsNavigatorTest {

    private val context = FakeTestContext()
    private val fakeLauncher = FakeIntentLauncher()

    @Test
    fun testSuccessfulPackageSettingsLaunch() {
        fakeLauncher.packageLaunchSuccess = true
        val navigator = SettingsNavigator(launcher = fakeLauncher, apiLevel = 34)

        val result = navigator.openSettings(context)

        assertEquals(34, result[UsageContract.KEY_API_LEVEL])
        assertTrue(result[UsageContract.KEY_INTENT_LAUNCHED] as Boolean)
        assertTrue(result[UsageContract.KEY_OPENED_PACKAGE_SETTINGS] as Boolean)
        assertEquals(1, fakeLauncher.launchedIntents.size)
    }

    @Test
    fun testFallbackToGenericWhenPackageFails() {
        fakeLauncher.packageLaunchSuccess = false
        fakeLauncher.genericLaunchSuccess = true
        val navigator = SettingsNavigator(launcher = fakeLauncher, apiLevel = 34)

        val result = navigator.openSettings(context)

        assertEquals(34, result[UsageContract.KEY_API_LEVEL])
        assertTrue(result[UsageContract.KEY_INTENT_LAUNCHED] as Boolean)
        assertFalse(result[UsageContract.KEY_OPENED_PACKAGE_SETTINGS] as Boolean)
        assertEquals(2, fakeLauncher.launchedIntents.size)
    }

    @Test
    fun testFailureWhenBothPackageAndGenericFail() {
        fakeLauncher.packageLaunchSuccess = false
        fakeLauncher.genericLaunchSuccess = false
        val navigator = SettingsNavigator(launcher = fakeLauncher, apiLevel = 34)

        val result = navigator.openSettings(context)

        assertEquals(34, result[UsageContract.KEY_API_LEVEL])
        assertFalse(result[UsageContract.KEY_INTENT_LAUNCHED] as Boolean)
        assertFalse(result[UsageContract.KEY_OPENED_PACKAGE_SETTINGS] as Boolean)
        assertEquals(2, fakeLauncher.launchedIntents.size)
    }

    @Test
    fun testNullContextReturnsFailure() {
        val navigator = SettingsNavigator(launcher = fakeLauncher, apiLevel = 34)

        val result = navigator.openSettings(null)

        assertEquals(34, result[UsageContract.KEY_API_LEVEL])
        assertFalse(result[UsageContract.KEY_INTENT_LAUNCHED] as Boolean)
        assertFalse(result[UsageContract.KEY_OPENED_PACKAGE_SETTINGS] as Boolean)
        assertEquals(0, fakeLauncher.launchedIntents.size)
    }
}
