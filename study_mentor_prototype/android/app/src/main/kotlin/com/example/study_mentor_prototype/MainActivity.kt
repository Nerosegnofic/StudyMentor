package com.example.study_mentor_prototype

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.content.getSystemService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    // Channel for starting/stopping the service
    private val USAGE_TRACKING_CHANNEL = "com.example.study_mentor_prototype/usage_tracking"
    // Channel for handling special permissions
    private val PERMISSIONS_CHANNEL = "com.example.study_mentor_prototype/permissions"

    // This companion object makes the channel accessible from the service.
    companion object {
        var channel: MethodChannel? = null
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Create the channel object once
        val usageTrackingChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_TRACKING_CHANNEL)

        // This is the crucial link. We are storing the channel where the service can find it.
        channel = usageTrackingChannel

        // --- Method Channel for Usage Tracking Service ---
        usageTrackingChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startTracking" -> {
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

        // --- Method Channel for Special Permissions ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsageStatsPermission" -> {
                    // Opens the specific Android settings page
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "hasSystemAlertWindowPermission" -> {
                    result.success(hasSystemAlertWindowPermission())
                }
                "requestSystemAlertWindowPermission" -> {
                    // Opens the specific Android settings page for drawing over other apps
                    val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                    startActivity(intent)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // --- Helper methods for Usage Tracking Service (UNCHANGED) ---
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

    // --- Helper methods for checking special permissions (UNCHANGED) ---
    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun hasSystemAlertWindowPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            // This permission was granted automatically on older Android versions
            true
        }
    }
}
