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
 * ┌─────────────────────────────────────────────────────────────────────────┐
 * │  Per-student timer state (keyed by UID — never shared across accounts) │
 * │    • <uid>_total_usage_seconds     – cumulative restricted usage        │
 * │    • <uid>_is_blocked              – in cooldown?                       │
 * │    • <uid>_cooldown_remaining_secs – seconds left in cooldown           │
 * │    • <uid>_quiz_dismissed          – student dismissed quiz?            │
 * │    • <uid>_quiz_shown              – quiz shown at least once?          │
 * │    • <uid>_usage_limit_seconds     – configured usage cap               │
 * │    • <uid>_cooldown_limit_seconds  – configured cooldown length         │
 * │    • <uid>_monitored_apps          – set of monitored package names     │
 * ├─────────────────────────────────────────────────────────────────────────┤
 * │  Device-wide keys (NOT prefixed — shared by all accounts on device)    │
 * │    • active_student_uid            – UID currently running the timer    │
 * │    • student_logged_in             – is any student logged in?          │
 * │    • timer_notification_enabled    – user preference                    │
 * │    • cooldown_notification_enabled – user preference                    │
 * └─────────────────────────────────────────────────────────────────────────┘
 *
 * When ACTION_START is received:
 *  - If the incoming UID differs from activeStudentUid, we load the incoming
 *    student's previously saved state (if any). The previous student's state
 *    is already fully persisted (written on every tick), so nothing is lost.
 *    Nothing is ever wiped: each student's data lives under its own key prefix.
 *
 * Compatibility: Android 8 (API 26) – Android 15+ (API 35).
 */
class UsageTimerService : Service() {

    companion object {
        // ── Intent actions ────────────────────────────────────────────────────
        const val ACTION_START   = "ACTION_START_TIMER"
        const val ACTION_STOP    = "ACTION_STOP_TIMER"
        const val ACTION_UNBLOCK = "ACTION_UNBLOCK"

        // ── Intent extras ─────────────────────────────────────────────────────
        const val EXTRA_MONITORED_APPS      = "EXTRA_MONITORED_APPS"
        const val EXTRA_USAGE_LIMIT_SECS    = "EXTRA_USAGE_LIMIT_SECS"
        const val EXTRA_COOLDOWN_LIMIT_SECS = "EXTRA_COOLDOWN_LIMIT_SECS"
        const val EXTRA_STUDENT_LOGGED_IN   = "EXTRA_STUDENT_LOGGED_IN"
        const val EXTRA_STUDENT_UID         = "EXTRA_STUDENT_UID"
        const val EXTRA_QUIZ_ON_LAUNCH      = "EXTRA_QUIZ_ON_LAUNCH"

        // ── Foreground service notification channels ───────────────────────────
        private const val FG_NOTIF_CHANNEL_ID        = "studymentor_timer_service"
        private const val FG_NOTIF_CHANNEL_NAME      = "StudyMentor Timer"
        private const val FG_NOTIF_CHANNEL_IDLE_ID   = "studymentor_timer_idle"
        private const val FG_NOTIF_CHANNEL_IDLE_NAME = "StudyMentor"
        private const val FG_NOTIF_ID                = 8001

        // ── Threshold alert notification channels ──────────────────────────────
        private const val ALERT_CHANNEL_ID            = "studymentor_usage_alerts"
        private const val ALERT_CHANNEL_NAME          = "Usage Alerts"
        private const val COOLDOWN_ALERT_CHANNEL_ID   = "studymentor_cooldown_alerts"
        private const val COOLDOWN_ALERT_CHANNEL_NAME = "Cooldown Alerts"

        // ── Notification IDs ───────────────────────────────────────────────────
        private const val ALERT_NOTIF_ID_5MIN          = 7002
        private const val ALERT_NOTIF_ID_1MIN          = 7003
        private const val ALERT_NOTIF_ID_10S           = 7004
        private const val COOLDOWN_ALERT_NOTIF_ID_5MIN = 7006
        private const val COOLDOWN_ALERT_NOTIF_ID_1MIN = 7007
        private const val COOLDOWN_ALERT_NOTIF_ID_10S  = 7008

        // ── SharedPreferences file ─────────────────────────────────────────────
        private const val PREFS_NAME = "studymentor_timer_prefs"

        // ── Device-wide keys (NOT prefixed with UID) ───────────────────────────
        private const val KEY_ACTIVE_STUDENT_UID = "active_student_uid"
        private const val KEY_STUDENT_LOGGED_IN  = "student_logged_in"
        const val KEY_TIMER_NOTIF_ENABLED        = "timer_notification_enabled"
        const val KEY_COOLDOWN_NOTIF_ENABLED     = "cooldown_notification_enabled"
        private const val KEY_STUDENT_UID        = "student_uid"

        // ── Per-student key suffixes ───────────────────────────────────────────
        // Never read these raw — always go through studentKey(uid, SUFFIX_*).
        private const val SUFFIX_TOTAL_USAGE        = "total_usage_seconds"
        private const val SUFFIX_IS_BLOCKED         = "is_blocked"
        private const val SUFFIX_COOLDOWN_REMAINING = "cooldown_remaining_seconds"
        private const val SUFFIX_USAGE_LIMIT        = "usage_limit_seconds"
        private const val SUFFIX_COOLDOWN_LIMIT     = "cooldown_limit_seconds"
        private const val SUFFIX_MONITORED_APPS     = "monitored_apps"
        private const val SUFFIX_QUIZ_DISMISSED     = "quiz_dismissed_for_cooldown"
        private const val SUFFIX_QUIZ_SHOWN         = "quiz_shown_for_cooldown"

        // Public aliases kept for TimerServiceBridge compatibility.
        // Bridge calls prefs(context) then reads quiz state; it now needs to
        // pair these suffixes with the active UID via studentKey().
        const val KEY_QUIZ_DISMISSED = SUFFIX_QUIZ_DISMISSED
        const val KEY_QUIZ_SHOWN     = SUFFIX_QUIZ_SHOWN

        // ── Broadcast action & extras ──────────────────────────────────────────
        const val BROADCAST_STATE_UPDATE = "com.example.studymentor.TIMER_STATE_UPDATE"
        const val EXTRA_TOTAL_USAGE      = "total_usage"
        const val EXTRA_IS_BLOCKED       = "is_blocked"
        const val EXTRA_COOLDOWN_REM     = "cooldown_remaining"
        const val EXTRA_THRESHOLD_ALERT  = "threshold_alert_seconds"
        const val EXTRA_MONITORED_IN_FG  = "monitored_in_foreground"

        // ── Helpers ────────────────────────────────────────────────────────────

        /**
         * Builds the per-student SharedPreferences key for [suffix] scoped to
         * [uid]. Falls back to the bare suffix when uid is blank so reads still
         * return a defined default rather than an unexpected crash.
         */
        fun studentKey(uid: String, suffix: String): String =
            if (uid.isBlank()) suffix else "${uid}_${suffix}"

        /** Returns the SharedPreferences file used by this service. */
        fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        /**
         * Returns the currently active student UID stored in prefs, or "".
         * Useful for callers (e.g. TimerServiceBridge) that need the UID to
         * build per-student keys without holding a reference to the running
         * service.
         */
        fun activeUid(context: Context): String =
            prefs(context).getString(KEY_ACTIVE_STUDENT_UID, "") ?: ""
    }

    // ── Binder ────────────────────────────────────────────────────────────────

    inner class LocalBinder : Binder() {
        fun getService(): UsageTimerService = this@UsageTimerService
    }

    private val binder = LocalBinder()
    override fun onBind(intent: Intent?): IBinder = binder

    // ── In-memory state ───────────────────────────────────────────────────────

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
    private var studentUid            = ""

    /** UID of the student whose timer state is currently loaded in memory. */
    private var activeStudentUid = ""

    // ── Quiz state ────────────────────────────────────────────────────────────

    private var quizDismissedForCooldown = false
    private var quizShownForCooldown     = false

    // One-shot threshold alert tracking (reset on unblock / account switch)
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

        // Restore the previously active student's state so the service is
        // immediately ready if the OS restarts it after a kill.
        val savedUid = prefs.getString(KEY_ACTIVE_STUDENT_UID, "") ?: ""
        if (savedUid.isNotEmpty()) {
            activeStudentUid = savedUid
            restoreStudentState(savedUid)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val incomingUid = intent.getStringExtra(EXTRA_STUDENT_UID).orEmpty()

                if (incomingUid.isNotEmpty() && incomingUid != activeStudentUid) {
                    // ── Account switch ─────────────────────────────────────────
                    // The outgoing student's state is already fully persisted
                    // (written on every tick and on block/unblock), so we can
                    // switch immediately without any extra save step.
                    // Load the incoming student's own previously saved state.
                    // restoreStudentState() unconditionally syncs both
                    // AppPrefs.KEY_IS_BLOCKED and
                    // StudyMentorAccessibilityService.isBlocked to match the
                    // incoming student's actual cooldown state, so no stale
                    // block from the outgoing account leaks into this session.
                    activeStudentUid = incomingUid
                    prefs.edit().putString(KEY_ACTIVE_STUDENT_UID, incomingUid).apply()
                    restoreStudentState(incomingUid)
                    firedUsageThresholds.clear()
                    firedCooldownThresholds.clear()
                }

                // Apply config overrides from the intent (always wins over
                // saved state so the parent's latest settings take effect).
                intent.getStringArrayListExtra(EXTRA_MONITORED_APPS)?.let {
                    monitoredApps = it.toMutableSet()
                    saveMonitoredApps()
                }
                intent.getIntExtra(EXTRA_USAGE_LIMIT_SECS, -1).takeIf { it >= 0 }?.let {
                    usageLimitSecs = it
                    prefs.edit()
                        .putInt(studentKey(activeStudentUid, SUFFIX_USAGE_LIMIT), it)
                        .apply()
                }
                intent.getIntExtra(EXTRA_COOLDOWN_LIMIT_SECS, -1).takeIf { it >= 0 }?.let {
                    cooldownLimitSecs = it
                    prefs.edit()
                        .putInt(studentKey(activeStudentUid, SUFFIX_COOLDOWN_LIMIT), it)
                        .apply()
                }

                studentLoggedIn = intent.getBooleanExtra(EXTRA_STUDENT_LOGGED_IN, true)
                prefs.edit().putBoolean(KEY_STUDENT_LOGGED_IN, studentLoggedIn).apply()
                intent.getStringExtra(EXTRA_STUDENT_UID)?.let {
                    if (it.isNotEmpty()) {
                        studentUid = it
                        prefs.edit().putString(KEY_STUDENT_UID, it).apply()
                    }
                }

                startForegroundWithNotification()
                if (!isRunning) {
                    isRunning = true
                    handler.post(tickRunnable)
                }
            }

            ACTION_STOP -> stopSelf()

            ACTION_UNBLOCK -> unblock()

            null -> {
                // Restarted by OS after kill — state already restored in onCreate().
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

        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val pausedAppsValue = flutterPrefs.all["flutter.paused_packages_$studentUid"]
        val isPaused = foreground != null && when (pausedAppsValue) {
            is Set<*> -> pausedAppsValue.contains(foreground)
            is List<*> -> pausedAppsValue.contains(foreground)
            is Collection<*> -> pausedAppsValue.contains(foreground)
            is String -> pausedAppsValue.contains("\"$foreground\"") || pausedAppsValue.contains(foreground)
            else -> false
        }
        val isForegroundMonitored = foreground != null && monitoredApps.contains(foreground) && !isPaused

        if (isBlocked) {
            // ── Cooldown countdown ─────────────────────────────────────────────
            if (cooldownRemSecs > 0) {
                cooldownRemSecs--
                thresholdAlert = checkCooldownThreshold(cooldownRemSecs)
                if (thresholdAlert >= 0) postCooldownThresholdAlert(thresholdAlert)
            }
            if (cooldownRemSecs <= 0) {
                unblock()
                return
            }

            if (isForegroundMonitored) {
                StudyMentorAccessibilityService.instance?.performGlobalAction(
                    android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_HOME,
                )
                OverlayPlugin.instance?.notifyMonitoredAppIntercepted(foreground!!)
            }

        } else {
            // ── Usage accumulation ─────────────────────────────────────────────
            if (isForegroundMonitored) {
                totalUsageSecs++
                val remaining = (usageLimitSecs - totalUsageSecs).coerceAtLeast(0)
                thresholdAlert = checkUsageThreshold(remaining)
                if (thresholdAlert >= 0) postUsageThresholdAlert(thresholdAlert)

                if (totalUsageSecs >= usageLimitSecs) {
                    block()
                    return
                }
            }
        }

        monitoredInForeground = !isBlocked && isForegroundMonitored

        persistState()
        broadcastState(thresholdAlert, monitoredInForeground = monitoredInForeground)
        updateFgNotification()
    }

    // ── Block / unblock ───────────────────────────────────────────────────────

    private fun block() {
        isBlocked                = true
        cooldownRemSecs          = cooldownLimitSecs
        quizDismissedForCooldown = false
        quizShownForCooldown     = false
        firedUsageThresholds.clear()
        StudyMentorAccessibilityService.isBlocked = true

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
        quizDismissedForCooldown = false
        quizShownForCooldown     = false
        firedUsageThresholds.clear()
        firedCooldownThresholds.clear()
        StudyMentorAccessibilityService.isBlocked = false

        applicationContext
            .getSharedPreferences(AppPrefs.PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putBoolean(AppPrefs.KEY_IS_BLOCKED, false).apply()

        persistState()
        broadcastState(-1)
        updateFgNotification()
    }

    // ── Quiz dismissed flag — public setters ──────────────────────────────────

    fun setQuizDismissed(dismissed: Boolean) {
        quizDismissedForCooldown = dismissed
        if (dismissed) quizShownForCooldown = true
        prefs.edit()
            .putBoolean(studentKey(activeStudentUid, SUFFIX_QUIZ_DISMISSED), quizDismissedForCooldown)
            .putBoolean(studentKey(activeStudentUid, SUFFIX_QUIZ_SHOWN), quizShownForCooldown)
            .apply()
    }

    fun markQuizShown() {
        quizShownForCooldown = true
        prefs.edit()
            .putBoolean(studentKey(activeStudentUid, SUFFIX_QUIZ_SHOWN), true)
            .apply()
    }

    // ── Threshold helpers ─────────────────────────────────────────────────────

    private fun checkUsageThreshold(remaining: Int): Int {
        for (t in listOf(300, 60, 10)) {
            if (!firedUsageThresholds.contains(t) && remaining == t) {
                firedUsageThresholds.add(t)
                return remaining
            }
        }
        return -1
    }

    private fun checkCooldownThreshold(remaining: Int): Int {
        for (t in listOf(300, 60, 10)) {
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
            .setContentTitle(alert.title).setContentText(alert.body)
            .setOngoing(false).setAutoCancel(true)
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
            .setContentTitle(alert.title).setContentText(alert.body)
            .setOngoing(false).setAutoCancel(true)
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
                FG_NOTIF_CHANNEL_ID, FG_NOTIF_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shows time remaining while a restricted app is in use"
                setShowBadge(false); setSound(null, null); enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }
            val idleChannel = NotificationChannel(
                FG_NOTIF_CHANNEL_IDLE_ID, FG_NOTIF_CHANNEL_IDLE_NAME,
                NotificationManager.IMPORTANCE_MIN,
            ).apply {
                description = "Required background service notification"
                setShowBadge(false); setSound(null, null); enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }
            val usageAlertChannel = NotificationChannel(
                ALERT_CHANNEL_ID, ALERT_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Alerts when the usage limit is almost reached"
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(true)
            }
            val cooldownAlertChannel = NotificationChannel(
                COOLDOWN_ALERT_CHANNEL_ID, COOLDOWN_ALERT_CHANNEL_NAME,
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
                } else "StudyMentor is running..." to ""
            }
            monitoredInForeground -> {
                if (timerNotifEnabled) {
                    val rem = (usageLimitSecs - totalUsageSecs).coerceAtLeast(0)
                    val h = rem / 3600; val m = (rem % 3600) / 60; val s = rem % 60
                    "Time remaining" to String.format("%02d:%02d:%02d", h, m, s)
                } else "StudyMentor is running..." to ""
            }
            else -> "StudyMentor is running..." to ""
        }

        val channelId = if (!isBlocked && !monitoredInForeground)
            FG_NOTIF_CHANNEL_IDLE_ID else FG_NOTIF_CHANNEL_ID

        return NotificationCompat.Builder(applicationContext, channelId)
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setContentTitle(title).setContentText(body)
            .setOngoing(true).setOnlyAlertOnce(true).setSilent(true)
            .setPriority(
                if (!isBlocked && !monitoredInForeground)
                    NotificationCompat.PRIORITY_MIN
                else NotificationCompat.PRIORITY_LOW,
            )
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .setContentIntent(pi).build()
    }

    private fun startForegroundWithNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                FG_NOTIF_ID, buildFgNotification(),
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

    /**
     * Loads all per-student timer counters from SharedPreferences for [uid].
     *
     * Called on service start (onCreate) to recover the previously active
     * student, and on account switch to load the incoming student's own saved
     * data. Config values (limits, monitored apps) are loaded too, but will be
     * overwritten by values arriving in the ACTION_START Intent right after.
     *
     * FIX: AppPrefs.KEY_IS_BLOCKED and StudyMentorAccessibilityService.isBlocked
     * are now set unconditionally to match the restored student's actual
     * cooldown state. Previously they were only set when isBlocked == true,
     * which meant that switching to an account that was NOT in cooldown left
     * both flags stale from the previous account's block() call, causing all
     * restricted apps to remain blocked for the newly logged-in account.
     */
    private fun restoreStudentState(uid: String) {
        totalUsageSecs           = prefs.getInt(studentKey(uid, SUFFIX_TOTAL_USAGE), 0)
        isBlocked                = prefs.getBoolean(studentKey(uid, SUFFIX_IS_BLOCKED), false)
        cooldownRemSecs          = prefs.getInt(studentKey(uid, SUFFIX_COOLDOWN_REMAINING), 0)
        usageLimitSecs           = prefs.getInt(studentKey(uid, SUFFIX_USAGE_LIMIT), 1800)
        cooldownLimitSecs        = prefs.getInt(studentKey(uid, SUFFIX_COOLDOWN_LIMIT), 600)
        monitoredApps            = prefs.getStringSet(studentKey(uid, SUFFIX_MONITORED_APPS), emptySet())
                                       ?.toMutableSet() ?: mutableSetOf()
        quizDismissedForCooldown = prefs.getBoolean(studentKey(uid, SUFFIX_QUIZ_DISMISSED), false)
        quizShownForCooldown     = prefs.getBoolean(studentKey(uid, SUFFIX_QUIZ_SHOWN), false)

        // Device-wide prefs (not per-student)
        studentLoggedIn      = prefs.getBoolean(KEY_STUDENT_LOGGED_IN, false)
        timerNotifEnabled    = prefs.getBoolean(KEY_TIMER_NOTIF_ENABLED, true)
        cooldownNotifEnabled = prefs.getBoolean(KEY_COOLDOWN_NOTIF_ENABLED, true)

        // Unconditionally sync the shared blocked flag and the in-memory
        // accessibility-service static to match the incoming student's actual
        // cooldown state. This clears any stale block left by the previous
        // account: if Account 1 was in cooldown and Account 2 is not,
        // isBlocked is now false and both flags are cleared immediately.
        StudyMentorAccessibilityService.isBlocked = isBlocked
        applicationContext
            .getSharedPreferences(AppPrefs.PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putBoolean(AppPrefs.KEY_IS_BLOCKED, isBlocked).apply()
    }

    /**
     * Writes all per-student timer counters to SharedPreferences under the
     * [activeStudentUid] prefix. Called on every tick and on block/unblock so
     * state survives process death or an unexpected account switch.
     */
    private fun persistState() {
        if (activeStudentUid.isBlank()) return // safety: no UID → nothing to persist
        prefs.edit()
            .putInt(studentKey(activeStudentUid, SUFFIX_TOTAL_USAGE),        totalUsageSecs)
            .putBoolean(studentKey(activeStudentUid, SUFFIX_IS_BLOCKED),     isBlocked)
            .putInt(studentKey(activeStudentUid, SUFFIX_COOLDOWN_REMAINING), cooldownRemSecs)
            .putInt(studentKey(activeStudentUid, SUFFIX_USAGE_LIMIT),        usageLimitSecs)
            .putInt(studentKey(activeStudentUid, SUFFIX_COOLDOWN_LIMIT),     cooldownLimitSecs)
            .putBoolean(studentKey(activeStudentUid, SUFFIX_QUIZ_DISMISSED), quizDismissedForCooldown)
            .putBoolean(studentKey(activeStudentUid, SUFFIX_QUIZ_SHOWN),     quizShownForCooldown)
            .putString(KEY_ACTIVE_STUDENT_UID, activeStudentUid)
            .apply()
        saveMonitoredApps()
    }

    private fun saveMonitoredApps() {
        if (activeStudentUid.isBlank()) return
        prefs.edit()
            .putStringSet(studentKey(activeStudentUid, SUFFIX_MONITORED_APPS), monitoredApps)
            .apply()
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

    fun getTotalUsageSecs()  = totalUsageSecs
    fun getIsBlocked()       = isBlocked
    fun getCooldownRemSecs() = cooldownRemSecs
    fun getUsageLimitSecs()  = usageLimitSecs
    fun getQuizDismissed()   = quizDismissedForCooldown
    fun getQuizShown()       = quizShownForCooldown

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