package com.haven.child.usage

import android.app.AppOpsManager
import android.content.Context

/**
 * Hand-written fake for AppOpsChecker testing without Android system services.
 */
class FakeAppOpsChecker(
    var simulatedMode: Int = AppOpsManager.MODE_ALLOWED,
    var shouldThrow: Boolean = false,
) : AppOpsChecker {

    override fun checkUsageStatsOp(context: Context): Int {
        if (shouldThrow) {
            throw SecurityException("Fake AppOps security exception")
        }
        return simulatedMode
    }
}
