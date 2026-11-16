package com.haven.child.usage

import android.content.Context
import android.os.Build
import com.haven.child.UsageContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles MethodChannel calls for the child Usage Access bridge (D-4).
 */
class UsageBridgeHandler(
    private val contextProvider: () -> Context?,
    private val permissionReader: AppOpsPermissionReader = AppOpsPermissionReader(),
    private val settingsNavigator: SettingsNavigator = SettingsNavigator(),
    private val usageStatsReader: UsageStatsReader = UsageStatsReader(),
    private val usageAggregator: UsageAggregator = UsageAggregator(),
    private val apiLevel: Int = Build.VERSION.SDK_INT,
) : MethodChannel.MethodCallHandler {

    companion object {
        fun attach(
            contextProvider: () -> Context?,
            messenger: BinaryMessenger,
        ): MethodChannel {
            val channel = MethodChannel(messenger, UsageContract.CHANNEL_NAME)
            val handler = UsageBridgeHandler(contextProvider)
            channel.setMethodCallHandler(handler)
            return channel
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            UsageContract.METHOD_GET_PERMISSION_STATUS -> handleGetPermissionStatus(result)
            UsageContract.METHOD_OPEN_SETTINGS -> handleOpenSettings(result)
            UsageContract.METHOD_QUERY_DAILY_USAGE -> handleQueryDailyUsage(call, result)
            else -> result.error(
                UsageContract.ERROR_UNKNOWN_METHOD,
                "Unknown usage bridge method: ${call.method}",
                null,
            )
        }
    }

    private fun handleGetPermissionStatus(result: MethodChannel.Result) {
        val context = contextProvider()
        if (context == null) {
            result.error(UsageContract.ERROR_NO_CONTEXT, "Android context is null", null)
            return
        }
        val status = permissionReader.getPermissionStatus(context)
        result.success(
            mapOf(
                UsageContract.KEY_API_LEVEL to apiLevel,
                UsageContract.KEY_STATUS to status,
            )
        )
    }

    private fun handleOpenSettings(result: MethodChannel.Result) {
        val context = contextProvider()
        if (context == null) {
            result.error(UsageContract.ERROR_NO_CONTEXT, "Android context is null", null)
            return
        }
        val response = settingsNavigator.openSettings(context)
        result.success(response)
    }

    private fun handleQueryDailyUsage(call: MethodCall, result: MethodChannel.Result) {
        val context = contextProvider()
        if (context == null) {
            result.error(UsageContract.ERROR_NO_CONTEXT, "Android context is null", null)
            return
        }

        val startRaw = call.argument<Number>(UsageContract.KEY_START_TIME_MILLIS)
        val endRaw = call.argument<Number>(UsageContract.KEY_END_TIME_MILLIS)

        if (startRaw == null || endRaw == null) {
            result.error(
                UsageContract.ERROR_INVALID_RANGE,
                "Both startTimeMillis and endTimeMillis arguments are required",
                null,
            )
            return
        }

        val startTime = startRaw.toLong()
        val endTime = endRaw.toLong()

        if (startTime < 0L || endTime < 0L || startTime >= endTime) {
            result.error(
                UsageContract.ERROR_INVALID_RANGE,
                "Invalid time range: startTimeMillis must be non-negative and strictly less than endTimeMillis",
                null,
            )
            return
        }

        val status = permissionReader.getPermissionStatus(context)
        if (status != UsageContract.PERMISSION_GRANTED) {
            result.error(
                UsageContract.ERROR_PERMISSION_DENIED,
                "Usage Access permission is not granted (current status: $status)",
                null,
            )
            return
        }

        try {
            val rawStats = usageStatsReader.queryUsage(context, startTime, endTime)
            val response = usageAggregator.aggregate(startTime, endTime, rawStats, apiLevel)
            result.success(response)
        } catch (e: IllegalArgumentException) {
            result.error(UsageContract.ERROR_INVALID_RANGE, e.message, null)
        } catch (e: Exception) {
            result.error(UsageContract.ERROR_SECTION_FAILED, e.javaClass.simpleName, null)
        }
    }
}
