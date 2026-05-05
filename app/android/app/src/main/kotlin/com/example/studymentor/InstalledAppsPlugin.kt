package com.example.studymentor

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.util.Base64
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class InstalledAppsPlugin(private val context: Context) {

    companion object {
        const val CHANNEL = "com.example.studymentor/installed_apps"
        const val PREFS_NAME = "studymentor_prefs"
        const val KEY_INVENTORY_DIRTY = "inventory_dirty"

        // These packages are never returned, regardless of any filter.
        // Blocking them would brick or lock the student out of their phone.
        private val EXCLUDED_PACKAGES = setOf(
            "com.example.studymentor",
            "com.android.systemui",
            "com.android.settings",
            "com.android.phone",
            "com.google.android.dialer",
            "com.android.launcher",
            "com.android.launcher2",
            "com.android.launcher3",
            "com.google.android.apps.nexuslauncher",
            "com.miui.home",
            "com.sec.android.app.launcher",
            "com.huawei.android.launcher",
            "com.oppo.launcher",
            "com.vivo.launcher",
            "com.oneplus.launcher",
            "com.nothing.launcher",
        )
    }

    fun registerWith(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result -> handleCall(call, result) }
    }

    private fun handleCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInstalledApps" -> {
                val includeSystemApps = call.argument<Boolean>("includeSystemApps") ?: false
                result.success(getInstalledApps(includeSystemApps))
            }
            "isInventoryDirty" -> {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                result.success(prefs.getBoolean(KEY_INVENTORY_DIRTY, false))
            }
            "markInventoryClean" -> {
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    .edit().putBoolean(KEY_INVENTORY_DIRTY, false).apply()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun getInstalledApps(includeSystemApps: Boolean): List<Map<String, Any?>> {
        val pm = context.packageManager
        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val launcherIntent = android.content.Intent(android.content.Intent.ACTION_MAIN, null)
        launcherIntent.addCategory(android.content.Intent.CATEGORY_LAUNCHER)
        val launcherApps = pm.queryIntentActivities(launcherIntent, 0)
            .map { it.activityInfo.packageName }
            .toSet()

        return apps
            .filter { app ->
                val pkg = app.packageName
                val isSystem = (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val isLauncher = launcherApps.contains(pkg)
                
                // Exclude anything in the safety list (startsWith covers launcher variants)
                val excluded = EXCLUDED_PACKAGES.any { pkg.startsWith(it) }
                
                // Show if:
                // 1. Not excluded AND
                // 2. (It's a launcher app OR includeSystemApps is true OR it's not a system app)
                !excluded && (isLauncher || includeSystemApps || !isSystem)
            }
            .mapNotNull { app ->
                try {
                    val label = pm.getApplicationLabel(app).toString()
                    val isSystem = (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                    val iconBase64 = try {
                        drawableToBase64(pm.getApplicationIcon(app))
                    } catch (_: Exception) {
                        null
                    }
                    mapOf(
                        "package"     to app.packageName,
                        "label"       to label,
                        "isSystem"    to isSystem,
                        "iconBase64"  to iconBase64,
                    )
                } catch (_: Exception) {
                    null
                }
            }
            .sortedBy { (it["label"] as? String)?.lowercase() }
    }

    private fun drawableToBase64(drawable: android.graphics.drawable.Drawable): String {
        val source = when (drawable) {
            is BitmapDrawable -> drawable.bitmap
            else -> {
                val w = drawable.intrinsicWidth.takeIf { it > 0 } ?: 48
                val h = drawable.intrinsicHeight.takeIf { it > 0 } ?: 48
                val bm = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bm)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bm
            }
        }
        // Scale to 48×48 — enough for a list avatar, keeps stored size small (~1–3 KB each)
        val scaled = Bitmap.createScaledBitmap(source, 48, 48, true)
        val stream = ByteArrayOutputStream()
        scaled.compress(Bitmap.CompressFormat.PNG, 85, stream)
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    }
}
