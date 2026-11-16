package com.haven.child.usage

import android.app.AppOpsManager
import com.haven.child.UsageContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class FakeMethodResult : MethodChannel.Result {
    var successValue: Any? = null
    var errorCode: String? = null
    var errorMessage: String? = null
    var errorDetails: Any? = null
    var notImplementedCalled: Boolean = false

    override fun success(result: Any?) {
        successValue = result
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        this.errorCode = errorCode
        this.errorMessage = errorMessage
        this.errorDetails = errorDetails
    }

    override fun notImplemented() {
        notImplementedCalled = true
    }
}

class UsageBridgeHandlerTest {

    private val context = FakeTestContext()
    private val fakeChecker = FakeAppOpsChecker()
    private val fakeLauncher = FakeIntentLauncher()
    private val fakeProvider = FakeUsageStatsProvider()

    private val permissionReader = AppOpsPermissionReader(checker = fakeChecker, apiLevel = 34)
    private val settingsNavigator = SettingsNavigator(launcher = fakeLauncher, apiLevel = 34)
    private val usageStatsReader = UsageStatsReader(provider = fakeProvider)
    private val usageAggregator = UsageAggregator()

    private fun createHandler(hasContext: Boolean = true): UsageBridgeHandler {
        return UsageBridgeHandler(
            contextProvider = { if (hasContext) context else null },
            permissionReader = permissionReader,
            settingsNavigator = settingsNavigator,
            usageStatsReader = usageStatsReader,
            usageAggregator = usageAggregator,
            apiLevel = 34,
        )
    }

    @Test
    fun testUnknownMethodReturnsErrorUnknownMethod() {
        val handler = createHandler()
        val result = FakeMethodResult()

        handler.onMethodCall(MethodCall("invalid.method", null), result)

        assertEquals(UsageContract.ERROR_UNKNOWN_METHOD, result.errorCode)
    }

    @Test
    fun testGetPermissionStatusSuccess() {
        fakeChecker.simulatedMode = AppOpsManager.MODE_ALLOWED
        val handler = createHandler()
        val result = FakeMethodResult()

        handler.onMethodCall(MethodCall(UsageContract.METHOD_GET_PERMISSION_STATUS, null), result)

        @Suppress("UNCHECKED_CAST")
        val map = result.successValue as Map<String, Any>
        assertEquals(34, map[UsageContract.KEY_API_LEVEL])
        assertEquals(UsageContract.PERMISSION_GRANTED, map[UsageContract.KEY_STATUS])
    }

    @Test
    fun testGetPermissionStatusNoContextReturnsErrorNoContext() {
        val handler = createHandler(hasContext = false)
        val result = FakeMethodResult()

        handler.onMethodCall(MethodCall(UsageContract.METHOD_GET_PERMISSION_STATUS, null), result)

        assertEquals(UsageContract.ERROR_NO_CONTEXT, result.errorCode)
    }

    @Test
    fun testOpenSettingsSuccess() {
        fakeLauncher.packageLaunchSuccess = true
        val handler = createHandler()
        val result = FakeMethodResult()

        handler.onMethodCall(MethodCall(UsageContract.METHOD_OPEN_SETTINGS, null), result)

        @Suppress("UNCHECKED_CAST")
        val map = result.successValue as Map<String, Any>
        assertEquals(34, map[UsageContract.KEY_API_LEVEL])
        assertEquals(true, map[UsageContract.KEY_INTENT_LAUNCHED])
        assertEquals(true, map[UsageContract.KEY_OPENED_PACKAGE_SETTINGS])
    }

    @Test
    fun testOpenSettingsNoContextReturnsErrorNoContext() {
        val handler = createHandler(hasContext = false)
        val result = FakeMethodResult()

        handler.onMethodCall(MethodCall(UsageContract.METHOD_OPEN_SETTINGS, null), result)

        assertEquals(UsageContract.ERROR_NO_CONTEXT, result.errorCode)
    }

    @Test
    fun testQueryDailyUsageMissingArgumentsReturnsInvalidRange() {
        val handler = createHandler()
        val result = FakeMethodResult()

        handler.onMethodCall(MethodCall(UsageContract.METHOD_QUERY_DAILY_USAGE, null), result)

        assertEquals(UsageContract.ERROR_INVALID_RANGE, result.errorCode)
    }

    @Test
    fun testQueryDailyUsageInvalidRangeReturnsInvalidRange() {
        val handler = createHandler()
        val result = FakeMethodResult()
        val args = mapOf(
            UsageContract.KEY_START_TIME_MILLIS to 5000L,
            UsageContract.KEY_END_TIME_MILLIS to 1000L,
        )

        handler.onMethodCall(MethodCall(UsageContract.METHOD_QUERY_DAILY_USAGE, args), result)

        assertEquals(UsageContract.ERROR_INVALID_RANGE, result.errorCode)
    }

    @Test
    fun testQueryDailyUsagePermissionDeniedReturnsPermissionDeniedError() {
        fakeChecker.simulatedMode = AppOpsManager.MODE_IGNORED
        val handler = createHandler()
        val result = FakeMethodResult()
        val args = mapOf(
            UsageContract.KEY_START_TIME_MILLIS to 1000L,
            UsageContract.KEY_END_TIME_MILLIS to 5000L,
        )

        handler.onMethodCall(MethodCall(UsageContract.METHOD_QUERY_DAILY_USAGE, args), result)

        assertEquals(UsageContract.ERROR_PERMISSION_DENIED, result.errorCode)
    }

    @Test
    fun testQueryDailyUsageSuccessReturnsEnvelope() {
        fakeChecker.simulatedMode = AppOpsManager.MODE_ALLOWED
        fakeProvider.simulatedStats = listOf(
            AppUsageInfo("com.example.app", 3600000L, 4900000L, false),
        )
        val handler = createHandler()
        val result = FakeMethodResult()
        val args = mapOf(
            UsageContract.KEY_START_TIME_MILLIS to 1000L,
            UsageContract.KEY_END_TIME_MILLIS to 5000000L,
        )

        handler.onMethodCall(MethodCall(UsageContract.METHOD_QUERY_DAILY_USAGE, args), result)

        @Suppress("UNCHECKED_CAST")
        val map = result.successValue as Map<String, Any>
        assertEquals(34, map[UsageContract.KEY_API_LEVEL])
        assertEquals(1000L, map[UsageContract.KEY_START_TIME_MILLIS])
        assertEquals(5000000L, map[UsageContract.KEY_END_TIME_MILLIS])
        assertEquals(3600000L, map[UsageContract.KEY_TOTAL_FOREGROUND_MILLIS])
        assertNotNull(map[UsageContract.KEY_DATA_FRESHNESS])

        @Suppress("UNCHECKED_CAST")
        val apps = map[UsageContract.KEY_APPS] as List<Map<String, Any>>
        assertEquals(1, apps.size)
        assertEquals("com.example.app", apps[0][UsageContract.KEY_PACKAGE_NAME])
    }

    @Test
    fun testQueryDailyUsageExceptionReturnsSectionFailed() {
        fakeChecker.simulatedMode = AppOpsManager.MODE_ALLOWED
        fakeProvider.exceptionToThrow = RuntimeException("Database error")
        val handler = createHandler()
        val result = FakeMethodResult()
        val args = mapOf(
            UsageContract.KEY_START_TIME_MILLIS to 1000L,
            UsageContract.KEY_END_TIME_MILLIS to 5000L,
        )

        handler.onMethodCall(MethodCall(UsageContract.METHOD_QUERY_DAILY_USAGE, args), result)

        assertEquals(UsageContract.ERROR_SECTION_FAILED, result.errorCode)
        assertEquals("RuntimeException", result.errorMessage)
    }
}
