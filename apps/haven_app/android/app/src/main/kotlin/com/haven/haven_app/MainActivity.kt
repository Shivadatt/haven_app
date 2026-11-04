package com.haven.haven_app

import com.haven.haven_app.child_services.platform_bridge.HavenBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    /**
     * Attaches the device-state lane as soon as an engine exists.
     *
     * It is attached rather than registered as a plugin: it answers questions about
     * one phone, has no method that changes anything, and does not need a plugin
     * manifest entry or a registrar to be found by the Dart side.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        HavenBridge.forApp { applicationContext }
            .attach(flutterEngine.dartExecutor.binaryMessenger)
    }
}
