package com.haven.child.usage

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.haven.child.UsageContract

/**
 * Interface abstracting Activity/Intent launching for testability.
 */
interface IntentLauncher {
    fun launch(context: Context, intent: Intent): Boolean
}

/**
 * Production implementation launching intents through Android Context.
 */
class SystemIntentLauncher : IntentLauncher {
    override fun launch(context: Context, intent: Intent): Boolean {
        return try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}

/**
 * Dispatches navigation intents to Android Usage Access Settings.
 *
 * Tries package-specific URI first; falls back to generic settings if rejected.
 */
class SettingsNavigator(
    private val launcher: IntentLauncher = SystemIntentLauncher(),
    private val apiLevel: Int = Build.VERSION.SDK_INT,
) {
    fun openSettings(context: Context?): Map<String, Any> {
        if (context == null) {
            return mapOf(
                UsageContract.KEY_API_LEVEL to apiLevel,
                UsageContract.KEY_INTENT_LAUNCHED to false,
                UsageContract.KEY_OPENED_PACKAGE_SETTINGS to false,
            )
        }

        // Attempt 1: Package-specific intent
        val packageUri = Uri.parse("package:${context.packageName}")
        val packageIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS, packageUri)
        val packageSuccess = launcher.launch(context, packageIntent)

        if (packageSuccess) {
            return mapOf(
                UsageContract.KEY_API_LEVEL to apiLevel,
                UsageContract.KEY_INTENT_LAUNCHED to true,
                UsageContract.KEY_OPENED_PACKAGE_SETTINGS to true,
            )
        }

        // Attempt 2: Fallback to generic settings screen
        val genericIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        val genericSuccess = launcher.launch(context, genericIntent)

        return mapOf(
            UsageContract.KEY_API_LEVEL to apiLevel,
            UsageContract.KEY_INTENT_LAUNCHED to genericSuccess,
            UsageContract.KEY_OPENED_PACKAGE_SETTINGS to false,
        )
    }
}
