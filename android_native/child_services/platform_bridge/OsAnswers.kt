package com.haven.haven_app.child_services.platform_bridge

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

/**
 * One rule for every value this lane reports: either the operating system
 * answered, or the answer is `null`.
 *
 * A `null` is what lets a screen say "this phone cannot say" instead of showing a
 * guess. So nothing below turns a refusal into a plausible-looking default, and no
 * reader reports a capability it has not actually asked the OS about — the brief's
 * rule that a restriction is never claimed unless the OS confirms it.
 */
object OsAnswers {
    /**
     * The OS refuses several of these calls to a caller that is not an active
     * device admin. A refusal is the answer, not an error worth propagating.
     */
    fun <T> guarded(block: () -> T): T? = try {
        block()
    } catch (_: SecurityException) {
        null
    } catch (_: IllegalStateException) {
        null
    } catch (_: IllegalArgumentException) {
        null
    }

    /** `null` below [level], because the question does not exist on that OS. */
    fun <T> atApi(level: Int, block: () -> T): T? =
        if (Build.VERSION.SDK_INT >= level) guarded(block) else null

    /**
     * Whether the OS currently grants [permission] to this app.
     *
     * `null` when the permission has no meaning on this API level — asking
     * `POST_NOTIFICATIONS` on Android 12, for example, has no answer to give.
     */
    fun granted(context: Context, permission: String, since: Int = 0): Boolean? {
        if (Build.VERSION.SDK_INT < since) return null
        val answer = try {
            context.checkPermission(permission, android.os.Process.myPid(), android.os.Process.myUid())
        } catch (_: Exception) {
            return null
        }
        return answer == PackageManager.PERMISSION_GRANTED
    }

    /**
     * The permissions this installed build actually declares.
     *
     * A permission that is not declared can never be granted, and reporting that
     * as "denied" would blame whoever holds the phone for a gap in the build.
     */
    @Suppress("DEPRECATION")
    fun declaredPermissions(context: Context): List<String> = guarded {
        val info = context.packageManager.getPackageInfo(
            context.packageName,
            PackageManager.GET_PERMISSIONS,
        )
        info.requestedPermissions?.toList() ?: emptyList()
    } ?: emptyList()

    /** True when [name] — a bare constant like `ACCESS_FINE_LOCATION` — is declared. */
    fun isDeclared(declared: List<String>, name: String): Boolean =
        declared.any { it.endsWith(".permission.$name") }
}

/**
 * The permissions this lane asks the OS about, and the answer each one can
 * legitimately have.
 *
 * Only runtime permissions belong here. `PACKAGE_USAGE_STATS` is deliberately
 * absent: it is a special access the OS hands out through Settings, and
 * `checkPermission` answers "denied" for it even when the app-op is allowed — so
 * [com.haven.haven_app.child_services.monitoring.MonitoringStateReader] reports it
 * from the app-ops service instead, which is where the real answer lives.
 */
enum class TrackedPermission(
    /** The `android.Manifest.permission` constant the OS checks against. */
    val osName: String,
    /** The API level from which that question has an answer. */
    val since: Int,
    /** The short key the Dart side reads this answer under. */
    val key: String,
) {
    NOTIFICATIONS(Manifest.permission.POST_NOTIFICATIONS, Build.VERSION_CODES.TIRAMISU, "notifications"),
    LOCATION_IN_USE(Manifest.permission.ACCESS_FINE_LOCATION, Build.VERSION_CODES.M, "locationInUse"),
    LOCATION_BACKGROUND(
        Manifest.permission.ACCESS_BACKGROUND_LOCATION,
        Build.VERSION_CODES.Q,
        "locationBackground",
    ),
    MICROPHONE(Manifest.permission.RECORD_AUDIO, Build.VERSION_CODES.M, "microphone"),
    CAMERA(Manifest.permission.CAMERA, Build.VERSION_CODES.M, "camera"),
    ;

    /** The last path segment of the OS constant, which is what a screen can show. */
    val declaredAs: String
        get() = osName.substringAfterLast('.')
}
