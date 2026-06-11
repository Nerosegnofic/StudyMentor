package com.example.studymentor

import android.app.AppOpsManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
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
import androidx.core.app.NotificationManagerCompat
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

        // ── Notification channel ──────────────────────────────────────────────
        //
        // All timer-related notifications use the single CHILD_TIMER channel,
        // which is created and owned by LocalNotificationService (Dart-side,
        // flutter_local_notifications) during app startup in main().
        //
        // This class must NOT create notification channels. The channel already
        // exists by the time any of the post* methods below are called.
        private const val CHILD_TIMER_CHANNEL_ID = "CHILD_TIMER"

        // ── Notification IDs ──────────────────────────────────────────────────
        // Silent persistent timer notifications
        private const val NOTIF_ID          = 7001   // usage countdown
        private const val COOLDOWN_NOTIF_ID = 7005   // cooldown countdown

        // Audible threshold alerts — usage
        private const val ALERT_NOTIF_ID_5MIN = 7002
        private const val ALERT_NOTIF_ID_1MIN = 7003
        private const val ALERT_NOTIF_ID_10S  = 7004

        // Audible threshold alerts — cooldown
        private const val COOLDOWN_ALERT_NOTIF_ID_5MIN = 7006
        private const val COOLDOWN_ALERT_NOTIF_ID_1MIN = 7007
        private const val COOLDOWN_ALERT_NOTIF_ID_10S  = 7008

        @Volatile var instance: OverlayPlugin? = null
    }

    // ── Full-screen cooldown overlay ──────────────────────────────────────────
    private var overlayView: FrameLayout? = null
    private var windowManager: WindowManager? = null
    private var countdownText: TextView? = null

    // ── Channel & audio ───────────────────────────────────────────────────────
    private var overlayChannel: MethodChannel? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    private var isDismissing = false

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
        // No notification channel creation — CHILD_TIMER is created by
        // LocalNotificationService.init() before registerWith() is called.
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Overlay channel
    // ─────────────────────────────────────────────────────────────────────────

    private fun handleOverlay(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "showOverlay" -> {
                if (!Settings.canDrawOverlays(activity)) {
                    result.error("NO_PERMISSION", "SYSTEM_ALERT_WINDOW not granted", null)
                    return
                }
                val remainingSeconds = call.argument<Int>("remainingSeconds") ?: 30
                activity.runOnUiThread {
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

            // ── Silent cooldown timer notification ───────────────────────────

            "showCooldownTimer" -> {
                val remainingSeconds = call.argument<Int>("remainingSeconds") ?: 0
                postCooldownNotification(remainingSeconds)
                result.success(null)
            }

            "hideCooldownTimer" -> {
                cancelCooldownNotification()
                result.success(null)
            }

            "updateCooldownTimer" -> {
                val remaining = call.argument<Int>("remainingSeconds") ?: 0
                postCooldownNotification(remaining)
                result.success(null)
            }

            // ── Audible threshold alert notifications (usage) ────────────────

            "showThresholdAlert" -> {
                val remainingSeconds = call.argument<Int>("remainingSeconds") ?: 0
                postThresholdAlert(remainingSeconds)
                result.success(null)
            }

            // ── Audible threshold alert notifications (cooldown) ─────────────

            "showCooldownThresholdAlert" -> {
                val remainingSeconds = call.argument<Int>("remainingSeconds") ?: 0
                postCooldownThresholdAlert(remainingSeconds)
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
    // Shared helpers
    // ─────────────────────────────────────────────────────────────────────────

    private fun formatHms(totalSeconds: Int): String {
        val h = totalSeconds / 3600
        val m = (totalSeconds % 3600) / 60
        val s = totalSeconds % 60
        return String.format("%02d:%02d:%02d", h, m, s)
    }

    private fun mainActivityIntent() = Intent(activity, MainActivity::class.java).apply {
        addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK
                or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                or Intent.FLAG_ACTIVITY_SINGLE_TOP,
        )
    }

    private fun mainActivityPendingIntent(requestCode: Int): PendingIntent =
        PendingIntent.getActivity(
            activity, requestCode, mainActivityIntent(),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun notificationManager() =
        activity.getSystemService(Context.NOTIFICATION_SERVICE)
            as android.app.NotificationManager

    // ─────────────────────────────────────────────────────────────────────────
    // Silent usage timer notification
    // ─────────────────────────────────────────────────────────────────────────

    private fun postUsageNotification(remainingSeconds: Int) {
        val notification = NotificationCompat.Builder(activity, CHILD_TIMER_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setContentTitle("Time remaining")
            .setContentText(formatHms(remainingSeconds))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(mainActivityPendingIntent(0))
            .build()
        notificationManager().notify(NOTIF_ID, notification)
    }

    private fun cancelUsageNotification() {
        notificationManager().cancel(NOTIF_ID)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Silent cooldown timer notification
    // ─────────────────────────────────────────────────────────────────────────

    private fun postCooldownNotification(remainingSeconds: Int) {
        val notification = NotificationCompat.Builder(activity, CHILD_TIMER_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setContentTitle("Cooldown — apps locked")
            .setContentText(formatHms(remainingSeconds))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(mainActivityPendingIntent(0))
            .build()
        notificationManager().notify(COOLDOWN_NOTIF_ID, notification)
    }

    private fun cancelCooldownNotification() {
        notificationManager().cancel(COOLDOWN_NOTIF_ID)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Audible threshold alerts — usage
    // ─────────────────────────────────────────────────────────────────────────

    private fun postThresholdAlert(remainingSeconds: Int) {
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
        val notification = NotificationCompat.Builder(activity, CHILD_TIMER_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(alert.title)
            .setContentText(alert.body)
            .setOngoing(false)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setContentIntent(mainActivityPendingIntent(alert.notifId))
            .build()
        notificationManager().notify(alert.notifId, notification)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Audible threshold alerts — cooldown
    // ─────────────────────────────────────────────────────────────────────────

    private fun postCooldownThresholdAlert(remainingSeconds: Int) {
        data class AlertInfo(val notifId: Int, val title: String, val body: String)
        val alert = when {
            remainingSeconds >= 270 -> AlertInfo(
                COOLDOWN_ALERT_NOTIF_ID_5MIN,
                "5 minutes until unlock ⏳",
                "Your cooldown ends in 5 minutes — get ready to study!",
            )
            remainingSeconds >= 45 -> AlertInfo(
                COOLDOWN_ALERT_NOTIF_ID_1MIN,
                "1 minute until unlock ⚠️",
                "Almost there — apps will unlock in 1 minute.",
            )
            else -> AlertInfo(
                COOLDOWN_ALERT_NOTIF_ID_10S,
                "Apps unlocking soon 🎉",
                "Your cooldown is ending in 10 seconds!",
            )
        }
        val notification = NotificationCompat.Builder(activity, CHILD_TIMER_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(alert.title)
            .setContentText(alert.body)
            .setOngoing(false)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setContentIntent(mainActivityPendingIntent(alert.notifId))
            .build()
        notificationManager().notify(alert.notifId, notification)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Usage-stats channel
    // ─────────────────────────────────────────────────────────────────────────

    private fun handleUsage(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
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

            "setMonitoredApps" -> {
                val apps = call.argument<List<String>>("apps") ?: emptyList()
                StudyMentorAccessibilityService.monitoredApps.clear()
                StudyMentorAccessibilityService.monitoredApps.addAll(apps)
                result.success(null)
            }

            "setBlocked" -> {
                val blocked = call.argument<Boolean>("blocked") ?: false
                StudyMentorAccessibilityService.isBlocked = blocked
                activity.getSharedPreferences(AppPrefs.PREFS_NAME, Context.MODE_PRIVATE)
                    .edit()
                    .putBoolean(AppPrefs.KEY_IS_BLOCKED, blocked)
                    .apply()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Activity-result forwarding
    // ─────────────────────────────────────────────────────────────────────────

    fun onActivityResult(requestCode: Int) {
        // No pending permission results to handle.
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
            audioManager?.requestAudioFocus({ }, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN)
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
    // Full-screen overlay
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
            if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND
                && event.timeStamp > lastTime) {
                lastTime = event.timeStamp
                lastPackage = event.packageName
            }
        }
        return lastPackage
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