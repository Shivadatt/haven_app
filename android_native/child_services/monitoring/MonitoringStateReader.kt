package com.haven.haven_app.child_services.monitoring

import android.app.AlarmManager
import android.app.AppOpsManager
import android.content.Context
import android.content.pm.PackageManager
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import android.os.Process
import com.haven.haven_app.child_services.platform_bridge.DeviceStateReader
import com.haven.haven_app.child_services.platform_bridge.OsAnswers
import com.haven.haven_app.child_services.platform_bridge.Sections

/**
 * Whether this phone would let a monitoring lane run at all.
 *
 * Usage access is the one this lane cannot infer from a permission check: the OS
 * hands it out in Settings and answers through the app-ops service, so the mode the
 * service reports is passed on unchanged. A `null` here means the phone refused to
 * say, and a screen must not read that as "allowed".
 */
class MonitoringStateReader : DeviceStateReader {
    override val section: String = Sections.MONITORING

    override fun read(context: Context): Map<String, Any?> {
        val usageMode = usageAccessMode(context)
        return linkedMapOf(
            "usageAccess" to (usageMode == AppOpsManager.MODE_ALLOWED),
            "usageAccessMode" to modeName(usageMode),
            "batteryOptimizationIgnored" to OsAnswers.atApi(Build.VERSION_CODES.M) {
                context.getSystemService(PowerManager::class.java)
                    ?.isIgnoringBatteryOptimizations(context.packageName)
            },
            "notificationImportance" to OsAnswers.atApi(Build.VERSION_CODES.N) {
                importanceName(
                    context.getSystemService(android.app.NotificationManager::class.java)
                        ?.importance,
                )
            },
            "exactAlarmsAllowed" to OsAnswers.atApi(Build.VERSION_CODES.S) {
                context.getSystemService(AlarmManager::class.java)?.canScheduleExactAlarms()
            },
            "runningServices" to serviceFacts(context),
            "silentMode" to silentMode(context),
        )
    }

    /** The app-ops answer for usage access, or `null` when the service refused. */
    private fun usageAccessMode(context: Context): Int? {
        val appOps = context.getSystemService(AppOpsManager::class.java) ?: return null
        val onQ = OsAnswers.atApi(Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                OP_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        }
        return onQ ?: OsAnswers.guarded {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(OP_GET_USAGE_STATS, Process.myUid(), context.packageName)
        }
    }

    /**
     * The OS's own mode constant, named. `REFUSED` is reported when the app-ops
     * service would not answer, which is different from "denied" and stays
     * different on the way out.
     */
    private fun modeName(mode: Int?): String = when (mode) {
        AppOpsManager.MODE_ALLOWED -> "allowed"
        AppOpsManager.MODE_IGNORED -> "ignored"
        AppOpsManager.MODE_ERRORED -> "errored"
        AppOpsManager.MODE_DEFAULT -> "system-default"
        AppOpsManager.MODE_FOREGROUND -> "foreground-only"
        null -> "refused"
        else -> "unknown-$mode"
    }

    private fun importanceName(importance: Int?): String = when (importance) {
        0 -> "none"
        1 -> "min"
        2 -> "low"
        3 -> "default"
        4 -> "high"
        5 -> "max"
        null -> "refused"
        else -> "unknown-$importance"
    }

    /**
     * How many services this build declares and whether any of them declares a
     * foreground type. Background work is only possible where the OS has been told
     * what kind of work it is, so the answer is the manifest's, not ours.
     */
    @Suppress("DEPRECATION")
    private fun serviceFacts(context: Context): Map<String, Any?> =
        OsAnswers.guarded {
            val services = context.packageManager
                .getPackageInfo(context.packageName, PackageManager.GET_SERVICES)
                .services
                ?.toList()
                ?: emptyList()
            mapOf(
                "count" to services.size,
                "withForegroundType" to services.count { service ->
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                        service.foregroundServiceType != 0
                },
            )
        } ?: mapOf("count" to null, "withForegroundType" to null)

    /** Whether the phone is set to a silent ring, which is all a session can know. */
    private fun silentMode(context: Context): Boolean? = OsAnswers.guarded {
        RingtoneManager.getActualDefaultRingtoneUri(context, RingtoneManager.TYPE_RINGTONE) == null
    }

    private companion object {
        /** The app-ops name the OS uses for usage access; the constant is not public. */
        const val OP_GET_USAGE_STATS = "android:get_usage_stats"
    }
}
