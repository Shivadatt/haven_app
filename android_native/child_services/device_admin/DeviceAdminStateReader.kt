package com.haven.haven_app.child_services.device_admin

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import com.haven.haven_app.child_services.platform_bridge.DeviceStateReader
import com.haven.haven_app.child_services.platform_bridge.OsAnswers
import com.haven.haven_app.child_services.platform_bridge.Sections

/**
 * What the OS confirms about Haven's standing on this phone.
 *
 * Every answer here is DevicePolicyManager's, and the interesting part of a `null`
 * is that the phone will not tell a caller that is not an active admin. That is
 * exactly why no screen may say a restriction is in force on the strength of having
 * asked: [userRestrictionsReadable] is the only OS answer that could support such a
 * sentence, and for a plain installed app it is `null`.
 */
class DeviceAdminStateReader : DeviceStateReader {
    override val section: String = Sections.DEVICE_ADMIN

    override fun read(context: Context): Map<String, Any?> {
        val admin = ComponentName(context, HavenDeviceAdminReceiver::class.java)
        val policy = OsAnswers.guarded { context.getSystemService(DevicePolicyManager::class.java) }
        if (policy == null) return mapOf("serviceAvailable" to false)

        val active = OsAnswers.guarded { policy.isAdminActive(admin) } == true
        // Only a device or profile owner is handed this bundle, so a plain
        // installed app gets `null` — and a `null` is what stops any screen from
        // saying a rule is in force.
        val restrictions = OsAnswers.guarded { policy.getUserRestrictions(admin) }
        return linkedMapOf(
            "serviceAvailable" to true,
            "receiverDeclared" to receiverDeclared(context, admin),
            "adminActive" to active,
            "deviceOwner" to OsAnswers.guarded { policy.isDeviceOwnerApp(context.packageName) },
            "profileOwner" to OsAnswers.guarded { policy.isProfileOwnerApp(context.packageName) },
            "activeAdminCount" to OsAnswers.guarded { policy.activeAdmins?.size },
            "screenLockTimeoutMs" to screenTimeout(policy, admin, active),
            "passwordQuality" to if (active) {
                OsAnswers.guarded { policy.getPasswordQuality(admin) }
            } else {
                null
            },
            "storageEncryptionState" to OsAnswers.atApi(Build.VERSION_CODES.LOLLIPOP) {
                encryptionName(policy.storageEncryptionStatus)
            },
            "userRestrictionsReadable" to (restrictions != null),
            "restrictionsInForce" to restrictionsInForce(restrictions),
        )
    }

    /**
     * The restriction keys the OS itself reports as being in force, by their own
     * names.
     *
     * Not one of these keys is translated into a friendlier claim here, and the
     * names are the system's — the public constants for most of them are
     * `@SystemApi`, so a normal app cannot even name them. Whatever a screen says
     * about a rule, this list is the only OS answer behind it.
     */
    private fun restrictionsInForce(bundle: Bundle?): List<String>? =
        bundle?.keySet()?.filter { key -> bundle.getBoolean(key, false) }?.sorted()

    /**
     * The OS keeps a screen-timeout rule for an active admin and answers
     * [Long.MAX_VALUE] when none was ever set, so "not set" is reported as such
     * instead of as a timeout of about 292 million years.
     */
    private fun screenTimeout(policy: DevicePolicyManager, admin: ComponentName, active: Boolean): Long? {
        if (!active) return null
        val value = OsAnswers.guarded { policy.getMaximumTimeToLock(admin) } ?: return null
        return if (value == Long.MAX_VALUE) null else value
    }

    private fun encryptionName(status: Int): String = when (status) {
        DevicePolicyManager.ENCRYPTION_STATUS_UNSUPPORTED -> "unsupported"
        DevicePolicyManager.ENCRYPTION_STATUS_INACTIVE -> "inactive"
        DevicePolicyManager.ENCRYPTION_STATUS_ACTIVATING -> "activating"
        DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE -> "active"
        DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE_PER_USER -> "active-per-user"
        else -> "unknown-$status"
    }

    private fun receiverDeclared(context: Context, admin: ComponentName): Boolean {
        @Suppress("DEPRECATION")
        return OsAnswers.guarded {
            context.packageManager.getReceiverInfo(admin, PackageManager.GET_META_DATA)
            true
        } ?: false
    }
}
