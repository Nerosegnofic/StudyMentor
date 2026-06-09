package com.example.studymentor

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Binder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

/**
 * A foreground Service that owns the restricted-app usage timer and cooldown
 * countdown. It survives the StudyMentor app being swiped away from recents
 * and persists all state to SharedPreferences on every tick so that even a
 * process kill + restart recovers correctly.
 *
 * ┌─────────────────────────────────────────────────────────┐
 * │  Timer state owned here (native, survives app death)    │
 * │    • totalUsageSeconds   – cumulative restricted usage  │
 * │    • isBlocked           – in cooldown?                 │
 * │    • cooldownRemaining   – seconds left in cooldown     │
 * │    • quizDismissed       – student dismissed quiz?      │
 * └─────────────────────────────────────────────────────────┘
 *
 * The Flutter layer (MascotOverlayService) starts/stops this service via
 * the "com.example.studymentor/timer_service" MethodChannel and receives
 * state updates through the same channel via [TimerServiceBridge].
 *
 * Compatibility: Android 8 (API 26) – Android 15+ (API 35).
 */
class UsageTimerService : Service() {

    // ── Companion ─────────────────────────────────────────────────────────────

    companion object {
        // Intent actions
        const val ACTION_START   = "ACTION_START_TIMER"
        const val ACTION_STOP    = "ACTION_STOP_TIMER"
        const val ACTION_UNBLOCK = "ACTION_UNBLOCK"

        // Intent extras
        const val EXTRA_MONITORED_APPS      = "EXTRA_MONITORED_APPS"
        const val EXTRA_USAGE_LIMIT_SECS    = "EXTRA_USAGE_LIMIT_SECS"
        const val EXTRA_COOLDOWN_LIMIT_SECS = "EXTRA_COOLDOWN_LIMIT_SECS"
        const val EXTRA_STUDENT_LOGGED_IN   = "EXTRA_STUDENT_LOGGED_IN"

        /**
         * Boolean extra attached to the MainActivity launch Intent when the
         * usage limit is reached while the app is not in the foreground.
         * MainActivity reads this on onCreate / onNewIntent and fires
         * onLimitReached back into Flutter so the quiz screen is shown
         * regardless of whether the app was already open or cold-launched.
         */
        const val EXTRA_QUIZ_ON_LAUNCH = "EXTRA_QUIZ_ON_LAUNCH"

        // Foreground service notification — active (usage / cooldown)
        private const val FG_NOTIF_CHANNEL_ID        = "studymentor_timer_service"
        private const val FG_NOTIF_CHANNEL_NAME      = "StudyMentor Timer"
        // Foreground service notification — idle placeholder (IMPORTANCE_MIN)
        private const val FG_NOTIF_CHANNEL_IDLE_ID   = "studymentor_timer_idle"
        private const val FG_NOTIF_CHANNEL_IDLE_NAME = "StudyMentor"
        private const val FG_NOTIF_ID                = 8001

        // ── Threshold alert notification channels ─────────────────────────────
        private const val ALERT_CHANNEL_ID   = "studymentor_usage_alerts"
        private const val ALERT_CHANNEL_NAME = "Usage Alerts"

        private const val COOLDOWN_ALERT_CHANNEL_ID   = "studymentor_cooldown_alerts"
        private const val COOLDOWN_ALERT_CHANNEL_NAME = "Cooldown Alerts"

        // Notification IDs — must match OverlayPlugin so they replace each other
        private const val ALERT_NOTIF_ID_5MIN          = 7002
        private const val ALERT_NOTIF_ID_1MIN          = 7003
        private const val ALERT_NOTIF_ID_10S           = 7004
        private const val COOLDOWN_ALERT_NOTIF_ID_5MIN = 7006
        private const val COOLDOWN_ALERT_NOTIF_ID_1MIN = 7007
        private const val COOLDOWN_ALERT_NOTIF_ID_10S  = 7008

        // SharedPreferences — timer-specific prefs file
        private const val PREFS_NAME             = "studymentor_timer_prefs"
        private const val KEY_TOTAL_USAGE        = "total_usage_seconds"
        private const val KEY_IS_BLOCKED         = "is_blocked"
        private const val KEY_COOLDOWN_REMAINING = "cooldown_remaining_seconds"
        private const val KEY_STUDENT_LOGGED_IN  = "student_logged_in"
        private const val KEY_USAGE_LIMIT        = "usage_limit_seconds"
        private const val KEY_COOLDOWN_LIMIT     = "cooldown_limit_seconds"
        private const val KEY_MONITORED_APPS     = "monitored_apps"
        const val KEY_TIMER_NOTIF_ENABLED        = "timer_notification_enabled"
        const val KEY_COOLDOWN_NOTIF_ENABLED     = "cooldown_notification_enabled"

        // ── Quiz dismissed flag ───────────────────────────────────────────────
        // Persisted so that a cold relaunch (swipe-to-dismiss + reopen) respects
        // the student's decision to dismiss the quiz during this cooldown cycle.
        //
        // Three-state semantics stored as two booleans:
        //   KEY_QUIZ_DISMISSED = false, KEY_QUIZ_SHOWN = false
        //     → quiz has not been shown yet this cooldown (show it)
        //   KEY_QUIZ_DISMISSED = false, KEY_QUIZ_SHOWN = true
        //     → quiz was shown but not explicitly dismissed (show it again on relaunch)
        //   KEY_QUIZ_DISMISSED = true,  KEY_QUIZ_SHOWN = true
        //     → student explicitly dismissed the quiz (do NOT show it again)
        const val KEY_QUIZ_DISMISSED = "quiz_dismissed_for_cooldown"
        const val KEY_QUIZ_SHOWN     = "quiz_shown_for_cooldown"

        // State snapshot broadcast (used by TimerServiceBridge to push to Flutter)
        const val BROADCAST_STATE_UPDATE    = "com.example.studymentor.TIMER_STATE_UPDATE"
        const val EXTRA_TOTAL_USAGE         = "total_usage"
        const val EXTRA_IS_BLOCKED          = "is_blocked"
        const val EXTRA_COOLDOWN_REM        = "cooldown_remaining"
        const val EXTRA_THRESHOLD_ALERT     = "threshold_alert_seconds" // -1 = none
        const val EXTRA_MONITORED_IN_FG     = "monitored_in_foreground"

        /** Returns the SharedPreferences used by this service (accessible from Flutter bridge). */
        fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    // ── Binder ────────────────────────────────────────────────────────────────

    inner class LocalBinder : Binder() {
        fun getService(): UsageTimerService = this@UsageTimerService
    }

    private val binder = LocalBinder()
    override fun onBind(intent: Intent?): IBinder = binder

    // ── State ─────────────────────────────────────────────────────────────────

    private var isRunning             = false
    private var totalUsageSecs        = 0
    private var isBlocked             = false
    private var cooldownRemSecs       = 0
    private var usageLimitSecs        = 1800
    private var cooldownLimitSecs     = 600
    private var monitoredApps         = mutableSetOf<String>()
    private var studentLoggedIn       = false
    private var monitoredInForeground = false
    private var timerNotifEnabled     = true
    private var cooldownNotifEnabled  = true

    // ── Quiz dismissed state ──────────────────────────────────────────────────

    /**
     * True when the student explicitly dismissed the quiz without completing it.
     * Persisted to SharedPreferences so it survives process death.
     * Cleared when the cooldown ends ([unblock]) or a new cooldown starts ([block]).
     */
    private var quizDismissedForCooldown = false

    /**
     * True once the quiz has been shown at least once during this cooldown.
     * Persisted so that on cold relaunch we know the quiz was already triggered
     * and should be shown again (unless the student dismissed it).
     */
    private var quizShownForCooldown = false

    // One-shot threshold alert tracking (reset on unblock)
    private val firedUsageThresholds    = mutableSetOf<Int>()
    private val firedCooldownThresholds = mutableSetOf<Int>()

    private val handler      = Handler(Looper.getMainLooper())
    private val tickRunnable = object : Runnable {
        override fun run() {
            if (isRunning) {
                tick()
                handler.postDelayed(this, 1_000)
            }
        }
    }

    private lateinit var prefs: SharedPreferences
    private var notificationManager: NotificationManager? = null

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        prefs = prefs(applicationContext)
        notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        ensureAllNotifChannels()
        restoreState()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                intent.getStringArrayListExtra(EXTRA_MONITORED_APPS)?.let {
                    monitoredApps = it.toMutableSet()
                    saveMonitoredApps()
                }
                intent.getIntExtra(EXTRA_USAGE_LIMIT_SECS, -1).takeIf { it >= 0 }?.let {
                    usageLimitSecs = it
                    prefs.edit().putInt(KEY_USAGE_LIMIT, it).apply()
                }
                intent.getIntExtra(EXTRA_COOLDOWN_LIMIT_SECS, -1).takeIf { it >= 0 }?.let {
                    cooldownLimitSecs = it
                    prefs.edit().putInt(KEY_COOLDOWN_LIMIT, it).apply()
                }
                studentLoggedIn = intent.getBooleanExtra(EXTRA_STUDENT_LOGGED_IN, true)
                prefs.edit().putBoolean(KEY_STUDENT_LOGGED_IN, studentLoggedIn).apply()

                startForegroundWithNotification()
                if (!isRunning) {
                    isRunning = true
                    handler.post(tickRunnable)
                }
            }

            ACTION_STOP -> stopSelf()

            ACTION_UNBLOCK -> unblock()

            null -> {
                // Restarted by OS after kill — restore and resume
                startForegroundWithNotification()
                if (studentLoggedIn && !isRunning) {
                    isRunning = true
                    handler.post(tickRunnable)
                }
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        handler.removeCallbacks(tickRunnable)
        super.onDestroy()
    }

    // ── Core tick ─────────────────────────────────────────────────────────────

    private fun tick() {
        if (!studentLoggedIn) return

        val foreground = getForegroundPackage()
        var thresholdAlert = -1

        if (isBlocked) {
            // ── Cooldown countdown ─────────────────────────────────────────────
            if (cooldownRemSecs > 0) {
                cooldownRemSecs--
                thresholdAlert = checkCooldownThreshold(cooldownRemSecs)
                if (thresholdAlert >= 0) {
                    postCooldownThresholdAlert(thresholdAlert)
                }
            }
            if (cooldownRemSecs <= 0) {
                unblock()
                return
            }

            if (foreground != null && monitoredApps.contains(foreground)) {
                StudyMentorAccessibilityService.instance?.performGlobalAction(
                    android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_HOME,
                )
                OverlayPlugin.instance?.notifyMonitoredAppIntercepted(foreground)
            }

        } else {
            // ── Usage accumulation ─────────────────────────────────────────────
            if (foreground != null && monitoredApps.contains(foreground)) {
                totalUsageSecs++
                val remaining = (usageLimitSecs - totalUsageSecs).coerceAtLeast(0)
                thresholdAlert = checkUsageThreshold(remaining)
                if (thresholdAlert >= 0) {
                    postUsageThresholdAlert(thresholdAlert)
                }

                if (totalUsageSecs >= usageLimitSecs) {
                    block()
                    return
                }
            }
        }

        monitoredInForeground = !isBlocked &&
            foreground != null && monitoredApps.contains(foreground)

        persistState()
        broadcastState(thresholdAlert, monitoredInForeground = monitoredInForeground)
        updateFgNotification()
    }

    // ── Block / unblock ───────────────────────────────────────────────────────

    private fun block() {
        isBlocked                = true
        cooldownRemSecs          = cooldownLimitSecs
        quizDismissedForCooldown = false  // fresh cooldown — always reset dismissed flag
        quizShownForCooldown     = false  // fresh cooldown — quiz not yet shown
        firedUsageThresholds.clear()
        StudyMentorAccessibilityService.isBlocked = true

        // Write the shared blocked flag so StudyMentorAccessibilityService can
        // restore it independently on onServiceConnected, eliminating the window
        // where UsageTimerService is still restarting after an OEM process kill
        // but the accessibility service is already back online with isBlocked=false.
        applicationContext
            .getSharedPreferences(AppPrefs.PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putBoolean(AppPrefs.KEY_IS_BLOCKED, true).apply()

        persistState()
        broadcastState(thresholdAlert = -1, limitReached = true)
        updateFgNotification()

        val launchIntent = Intent(applicationContext, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK
                    or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                    or Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
            putExtra(EXTRA_QUIZ_ON_LAUNCH, true)
        }
        applicationContext.startActivity(launchIntent)
    }

    fun unblock() {
        isBlocked                = false
        cooldownRemSecs          = 0
        totalUsageSecs           = 0
        monitoredInForeground    = false
        quizDismissedForCooldown = false  // cooldown over — always reset
        quizShownForCooldown     = false  // cooldown over — always reset
        firedUsageThresholds.clear()
        firedCooldownThresholds.clear()
        StudyMentorAccessibilityService.isBlocked = false

        // Clear the shared blocked flag so the accessibility service knows
        // restrictions are lifted even before the next onServiceConnected.
        applicationContext
            .getSharedPreferences(AppPrefs.PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putBoolean(AppPrefs.KEY_IS_BLOCKED, false).apply()

        persistState()
        broadcastState(-1)
        updateFgNotification()
    }

    // ── Quiz dismissed flag — public setters ──────────────────────────────────

    /**
     * Called from [TimerServiceBridge] when Flutter reports the student
     * explicitly dismissed the quiz (tapped away without completing).
     * Also marks the quiz as having been shown.
     */
    fun setQuizDismissed(dismissed: Boolean) {
        quizDismissedForCooldown = dismissed
        if (dismissed) quizShownForCooldown = true
        prefs.edit()
            .putBoolean(KEY_QUIZ_DISMISSED, quizDismissedForCooldown)
            .putBoolean(KEY_QUIZ_SHOWN, quizShownForCooldown)
            .apply()
    }

    /**
     * Called from [TimerServiceBridge] when Flutter reports the quiz was
     * shown (pushed onto the navigator). Marks it as shown without dismissing.
     */
    fun markQuizShown() {
        quizShownForCooldown = true
        prefs.edit().putBoolean(KEY_QUIZ_SHOWN, true).apply()
    }

    // ── Threshold helpers ─────────────────────────────────────────────────────

    private fun checkUsageThreshold(remaining: Int): Int {
        val thresholds = listOf(300, 60, 10)
        for (t in thresholds) {
            if (!firedUsageThresholds.contains(t) && remaining == t) {
                firedUsageThresholds.add(t)
                return remaining
            }
        }
        return -1
    }

    private fun checkCooldownThreshold(remaining: Int): Int {
        val thresholds = listOf(300, 60, 10)
        for (t in thresholds) {
            if (!firedCooldownThresholds.contains(t) && remaining == t) {
                firedCooldownThresholds.add(t)
                return remaining
            }
        }
        return -1
    }

    // ── Threshold alert notifications ─────────────────────────────────────────

    private fun mainActivityPendingIntent(requestCode: Int): PendingIntent {
        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK
                    or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                    or Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
        }
        return PendingIntent.getActivity(
            applicationContext, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun postUsageThresholdAlert(remainingSeconds: Int) {
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

        val notification = NotificationCompat.Builder(applicationContext, ALERT_CHANNEL_ID)
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

        notificationManager?.notify(alert.notifId, notification)
    }

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

        val notification = NotificationCompat.Builder(applicationContext, COOLDOWN_ALERT_CHANNEL_ID)
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

        notificationManager?.notify(alert.notifId, notification)
    }

    // ── Notification channels ─────────────────────────────────────────────────

    private fun ensureAllNotifChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val activeChannel = NotificationChannel(
                FG_NOTIF_CHANNEL_ID,
                FG_NOTIF_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shows time remaining while a restricted app is in use"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }
            val idleChannel = NotificationChannel(
                FG_NOTIF_CHANNEL_IDLE_ID,
                FG_NOTIF_CHANNEL_IDLE_NAME,
                NotificationManager.IMPORTANCE_MIN,
            ).apply {
                description = "Required background service notification"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }
            val usageAlertChannel = NotificationChannel(
                ALERT_CHANNEL_ID,
                ALERT_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Alerts when the usage limit is almost reached"
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(true)
            }
            val cooldownAlertChannel = NotificationChannel(
                COOLDOWN_ALERT_CHANNEL_ID,
                COOLDOWN_ALERT_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Alerts when the cooldown period is almost over"
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(true)
            }

            notificationManager?.createNotificationChannel(activeChannel)
            notificationManager?.createNotificationChannel(idleChannel)
            notificationManager?.createNotificationChannel(usageAlertChannel)
            notificationManager?.createNotificationChannel(cooldownAlertChannel)
        }
    }

    // ── Foreground notification ───────────────────────────────────────────────

    private fun buildFgNotification(): Notification {
        val tapIntent = Intent(applicationContext, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK
                    or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                    or Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
        }
        val pi = PendingIntent.getActivity(
            applicationContext, 0, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val (title, body) = when {
            isBlocked -> {
                if (cooldownNotifEnabled) {
                    val h = cooldownRemSecs / 3600
                    val m = (cooldownRemSecs % 3600) / 60
                    val s = cooldownRemSecs % 60
                    "Cooldown — apps locked" to String.format("%02d:%02d:%02d", h, m, s)
                } else {
                    "StudyMentor is running..." to ""
                }
            }
            monitoredInForeground -> {
                if (timerNotifEnabled) {
                    val rem = (usageLimitSecs - totalUsageSecs).coerceAtLeast(0)
                    val h = rem / 3600
                    val m = (rem % 3600) / 60
                    val s = rem % 60
                    "Time remaining" to String.format("%02d:%02d:%02d", h, m, s)
                } else {
                    "StudyMentor is running..." to ""
                }
            }
            else -> "StudyMentor is running..." to ""
        }

        val channelId = if (!isBlocked && !monitoredInForeground)
            FG_NOTIF_CHANNEL_IDLE_ID
        else
            FG_NOTIF_CHANNEL_ID

        return NotificationCompat.Builder(applicationContext, channelId)
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setPriority(
                if (!isBlocked && !monitoredInForeground)
                    NotificationCompat.PRIORITY_MIN
                else
                    NotificationCompat.PRIORITY_LOW,
            )
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .setContentIntent(pi)
            .build()
    }

    private fun startForegroundWithNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                FG_NOTIF_ID,
                buildFgNotification(),
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(FG_NOTIF_ID, buildFgNotification())
        }
    }

    private fun updateFgNotification() {
        notificationManager?.notify(FG_NOTIF_ID, buildFgNotification())
    }

    // ── Foreground app detection ──────────────────────────────────────────────

    private fun getForegroundPackage(): String? {
        val usm = getSystemService(USAGE_STATS_SERVICE)
            as? android.app.usage.UsageStatsManager ?: return null
        val now    = System.currentTimeMillis()
        val events = usm.queryEvents(now - 300_000L, now)
        var lastPkg: String? = null
        var lastTime = 0L
        val event = android.app.usage.UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND
                && event.timeStamp > lastTime) {
                lastTime = event.timeStamp
                lastPkg  = event.packageName
            }
        }
        return lastPkg
    }

    // ── State persistence ─────────────────────────────────────────────────────

    private fun restoreState() {
        totalUsageSecs           = prefs.getInt(KEY_TOTAL_USAGE, 0)
        isBlocked                = prefs.getBoolean(KEY_IS_BLOCKED, false)
        cooldownRemSecs          = prefs.getInt(KEY_COOLDOWN_REMAINING, 0)
        usageLimitSecs           = prefs.getInt(KEY_USAGE_LIMIT, 1800)
        cooldownLimitSecs        = prefs.getInt(KEY_COOLDOWN_LIMIT, 600)
        studentLoggedIn          = prefs.getBoolean(KEY_STUDENT_LOGGED_IN, false)
        monitoredApps            = prefs.getStringSet(KEY_MONITORED_APPS, emptySet())
                                       ?.toMutableSet() ?: mutableSetOf()
        timerNotifEnabled        = prefs.getBoolean(KEY_TIMER_NOTIF_ENABLED, true)
        cooldownNotifEnabled     = prefs.getBoolean(KEY_COOLDOWN_NOTIF_ENABLED, true)
        quizDismissedForCooldown = prefs.getBoolean(KEY_QUIZ_DISMISSED, false)
        quizShownForCooldown     = prefs.getBoolean(KEY_QUIZ_SHOWN, false)

        if (isBlocked) {
            StudyMentorAccessibilityService.isBlocked = true
            // Also ensure the shared prefs flag is in sync in case it was somehow
            // out of step (e.g. a crash between persistState and the AppPrefs write).
            applicationContext
                .getSharedPreferences(AppPrefs.PREFS_NAME, Context.MODE_PRIVATE)
                .edit().putBoolean(AppPrefs.KEY_IS_BLOCKED, true).apply()
        }
    }

    private fun persistState() {
        prefs.edit()
            .putInt(KEY_TOTAL_USAGE, totalUsageSecs)
            .putBoolean(KEY_IS_BLOCKED, isBlocked)
            .putInt(KEY_COOLDOWN_REMAINING, cooldownRemSecs)
            .putInt(KEY_USAGE_LIMIT, usageLimitSecs)
            .putInt(KEY_COOLDOWN_LIMIT, cooldownLimitSecs)
            .putBoolean(KEY_STUDENT_LOGGED_IN, studentLoggedIn)
            .putBoolean(KEY_QUIZ_DISMISSED, quizDismissedForCooldown)
            .putBoolean(KEY_QUIZ_SHOWN, quizShownForCooldown)
            .apply()
        saveMonitoredApps()
    }

    private fun saveMonitoredApps() {
        prefs.edit().putStringSet(KEY_MONITORED_APPS, monitoredApps).apply()
    }

    // ── Broadcast ─────────────────────────────────────────────────────────────

    private fun broadcastState(
        thresholdAlert: Int,
        limitReached: Boolean = false,
        monitoredInForeground: Boolean = false,
    ) {
        val intent = Intent(BROADCAST_STATE_UPDATE).apply {
            putExtra(EXTRA_TOTAL_USAGE,     totalUsageSecs)
            putExtra(EXTRA_IS_BLOCKED,      isBlocked)
            putExtra(EXTRA_COOLDOWN_REM,    cooldownRemSecs)
            putExtra(EXTRA_THRESHOLD_ALERT, thresholdAlert)
            putExtra(EXTRA_MONITORED_IN_FG, monitoredInForeground)
            putExtra("limit_reached",       limitReached)
            setPackage(packageName)
        }
        sendBroadcast(intent)
    }

    // ── Public accessors ──────────────────────────────────────────────────────

    fun getTotalUsageSecs()          = totalUsageSecs
    fun getIsBlocked()               = isBlocked
    fun getCooldownRemSecs()         = cooldownRemSecs
    fun getUsageLimitSecs()          = usageLimitSecs
    fun getQuizDismissed()           = quizDismissedForCooldown
    fun getQuizShown()               = quizShownForCooldown

    fun setTimerNotifEnabled(enabled: Boolean) {
        timerNotifEnabled = enabled
        prefs.edit().putBoolean(KEY_TIMER_NOTIF_ENABLED, enabled).apply()
        updateFgNotification()
    }

    fun setCooldownNotifEnabled(enabled: Boolean) {
        cooldownNotifEnabled = enabled
        prefs.edit().putBoolean(KEY_COOLDOWN_NOTIF_ENABLED, enabled).apply()
        updateFgNotification()
    }
}