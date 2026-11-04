package com.haven.haven_app.child_services.platform_bridge

/**
 * The whole native surface in one place: one channel, one method, and the keys
 * both sides agree on.
 *
 * Keeping the names here means the Dart decoder and these readers cannot drift
 * apart silently — a renamed key is a compile-time reference, not a string that
 * quietly stops matching.
 */
object BridgeContract {
    /** Reverse-DNS channel name for this app's own native lane. */
    const val CHANNEL = "haven.dev/child_device_state"

    ///** The one method: read every section that can be read right now. */
    const val METHOD_READ_ALL = "state.readAll"

    const val KEY_API_LEVEL = "apiLevel"
    const val KEY_OS_RELEASE = "osRelease"
    const val KEY_SECTIONS = "sections"
    const val KEY_SECTION_ERRORS = "sectionErrors"

    /** Returned when Dart asks for a method this lane does not have. */
    const val ERROR_UNKNOWN_METHOD = "unknown-method"

    /** Returned when there is no context to ask the operating system with. */
    const val ERROR_NO_CONTEXT = "no-context"

    /**
     * A section that could not be read at all. The reason is the exception's own
     * class name and nothing more: a message can carry a package path or a
     * resource name, and neither belongs on a screen a parent reads.
     */
    const val ERROR_SECTION_FAILED = "section-failed"
}
