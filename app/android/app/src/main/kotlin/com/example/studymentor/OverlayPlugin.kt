package com.example.studymentor

import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
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
import androidx.core.app.NotificationCompat
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

        // ── Silent timer notification ─────────────────────────────────────────
        private const val NOTIF_CHANNEL_ID   = "studymentor_usage_timer"
        private const val NOTIF_CHANNEL_NAME = "Usage Timer"
        private const val NOTIF_ID           = 7001

        // ── Audible threshold alert notifications ─────────────────────────────
        private const val ALERT_CHANNEL_ID   = "studymentor_usage_alerts"
        private const val ALERT_CHANNEL_NAME = "Usage Alerts"
        private const val ALERT_NOTIF_ID_5MIN = 7002
        private const val ALERT_NOTIF_ID_1MIN = 7003
        private const val ALERT_NOTIF_ID_10S  = 7004

        @Volatile var instance: OverlayPlugin? = null
    }

    // ── Full-screen cooldown overlay ──────────────────────────────────────────
    private var overlayView: FrameLayout? = null
    private var windowManager: WindowManager? = null
    private var countdownText: TextView? = null

    // ── Notifications ─────────────────────────────────────────────────────────
    private var notificationManager: NotificationManager? = null
    private var notifChannelCreated = false

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
        notificationManager =
            activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureNotificationChannels()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Notification channels (Android 8+)
    // ─────────────────────────────────────────────────────────────────────────

    private fun ensureNotificationChannels() {
        if (notifChannelCreated) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Silent, non-dismissible timer channel
            val timerChannel = NotificationChannel(
                NOTIF_CHANNEL_ID,
                NOTIF_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shows how much time is left before the usage limit is reached"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            // Audible, dismissible alert channel — cannot be disabled from within the app
            val alertChannel = NotificationChannel(
                ALERT_CHANNEL_ID,
                ALERT_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Alerts when the usage limit is almost reached"
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(true)
            }

            notificationManager?.createNotificationChannel(timerChannel)
            notificationManager?.createNotificationChannel(alertChannel)
        }
        notifChannelCreated = true
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
                    // Hide usage notification before showing the full-screen overlay
                    cancelUsageNotification()
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

            // ── Silent usage timer notification ──────────────────────────────

            "showUsageTimer" -> {
                val remainingSeconds = call.argument<Int>("remainingSeconds") ?: 0
                postUsageNotification(remainingSeconds)
                result.success(null)
            }

            "hideUsageTimer" -> {
                cancelUsageNotification()
                result.success(null)
            }

            "updateUsageTimer" -> {
                val remaining = call.argument<Int>("remainingSeconds") ?: 0
                postUsageNotification(remaining)
                result.success(null)
            }

            // ── Audible threshold alert notification ─────────────────────────

            "showThresholdAlert" -> {
                val remainingSeconds = call.argument<Int>("remainingSeconds") ?: 0
                postThresholdAlert(remainingSeconds)
                result.success(null)
            }

            "updateState" -> result.success(null)

            "bringAppToForeground" -> {
                val intent = Intent(activity, MainActivity::class.java).apply {
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK
                            or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                            or Intent.FLAG_ACTIVITY_SINGLE_TOP,
                    )
                }
                activity.startActivity(intent)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Silent usage timer notification helpers
    // ─────────────────────────────────────────────────────────────────────────

    /** Formats [totalSeconds] as HH:MM:SS. */
    private fun formatHms(totalSeconds: Int): String {
        val h = totalSeconds / 3600
        val m = (totalSeconds % 3600) / 60
        val s = totalSeconds % 60
        return String.format("%02d:%02d:%02d", h, m, s)
    }

    /**
     * Posts (or updates) the persistent usage-timer notification.
     * The notification is non-dismissible (ongoing = true) and silent.
     */
    private fun postUsageNotification(remainingSeconds: Int) {
        ensureNotificationChannels()

        val timeText = formatHms(remainingSeconds)

        val iconRes = android.R.drawable.ic_menu_recent_history

        val notification = NotificationCompat.Builder(activity, NOTIF_CHANNEL_ID)
            .setSmallIcon(iconRes)
            .setContentTitle("Time remaining")
            .setContentText(timeText)
            .setOngoing(true)           // non-dismissible by the user
            .setOnlyAlertOnce(true)     // no sound/vibration on updates
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(
                android.app.PendingIntent.getActivity(
                    activity,
                    0,
                    Intent(activity, MainActivity::class.java).apply {
                        addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK
                                or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                                or Intent.FLAG_ACTIVITY_SINGLE_TOP,
                        )
                    },
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT
                        or android.app.PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            .build()

        notificationManager?.notify(NOTIF_ID, notification)
    }

    /** Cancels the usage-timer notification. */
    private fun cancelUsageNotification() {
        notificationManager?.cancel(NOTIF_ID)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Audible threshold alert notification helpers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Posts a one-shot audible, dismissible notification for a usage threshold.
     * The correct notification ID and message are chosen based on [remainingSeconds]:
     *   >= 270 s → 5-minute warning  (ALERT_NOTIF_ID_5MIN)
     *   >= 45 s  → 1-minute warning  (ALERT_NOTIF_ID_1MIN)
     *   < 45 s   → 10-second warning (ALERT_NOTIF_ID_10S)
     *
     * Using fuzzy bounds here because [remainingSeconds] is a live countdown
     * and may not land on exactly 300/60/10. The Dart side guards with
     * _firedThresholds so each logical threshold fires at most once per session.
     *
     * Each threshold uses a distinct notification ID so all three can coexist
     * in the tray simultaneously without replacing one another.
     */
    private fun postThresholdAlert(remainingSeconds: Int) {
        ensureNotificationChannels()

        data class AlertInfo(val notifId: Int, val title: String, val body: String)

        val alert = when {
            remainingSeconds >= 270 -> AlertInfo(
                ALERT_NOTIF_ID_5MIN,
                "5 minutes left ⏳",
                "You have 5 minutes before your usage limit is reached.",
            )
            remainingSeconds >= 45 -> AlertInfo(
                ALERT_NOTIF_ID_1MIN,
                "1 minute left ⚠️",
                "Only 1 minute remaining before your usage is blocked.",
            )
            else -> AlertInfo(
                ALERT_NOTIF_ID_10S,
                "10 seconds left 🚨",
                "Your usage limit is almost up!",
            )
        }

        val notification = NotificationCompat.Builder(activity, ALERT_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(alert.title)
            .setContentText(alert.body)
            .setOngoing(false)                          // dismissible by the user
            .setAutoCancel(true)                        // dismissed on tap
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDefaults(NotificationCompat.DEFAULT_ALL) // sound + vibration
            .setContentIntent(
                android.app.PendingIntent.getActivity(
                    activity,
                    alert.notifId,                      // unique request code per alert
                    Intent(activity, MainActivity::class.java).apply {
                        addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK
                                or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                                or Intent.FLAG_ACTIVITY_SINGLE_TOP,
                        )
                    },
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT
                        or android.app.PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            .build()

        notificationManager?.notify(alert.notifId, notification)
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

    fun dismissOverlay() {
        mainHandler.post {
            if (overlayView == null) return@post
            isDismissing = true
            removeOverlay()
            overlayChannel?.invokeMethod("onOverlayDismissed", null)
        }
    }

    fun notifyMonitoredAppIntercepted(packageName: String?) {
        mainHandler.post {
            overlayChannel?.invokeMethod("onMonitoredAppIntercepted", packageName)
        }
    }

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
    // Full-screen overlay (cooldown — unchanged)
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

    private fun buildRootView(): FrameLayout {
        val root = object : FrameLayout(activity) {

            override fun onTouchEvent(event: MotionEvent): Boolean = true

            override fun dispatchKeyEvent(event: KeyEvent): Boolean {
                if (event.action != KeyEvent.ACTION_DOWN) return true

                if (event.keyCode == KeyEvent.KEYCODE_BACK) {
                    StudyMentorAccessibilityService.justIntercepted = true
                    StudyMentorAccessibilityService.instance?.performGlobalAction(
                        android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_HOME,
                    )
                    dismissOverlay()
                }

                return true
            }
        }.apply {
            setBackgroundColor(Color.BLACK)
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

        countdownText = TextView(activity).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                topMargin = dpToPx(32)
            }
            text = "00:00"
            textSize = 56f
            setTextColor(Color.parseColor("#5C6BC0"))
            gravity = Gravity.CENTER
        }

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

    private fun removeOverlay() {
        overlayView?.let { windowManager?.removeView(it) }
        overlayView = null
        countdownText = null
        releaseAudioFocus()
    }

    private fun updateCountdownDisplay(remainingSeconds: Int) {
        val mins = remainingSeconds / 60
        val secs = remainingSeconds % 60
        countdownText?.text = String.format("%02d:%02d", mins, secs)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private fun getForegroundPackage(): String? {
        val usageManager = activity.getSystemService(Context.USAGE_STATS_SERVICE)
            as? android.app.usage.UsageStatsManager ?: return null

        val now = System.currentTimeMillis()
        val events = usageManager.queryEvents(now - 300_000L, now)

        var lastPackage: String? = null
        var lastTime = 0L

        val event = android.app.usage.UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (
                event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND &&
                event.timeStamp > lastTime
            ) {
                lastTime = event.timeStamp
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

        val pkg = activity.packageName
        val fullClass = StudyMentorAccessibilityService::class.java.name
        val shortClass = ".${StudyMentorAccessibilityService::class.java.simpleName}"

        val splitter = android.text.TextUtils.SimpleStringSplitter(':')
        splitter.setString(prefString)

        while (splitter.hasNext()) {
            val entry = splitter.next()
            val slash = entry.indexOf('/')
            if (slash < 0) continue
            if (entry.substring(0, slash) != pkg) continue
            val cls = entry.substring(slash + 1)
            if (cls == fullClass || cls == shortClass) return true
        }

        return false
    }

    private fun dpToPx(dp: Int): Int =
        (dp * activity.resources.displayMetrics.density).toInt()
}