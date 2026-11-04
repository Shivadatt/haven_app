package com.haven.haven_app.child_services.device_admin

import android.app.admin.DeviceAdminReceiver

/**
 * The component the OS asks about when it is asked whether Haven is a device admin.
 *
 * It exists so that the question in [DeviceAdminStateReader] is a well-formed one:
 * asking about an admin this build never declared would always answer "no", and
 * that would look like a fact about the phone rather than a fact about this build.
 *
 * It remembers nothing and starts nothing. Enrollment state is read from
 * [android.app.admin.DevicePolicyManager] whenever the app asks, so a restart cannot
 * leave a stale copy behind — and this build has no code path that enforces anything,
 * because the command lane that would authorise one is blocked at the backend.
 */
class HavenDeviceAdminReceiver : DeviceAdminReceiver()
