package com.haven.haven_app.child_services.permissions

import android.content.Context
import com.haven.haven_app.child_services.platform_bridge.DeviceStateReader
import com.haven.haven_app.child_services.platform_bridge.OsAnswers
import com.haven.haven_app.child_services.platform_bridge.Sections
import com.haven.haven_app.child_services.platform_bridge.TrackedPermission

/**
 * What the OS grants this installed build, permission by permission.
 *
 * The two facts are kept apart on purpose. `granted` answers the question the OS
 * was actually asked; `notDeclared` says the question could not be asked because
 * this build never asked to hold that permission. Reporting the second as "denied"
 * would blame whoever holds the phone for a decision made when the APK was built,
 * and a screen that showed it would be wrong about who to ask.
 */
class PermissionStateReader : DeviceStateReader {
    override val section: String = Sections.PERMISSIONS

    override fun read(context: Context): Map<String, Any?> {
        val declared = OsAnswers.declaredPermissions(context)
        val answers = LinkedHashMap<String, Any?>()
        val missing = ArrayList<String>()
        for (tracked in TrackedPermission.entries) {
            val declaredHere = OsAnswers.isDeclared(declared, tracked.declaredAs)
            answers[tracked.key] = if (declaredHere) {
                OsAnswers.granted(context, tracked.osName, tracked.since)
            } else {
                null
            }
            if (!declaredHere) missing.add(tracked.key)
        }
        return linkedMapOf(
            "granted" to answers,
            "undeclared" to missing,
            "declaredPermissions" to declared.map { it.substringAfterLast('.') },
            "batteryExemptionDeclared" to OsAnswers.isDeclared(
                declared,
                "REQUEST_IGNORE_BATTERY_OPTIMIZATIONS",
            ),
            "bootReceiverDeclared" to OsAnswers.isDeclared(declared, "RECEIVE_BOOT_COMPLETED"),
            "runtimeAskable" to TrackedPermission.entries
                .filter { it.since <= android.os.Build.VERSION.SDK_INT }
                .map { it.key },
        )
    }
}
