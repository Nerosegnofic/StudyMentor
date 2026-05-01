package com.example.studymentor

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class OverlayPlugin(private val activity: FlutterActivity) {

    companion object {
        const val OVERLAY_CHANNEL = "com.example.studymentor/overlay"
        const val USAGE_CHANNEL   = "com.example.studymentor/usage_stats"
        const val ACCESS_CHANNEL  = "com.example.studymentor/accessibility"
        private const val REQUEST_OVERLAY_PERMISSION     = 1001
        private const val REQUEST_USAGE_STATS_PERMISSION = 1002

        @Volatile var instance: OverlayPlugin? = null
    }

    // ── View references ───────────────────────────────────────────────────────
    private var overlayView: FrameLayout? = null
    private var windowManager: WindowManager? = null
    private var countdownText: TextView? = null

    // ── Channel & audio ───────────────────────────────────────────────────────
    private var overlayChannel: MethodChannel? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    // Guard against double-firing the dismiss callback
    private var isDismissing = false

    // ── Pending results for permission flows ──────────────────────────────────
    private var pendingOverlayResult: MethodChannel.Result? = null
    private var pendingUsageResult: MethodChannel.Result? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    // ─────────────────────────────────────────────────────────────────────────
    // Registration
    // ─────────────────────────────────────────────────────────────────────────

    fun registerWith(flutterEngine: FlutterEngine) {
        instance = this
        FlutterEngineCache.getInstance().put("main_engine", flutterEngine)

        overlayChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OVERLAY_CHANNEL,
        ).also { ch -> ch.setMethodCallHandler { call, result -> handleOverlay(call, result) } }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            USAGE_CHANNEL,
        ).setMethodCallHandler { call, result -> handleUsage(call, result) }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ACCESS_CHANNEL,
        ).setMethodCallHandler { call, result -> handleAccessibility(call, result) }

        audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Overlay channel
    // ─────────────────────────────────────────────────────────────────────────

    private fun handleOverlay(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "requestOverlayPermission" -> {
                if (Settings.canDrawOverlays(activity)) {
                    result.success(true)
                } else {
                    pendingOverlayResult = result
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${activity.packageName}"),
                    )
                    @Suppress("DEPRECATION")
                    activity.startActivityForResult(intent, REQUEST_OVERLAY_PERMISSION)
                }
            }

            "showOverlay" -> {
                if (!Settings.canDrawOverlays(activity)) {
                    result.error("NO_PERMISSION", "SYSTEM_ALERT_WINDOW not granted", null)
                    return
                }
                val remainingSeconds = call.argument<Int>("remainingSeconds") ?: 30
                activity.runOnUiThread {
                    showOrUpdateOverlay(remainingSeconds)
                    result.success(null)
                }
            }

            "hideOverlay" -> {
                activity.runOnUiThread {
                    removeOverlay()
                    result.success(null)
                }
            }

            "updateCountdown" -> {
                val remaining = call.argument<Int>("remainingSeconds") ?: 0
                activity.runOnUiThread {
                    updateCountdownDisplay(remaining)
                    result.success(null)
                }
            }

            "updateState" -> result.success(null)

            else -> result.notImplemented()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Usage-stats channel
    // ─────────────────────────────────────────────────────────────────────────

    private fun handleUsage(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestUsageStatsPermission" -> {
                if (hasUsageStatsPermission()) {
                    result.success(true)
                } else {
                    pendingUsageResult = result
                    @Suppress("DEPRECATION")
                    activity.startActivityForResult(
                        Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS),
                        REQUEST_USAGE_STATS_PERMISSION,
                    )
                }
            }
            "getForegroundApp" -> result.success(getForegroundPackage())
            else -> result.notImplemented()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Accessibility channel
    // ─────────────────────────────────────────────────────────────────────────

    private fun handleAccessibility(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAccessibilityEnabled" -> result.success(isAccessibilityEnabled())

            "requestAccessibilityPermission" -> {
                if (!isAccessibilityEnabled()) {
                    activity.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                }
                result.success(null)
            }

            "setMonitoredApps" -> {
                val apps = call.argument<List<String>>("apps") ?: emptyList()
                StudyMentorAccessibilityService.monitoredApps.clear()
                StudyMentorAccessibilityService.monitoredApps.addAll(apps)
                result.success(null)
            }

            "setBlocked" -> {
                StudyMentorAccessibilityService.isBlocked =
                    call.argument<Boolean>("blocked") ?: false
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Activity-result forwarding
    // ─────────────────────────────────────────────────────────────────────────

    fun onActivityResult(requestCode: Int) {
        when (requestCode) {
            REQUEST_OVERLAY_PERMISSION -> {
                pendingOverlayResult?.success(Settings.canDrawOverlays(activity))
                pendingOverlayResult = null
            }
            REQUEST_USAGE_STATS_PERMISSION -> {
                pendingUsageResult?.success(hasUsageStatsPermission())
                pendingUsageResult = null
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Called by the accessibility service when the user navigates to the
    // launcher or a non-monitored app — dismisses the overlay if visible.
    // Safe to call from any thread; idempotent (overlayView null-check guards).
    // ─────────────────────────────────────────────────────────────────────────

    fun dismissOverlay() {
        mainHandler.post {
            if (overlayView == null) return@post
            isDismissing = true
            removeOverlay()
            overlayChannel?.invokeMethod("onOverlayDismissed", null)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Called by the accessibility service when it intercepts a monitored app.
    // Notifies Dart so the overlay re-appears with the remaining time.
    // ─────────────────────────────────────────────────────────────────────────

    fun notifyMonitoredAppIntercepted(packageName: String?) {
        mainHandler.post {
            overlayChannel?.invokeMethod("onMonitoredAppIntercepted", packageName)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Audio focus — silences YouTube / TikTok when overlay appears
    // ─────────────────────────────────────────────────────────────────────────

    private fun requestAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attrs)
                .setAcceptsDelayedFocusGain(false)
                .setOnAudioFocusChangeListener { }
                .build()
            audioFocusRequest = req
            audioManager?.requestAudioFocus(req)
        } else {
            @Suppress("DEPRECATION")
            audioManager?.requestAudioFocus(
                { },
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN,
            )
        }
    }

    private fun releaseAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus { }
        }
        audioFocusRequest = null
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Overlay window — creation & update
    // ─────────────────────────────────────────────────────────────────────────

    private fun showOrUpdateOverlay(remainingSeconds: Int) {
        if (overlayView != null) {
            updateCountdownDisplay(remainingSeconds)
            return
        }

        isDismissing = false
        requestAudioFocus()

        windowManager = activity.getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ERROR

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                    or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.OPAQUE,
        )

        val root = buildRootView()
        overlayView = root
        windowManager?.addView(root, params)
        updateCountdownDisplay(remainingSeconds)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Overlay view hierarchy
    // ─────────────────────────────────────────────────────────────────────────

    private fun buildRootView(): FrameLayout {
        val root = object : FrameLayout(activity) {

            override fun onTouchEvent(event: MotionEvent): Boolean = true

            override fun dispatchKeyEvent(event: KeyEvent): Boolean {
                if (event.action != KeyEvent.ACTION_DOWN) return true
                if (event.keyCode == KeyEvent.KEYCODE_BACK) {
                    // Navigate to home first so the monitored app underneath
                    // doesn't immediately re-trigger the overlay when dismissed.
                    StudyMentorAccessibilityService.justIntercepted = true
                    StudyMentorAccessibilityService.instance?.performGlobalAction(
                        android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_HOME
                    )
                    dismissOverlay()
                }
                return true
            }
        }.apply {
            setBackgroundColor(Color.parseColor("#FF000000"))
            isFocusable = true
            isFocusableInTouchMode = true
        }

        val center = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            )
        }

        // Mascot circle
        val mascotCircle = TextView(activity).apply {
            val size = dpToPx(120)
            layoutParams = LinearLayout.LayoutParams(size, size).apply {
                gravity = Gravity.CENTER_HORIZONTAL
            }
            setBackgroundColor(Color.parseColor("#5C6BC0"))
            textSize = 48f
            gravity = Gravity.CENTER
            text = "OO"
            setTextColor(Color.WHITE)
        }

        // Title
        val titleText = TextView(activity).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dpToPx(24) }
            text = "Take a Break!"
            textSize = 28f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }

        // Subtitle
        val subtitleText = TextView(activity).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dpToPx(8) }
            text = "You have been using this app for too long"
            textSize = 16f
            setTextColor(Color.parseColor("#B0B0B0"))
            gravity = Gravity.CENTER
        }

        // Countdown
        countdownText = TextView(activity).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                topMargin = dpToPx(32)
            }
            text = "00:30"
            textSize = 56f
            setTextColor(Color.parseColor("#5C6BC0"))
            gravity = Gravity.CENTER
        }

        // Hint
        val timerLabel = TextView(activity).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dpToPx(8) }
            text = "You may press home or back"
            textSize = 13f
            setTextColor(Color.parseColor("#808080"))
            gravity = Gravity.CENTER
        }

        center.addView(mascotCircle)
        center.addView(titleText)
        center.addView(subtitleText)
        center.addView(countdownText)
        center.addView(timerLabel)
        root.addView(center)
        return root
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Overlay removal
    // ─────────────────────────────────────────────────────────────────────────

    private fun removeOverlay() {
        overlayView?.let { windowManager?.removeView(it) }
        overlayView   = null
        countdownText = null
        releaseAudioFocus()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Countdown display
    // ─────────────────────────────────────────────────────────────────────────

    private fun updateCountdownDisplay(remainingSeconds: Int) {
        val mins = remainingSeconds / 60
        val secs = remainingSeconds % 60
        countdownText?.text = String.format("%02d:%02d", mins, secs)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Usage-stats helpers
    // ─────────────────────────────────────────────────────────────────────────

    private fun getForegroundPackage(): String? {
        val usageManager = activity.getSystemService(Context.USAGE_STATS_SERVICE)
            as? android.app.usage.UsageStatsManager ?: return null
        val now = System.currentTimeMillis()
        // Use MOVE_TO_FOREGROUND events — unlike lastTimeUsed, these only fire
        // when an Activity actually comes to the screen, so YouTube's background
        // media session cannot falsely keep it registered as "foreground".
        val events = usageManager.queryEvents(now - 300_000L, now)
        var lastPackage: String? = null
        var lastTime = 0L
        val event = android.app.usage.UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND
                && event.timeStamp > lastTime
            ) {
                lastTime    = event.timeStamp
                lastPackage = event.packageName
            }
        }
        return lastPackage
    }

    private fun hasUsageStatsPermission(): Boolean {
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

    private fun isAccessibilityEnabled(): Boolean {
        val prefString = Settings.Secure.getString(
            activity.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false

        val pkg        = activity.packageName
        val fullClass  = StudyMentorAccessibilityService::class.java.name
        val shortClass = ".${StudyMentorAccessibilityService::class.java.simpleName}"

        // TextUtils.SimpleStringSplitter is exactly what the Android framework uses
        // internally — handles the colon-separated list correctly on all API levels.
        val splitter = android.text.TextUtils.SimpleStringSplitter(':')
        splitter.setString(prefString)
        while (splitter.hasNext()) {
            val entry = splitter.next()
            val slash = entry.indexOf('/')
            if (slash < 0) continue
            if (entry.substring(0, slash) != pkg) continue
            val cls = entry.substring(slash + 1)
            // Match both formats: full name and short name (.ClassName)
            if (cls == fullClass || cls == shortClass) return true
        }
        return false
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Utilities
    // ─────────────────────────────────────────────────────────────────────────

    private fun dpToPx(dp: Int): Int =
        (dp * activity.resources.displayMetrics.density).toInt()
}
