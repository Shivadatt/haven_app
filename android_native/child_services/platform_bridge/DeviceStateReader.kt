package com.haven.haven_app.child_services.platform_bridge

import android.content.Context

/**
 * One readable slice of what the operating system says about this device.
 *
 * The five readers in this lane share this shape so the bridge can hold them as a
 * list, ask each one separately, and let a single reader fail without taking the
 * whole answer with it — a phone that cannot report its encryption state still
 * reports its notification permission.
 */
interface DeviceStateReader {
    /** The key the answers are filed under, and the name Dart reads them back by. */
    val section: String

    /**
     * The OS's current answers.
     *
     * Values are limited to what a MethodChannel can carry without a codec of our
     * own: `Boolean`, `Int`, `Long`, `Double`, `String`, `List`, `Map` and `null`.
     * A `null` means the OS could not be asked, never "no".
     */
    fun read(context: Context): Map<String, Any?>
}

/**
 * The section names, kept in one place so the Dart decoder and these readers agree
 * without having to read each other's source.
 */
object Sections {
    const val PERMISSIONS = "permissions"
    const val MONITORING = "monitoring"
    const val LOCATION = "location"
    const val DEVICE_ADMIN = "deviceAdmin"
    const val COMMUNICATION = "communication"
}
