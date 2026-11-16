package com.haven.child.usage

import android.app.AppOpsManager
import android.content.Context
import android.os.Build
import android.os.Process
import com.haven.child.UsageContract

/**
 * Interface abstracting AppOps operations for testability without mocks.
 */
interface AppOpsChecker {
    fun checkUsageStatsOp(context: Context): Int
}

/**
 * Production implementation querying Android's AppOpsManager.
 */
class SystemAppOpsChecker : AppOpsChecker {
    override fun checkUsageStatsOp(context: Context): Int {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return AppOpsManager.MODE_IGNORED
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        }
    }
}

/**
 * Reads Usage Access permission state through Android AppOps (D-4).
 *
 * Distinguishes granted, denied, and unsupported states safely.
 */
class AppOpsPermissionReader(
    private val checker: AppOpsChecker = SystemAppOpsChecker(),
    private val apiLevel: Int = Build.VERSION.SDK_INT,
) {
    fun getPermissionStatus(context: Context?): String {
        if (context == null) {
            return UsageContract.PERMISSION_DENIED
        }
        if (apiLevel < Build.VERSION_CODES.LOLLIPOP) {
            return UsageContract.PERMISSION_UNSUPPORTED
        }
        return try {
            val mode = checker.checkUsageStatsOp(context)
            if (mode == AppOpsManager.MODE_ALLOWED) {
                UsageContract.PERMISSION_GRANTED
            } else {
                UsageContract.PERMISSION_DENIED
            }
        } catch (_: Exception) {
            UsageContract.PERMISSION_DENIED
        }
    }
}
