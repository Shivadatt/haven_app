package com.haven.child

import com.haven.child.usage.UsageBridgeHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        UsageBridgeHandler.attach(
            contextProvider = { applicationContext },
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }
}

