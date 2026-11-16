package com.haven.child.usage

import android.content.Context
import android.content.Intent

/**
 * Hand-written fake for IntentLauncher testing without Activity launching.
 */
class FakeIntentLauncher(
    var packageLaunchSuccess: Boolean = true,
    var genericLaunchSuccess: Boolean = true,
) : IntentLauncher {

    val launchedIntents = mutableListOf<Intent>()

    override fun launch(context: Context, intent: Intent): Boolean {
        launchedIntents.add(intent)
        // In SettingsNavigator, the 1st attempt is package-specific, 2nd is generic fallback.
        return if (launchedIntents.size == 1) {
            packageLaunchSuccess
        } else {
            genericLaunchSuccess
        }
    }
}
