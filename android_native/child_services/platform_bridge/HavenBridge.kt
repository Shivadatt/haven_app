package com.haven.haven_app.child_services.platform_bridge

import android.content.Context
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The only door between Dart and this lane, and it has one handle on it: read the
 * device's state.
 *
 * There is no method here that changes anything, because nothing in this build has
 * the specification that would make a change legitimate — so the surface a parent
 * app can reach is exactly the surface it can verify. Adding an "apply" method
 * would let a screen claim a restriction the OS had not confirmed.
 */
class HavenBridge(
    private val contextProvider: () -> Context,
    private val readers: List<DeviceStateReader>,
) {
    fun attach(messenger: BinaryMessenger): MethodChannel {
        val channel = MethodChannel(messenger, BridgeContract.CHANNEL)
        channel.setMethodCallHandler { call, reply -> respond(call, reply) }
        return channel
    }

    private fun respond(call: MethodCall, reply: MethodChannel.Result) {
        if (call.method != BridgeContract.METHOD_READ_ALL) {
            reply.error(
                BridgeContract.ERROR_UNKNOWN_METHOD,
                "The native state lane answers ${BridgeContract.METHOD_READ_ALL} only.",
                null,
            )
            return
        }
        val context = try {
            contextProvider()
        } catch (_: Exception) {
            null
        }
        if (context == null) {
            reply.error(
                BridgeContract.ERROR_NO_CONTEXT,
                "The phone had no running app to ask.",
                null,
            )
            return
        }
        reply.success(readAll(context))
    }

    /**
     * Asks every reader in turn. A reader that throws is recorded by its own
     * section name and the exception's class, and the others are still answered —
     * one unreadable section must not blank the whole report.
     */
    private fun readAll(context: Context): Map<String, Any?> {
        val sections = LinkedHashMap<String, Any?>()
        val failures = LinkedHashMap<String, String>()
        for (reader in readers) {
            try {
                sections[reader.section] = reader.read(context)
            } catch (_: Exception) {
                failures[reader.section] = BridgeContract.ERROR_SECTION_FAILED
            }
        }
        return mapOf(
            BridgeContract.KEY_API_LEVEL to Build.VERSION.SDK_INT,
            BridgeContract.KEY_OS_RELEASE to Build.VERSION.RELEASE,
            BridgeContract.KEY_SECTIONS to sections,
            BridgeContract.KEY_SECTION_ERRORS to failures,
        )
    }

    companion object {
        /** The bridge this app attaches: one reader per area of the device lane. */
        fun forApp(contextProvider: () -> Context): HavenBridge = HavenBridge(
            contextProvider,
            listOf(
                com.haven.haven_app.child_services.permissions.PermissionStateReader(),
                com.haven.haven_app.child_services.monitoring.MonitoringStateReader(),
                com.haven.haven_app.child_services.location.LocationStateReader(),
                com.haven.haven_app.child_services.device_admin.DeviceAdminStateReader(),
                com.haven.haven_app.child_services.communication.CommunicationStateReader(),
            ),
        )
    }
}
