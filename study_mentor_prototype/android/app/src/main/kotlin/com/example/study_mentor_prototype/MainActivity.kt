package com.example.study_mentor_prototype

import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import androidx.compose.ui.semantics.error
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.study_mentor_prototype/usage_tracking"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "startTracking" -> {
                    // Extract arguments sent from Flutter
                    val childId = call.argument<String>("childId")
                    val sessionTimeMinutes = call.argument<Int>("sessionTimeMinutes")

                    if (childId != null && sessionTimeMinutes != null) {
                        startUsageTrackingService(childId, sessionTimeMinutes)
                        result.success("Usage tracking service started for childId: $childId")
                    } else {
                        result.error("INVALID_ARGUMENTS", "childId or sessionTimeMinutes is missing", null)
                    }
                }
                "stopTracking" -> {
                    stopUsageTrackingService()
                    result.success("Usage tracking service stopped")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startUsageTrackingService(childId: String, sessionTimeMinutes: Int) {
        val serviceIntent = Intent(this, UsageTrackingService::class.java).apply {
            putExtra("childId", childId)
            putExtra("sessionTimeMinutes", sessionTimeMinutes)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopUsageTrackingService() {
        val serviceIntent = Intent(this, UsageTrackingService::class.java)
        stopService(serviceIntent)
    }
}
