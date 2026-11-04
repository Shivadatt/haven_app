package com.haven.haven_app.child_services.location

import android.Manifest
import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.SystemClock
import com.haven.haven_app.child_services.platform_bridge.DeviceStateReader
import com.haven.haven_app.child_services.platform_bridge.OsAnswers
import com.haven.haven_app.child_services.platform_bridge.Sections

/**
 * Where the phone's own location lane stands: which providers are switched on,
 * whether this build may ask, and how old the newest fix the OS is holding is.
 *
 * **No coordinates leave this file.** This lane answers the question "could a
 * location be reported at all", and a fix's latitude and longitude are not part of
 * that answer. Sending them would put a child's position on a channel a
 * settings screen reads, and the brief does not ask for that.
 *
 * The accuracy that is sent is the OS's own number, in metres — never a rounded
 * "about 10 m" and never a precision this phone did not report.
 */
class LocationStateReader : DeviceStateReader {
    override val section: String = Sections.LOCATION

    override fun read(context: Context): Map<String, Any?> {
        val manager = OsAnswers.guarded { context.getSystemService(LocationManager::class.java) }
        if (manager == null) return mapOf("serviceAvailable" to false)

        val fine = OsAnswers.granted(context, Manifest.permission.ACCESS_FINE_LOCATION, Build.VERSION_CODES.M)
        val coarse = OsAnswers.granted(context, Manifest.permission.ACCESS_COARSE_LOCATION)
        val mayAsk = fine == true || coarse == true

        return linkedMapOf(
            "serviceAvailable" to true,
            "gpsOn" to providerOn(manager, LocationManager.GPS_PROVIDER),
            "networkOn" to providerOn(manager, LocationManager.NETWORK_PROVIDER),
            "passiveOn" to providerOn(manager, LocationManager.PASSIVE_PROVIDER),
            "mayAsk" to mayAsk,
            "lastFix" to if (mayAsk) newestFix(manager) else null,
            "lastFixWithheldBecause" to if (mayAsk) null else "permission",
        )
    }

    private fun providerOn(manager: LocationManager, provider: String): Boolean? =
        OsAnswers.guarded { manager.isProviderEnabled(provider) }

    /**
     * The newest fix the OS is already holding, from whichever provider has one.
     *
     * `getLastKnownLocation` answers from the OS cache, so an app that has never
     * started updates still gets a real age — and `null` when the OS holds nothing,
     * which is not the same as a fix from now.
     */
    private fun newestFix(manager: LocationManager): Map<String, Any?>? {
        val candidates = listOf(
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
            LocationManager.PASSIVE_PROVIDER,
        ).mapNotNull { name -> OsAnswers.guarded { manager.getLastKnownLocation(name) } }
        val newest: Location = candidates.maxByOrNull { it.time } ?: return null
        val ageMs = SystemClock.elapsedRealtime() -
            (newest.elapsedRealtimeNanos / NANOS_PER_MILLISECOND)
        return mapOf(
            "provider" to newest.provider,
            "accuracyMetres" to newest.accuracy.toDouble(),
            "ageMs" to if (ageMs < 0) null else ageMs,
            "hasAltitude" to newest.hasAltitude(),
            "fromMockProvider" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                newest.isMock
            } else {
                null
            },
        )
    }

    private companion object {
        const val NANOS_PER_MILLISECOND = 1_000_000L
    }
}
