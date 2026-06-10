package com.example.studymentor

import android.app.AppOpsManager
import android.app.NotificationManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Native implementation of the `com.example.studymentor/permissions` channel.
 *
 * Handles two methods:
 *   • isGranted(permission: String) → Boolean
 *   • openSettings(permission: String)
 *
 * Permission names match [RequiredPermission.name] values defined in Dart:
 *   systemAlertWindow, packageUsageStats, postNotifications,
 *   accessibilityService, deviceAdmin, batteryOptimization
 */
class PermissionPlugin(private val activity: MainActivity) {

    companion object {
        const val CHANNEL = "com.example.studymentor/permissions"
    }

    fun registerWith(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            val permission = call.argument<String>("permission")
            when (call.method) {
                "isGranted" -> {
                    if (permission == null) {
                        result.error("INVALID_ARG", "permission is required", null)
                        return@setMethodCallHandler
                    }
                    result.success(checkPermission(permission))
                }
                "openSettings" -> {
                    if (permission == null) {
                        result.error("INVALID_ARG", "permission is required", null)
                        return@setMethodCallHandler
                    }
                    openSettings(permission)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ── Permission checks ─────────────────────────────────────────────────────

    private fun checkPermission(permission: String): Boolean {
        return when (permission) {
            "systemAlertWindow"    -> checkSystemAlertWindow()
            "packageUsageStats"    -> checkPackageUsageStats()
            "postNotifications"    -> checkPostNotifications()
            "accessibilityService" -> checkAccessibilityService()
            "deviceAdmin"          -> checkDeviceAdmin()
            "batteryOptimization"  -> checkBatteryOptimization()
            else -> false
        }
    }

    /** SYSTEM_ALERT_WINDOW — Settings.canDrawOverlays(). */
    private fun checkSystemAlertWindow(): Boolean {
        return Settings.canDrawOverlays(activity)
    }

    /**
     * PACKAGE_USAGE_STATS — AppOpsManager.checkOpNoThrow().
     * There is no public API; we use the same approach as the existing
     * UsageTimerService / InstalledAppsPlugin code in this project.
     */
    private fun checkPackageUsageStats(): Boolean {
        val appOps = activity.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                activity.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                activity.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * POST_NOTIFICATIONS — on Android 13+ (API 33) this is a runtime
     * permission. On older versions notifications are always allowed.
     */
    private fun checkPostNotifications(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val nm = activity.getSystemService(Context.NOTIFICATION_SERVICE)
                    as NotificationManager
            nm.areNotificationsEnabled()
        } else {
            true
        }
    }

    /**
     * BIND_ACCESSIBILITY_SERVICE — checks the secure Settings string
     * "enabled_accessibility_services" for our service's component name.
     */
    private fun checkAccessibilityService(): Boolean {
        val expectedComponent = ComponentName(
            activity,
            StudyMentorAccessibilityService::class.java,
        ).flattenToString()

        val enabledServices = Settings.Secure.getString(
            activity.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false

        // The setting is a colon-separated list of component names.
        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)
        for (component in colonSplitter) {
            if (component.equals(expectedComponent, ignoreCase = true)) {
                return true
            }
        }
        return false
    }

    /** BIND_DEVICE_ADMIN — DevicePolicyManager.isAdminActive(). */
    private fun checkDeviceAdmin(): Boolean {
        val dpm = activity.getSystemService(Context.DEVICE_POLICY_SERVICE)
                as DevicePolicyManager
        val adminComponent = ComponentName(activity, MyDeviceAdminReceiver::class.java)
        return dpm.isAdminActive(adminComponent)
    }

    /**
     * Battery optimisation — PowerManager.isIgnoringBatteryOptimizations().
     *
     * Returns true when the app is on the system's battery-optimisation
     * whitelist (i.e. Android will NOT kill our background services for
     * battery reasons). Available on API 23+ (Marshmallow); always returns
     * true on older devices where Doze does not exist.
     */
    private fun checkBatteryOptimization(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val pm = activity.getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(activity.packageName)
    }

    // ── Settings launchers ────────────────────────────────────────────────────

    private fun openSettings(permission: String) {
        when (permission) {
            "systemAlertWindow"    -> openSystemAlertWindowSettings()
            "packageUsageStats"    -> openUsageAccessSettings()
            "postNotifications"    -> openNotificationSettings()
            "accessibilityService" -> openAccessibilitySettings()
            "deviceAdmin"          -> openDeviceAdminSettings()
            "batteryOptimization"  -> openBatteryOptimizationSettings()
        }
    }

    /** Opens the "Display over other apps" page for this specific app. */
    private fun openSystemAlertWindowSettings() {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${activity.packageName}"),
        )
        activity.startActivity(intent)
    }

    /** Opens the Usage Access (App usage access) list. */
    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.data = Uri.parse("package:${activity.packageName}")
        try {
            activity.startActivity(intent)
        } catch (e: Exception) {
            activity.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        }
    }

    /**
     * Opens the notification settings for this app on Android 8+ (API 26).
     * On older versions opens the general app info page.
     */
    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${activity.packageName}")
            }
        }
        activity.startActivity(intent)
    }

    /** Opens the Accessibility services list. */
    private fun openAccessibilitySettings() {
        activity.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
    }

    /**
     * Opens the Device Admin activation screen.
     * Reuses [DeviceAdminPlugin.REQUEST_CODE_ENABLE_ADMIN] so that
     * [MainActivity.onActivityResult] correctly clears the bypass flag.
     */
    private fun openDeviceAdminSettings() {
        val adminComponent = ComponentName(activity, MyDeviceAdminReceiver::class.java)
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
            putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "StudyMentor needs Device Administrator access to prevent " +
                "uninstallation without your parent's permission.",
            )
        }
        @Suppress("DEPRECATION")
        activity.startActivityForResult(intent, DeviceAdminPlugin.REQUEST_CODE_ENABLE_ADMIN)
    }

    /**
     * Opens the battery optimisation detail screen for this app directly.
     *
     * On API 23+ we use ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS with a
     * package URI, which opens a single-tap system dialog — the fastest UX.
     *
     * Fallback: ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS opens the full
     * "Battery optimization" list so the user can find the app manually.
     * This is needed on some OEMs (e.g. Xiaomi MIUI) that block the direct
     * intent, and is the only option below API 23 (Doze unavailable → no-op).
     */
    private fun openBatteryOptimizationSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:${activity.packageName}"),
                )
                activity.startActivity(intent)
                return
            } catch (e: Exception) {
                // Direct intent not supported on this device — fall through.
            }
        }
        // Fallback: open the battery optimisation list.
        try {
            activity.startActivity(
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            )
        } catch (e: Exception) {
            // Last resort: open app info page.
            activity.startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:${activity.packageName}")
                }
            )
        }
    }
}