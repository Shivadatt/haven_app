package com.haven.haven_app.child_services.communication

import android.Manifest
import android.content.Context
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.os.Build
import com.haven.haven_app.child_services.platform_bridge.DeviceStateReader
import com.haven.haven_app.child_services.platform_bridge.OsAnswers
import com.haven.haven_app.child_services.platform_bridge.Sections

/**
 * What the phone says about its microphone and camera before anything is asked of
 * either.
 *
 * Nothing here opens a device: the counts come from the OS's list of hardware, the
 * mute and mode answers come from the audio service, and no call in this file can
 * start capture. A session that has not been consented to therefore has nothing to
 * be accused of using, which is the point §I of the brief makes about the
 * microphone and camera.
 */
class CommunicationStateReader : DeviceStateReader {
    override val section: String = Sections.COMMUNICATION

    override fun read(context: Context): Map<String, Any?> {
        val audio = OsAnswers.guarded { context.getSystemService(AudioManager::class.java) }
        return linkedMapOf(
            "microphoneAllowed" to OsAnswers.granted(
                context,
                Manifest.permission.RECORD_AUDIO,
                Build.VERSION_CODES.M,
            ),
            "cameraAllowed" to OsAnswers.granted(
                context,
                Manifest.permission.CAMERA,
                Build.VERSION_CODES.M,
            ),
            "audioServiceAvailable" to (audio != null),
            "microphoneMutedBySystem" to OsAnswers.guarded { audio?.isMicrophoneMute },
            "audioMode" to modeName(OsAnswers.guarded { audio?.mode }),
            "speakerphoneOn" to OsAnswers.guarded { audio?.isSpeakerphoneOn },
            "inputDevices" to OsAnswers.atApi(Build.VERSION_CODES.M) {
                audio?.getDevices(AudioManager.GET_DEVICES_INPUTS)?.size
            },
            "camerasPresent" to cameraCount(context),
        )
    }

    /** How many cameras the OS lists. Listing them does not open one. */
    private fun cameraCount(context: Context): Int? = OsAnswers.atApi(Build.VERSION_CODES.LOLLIPOP_MR1) {
        OsAnswers.guarded {
            context.getSystemService(CameraManager::class.java)?.cameraIdList?.size
        }
    }

    private fun modeName(mode: Int?): String = when (mode) {
        AudioManager.MODE_NORMAL -> "normal"
        AudioManager.MODE_RINGTONE -> "ringing"
        AudioManager.MODE_IN_CALL -> "in-call"
        AudioManager.MODE_IN_COMMUNICATION -> "in-communication"
        null -> "refused"
        else -> "unknown-$mode"
    }
}
