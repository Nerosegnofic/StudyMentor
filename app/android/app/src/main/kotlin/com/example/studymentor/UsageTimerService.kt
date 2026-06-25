package com.example.studymentor

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.os.Binder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import java.util.Locale

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
 * All notifications — foreground service persistent notification, usage/cooldown
 * countdown updates, and threshold alerts — are posted on the single CHILD_TIMER
 * channel ("CHILD_TIMER"), which is created and owned by LocalNotificationService
 * (flutter_local_notifications) during app startup. This service never creates
 * its own channels; it relies on the channel already existing by the time the
 * service starts.
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

        // ── Notification channel ──────────────────────────────────────────────
        //
        // All timer notifications share the single CHILD_TIMER channel, which is
        // created by LocalNotificationService.init() (flutter_local_notifications)
        // before the service ever starts. Do NOT create this channel here —
        // Android ignores duplicate createNotificationChannel calls, but keeping
        // a single owner avoids importance/sound setting conflicts.
        private const val CHILD_TIMER_CHANNEL_ID = "CHILD_TIMER"

        // ── Foreground service notification ID ────────────────────────────────
        private const val FG_NOTIF_ID = 8001

        // ── Threshold alert notification IDs ──────────────────────────────────
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
        const val KEY_STUDENT_LOGGED_IN          = "student_logged_in"
        const val KEY_TIMER_NOTIF_ENABLED        = "timer_notification_enabled"
        const val KEY_COOLDOWN_NOTIF_ENABLED     = "cooldown_notification_enabled"
        private const val KEY_STUDENT_UID        = "student_uid"

        // ── Quiz lock ─────────────────────────────────────────────────────────
        // Device-wide (not per-student): only one quiz can be locked at a time.
        const val KEY_QUIZ_LOCK_ACTIVE   = "quiz_lock_active"
        const val EXTRA_QUIZ_RESTORE     = "EXTRA_QUIZ_RESTORE"

        // ── Per-student key suffixes ───────────────────────────────────────────
        private const val SUFFIX_TOTAL_USAGE        = "total_usage_seconds"
        private const val SUFFIX_IS_BLOCKED         = "is_blocked"
        private const val SUFFIX_COOLDOWN_REMAINING = "cooldown_remaining_seconds"
        private const val SUFFIX_USAGE_LIMIT        = "usage_limit_seconds"
        private const val SUFFIX_COOLDOWN_LIMIT     = "cooldown_limit_seconds"
        private const val SUFFIX_MONITORED_APPS     = "monitored_apps"
        private const val SUFFIX_QUIZ_DISMISSED     = "quiz_dismissed_for_cooldown"
        private const val SUFFIX_QUIZ_SHOWN         = "quiz_shown_for_cooldown"

        // Public aliases kept for TimerServiceBridge compatibility.
        const val KEY_QUIZ_DISMISSED = SUFFIX_QUIZ_DISMISSED
        const val KEY_QUIZ_SHOWN     = SUFFIX_QUIZ_SHOWN

        // ── Broadcast action & extras ──────────────────────────────────────────
        const val BROADCAST_STATE_UPDATE = "com.example.studymentor.TIMER_STATE_UPDATE"
        const val EXTRA_TOTAL_USAGE      = "total_usage"
        const val EXTRA_IS_BLOCKED       = "is_blocked"
        const val EXTRA_COOLDOWN_REM     = "cooldown_remaining"
        const val EXTRA_THRESHOLD_ALERT  = "threshold_alert_seconds"
        const val EXTRA_MONITORED_IN_FG  = "monitored_in_foreground"
        const val EXTRA_UNBLOCKED        = "unblocked"

        // ── Helpers ────────────────────────────────────────────────────────────

        fun studentKey(uid: String, suffix: String): String =
            if (uid.isBlank()) suffix else "${uid}_${suffix}"

        fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

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

    private var activeStudentUid = ""

    // Timestamp of the last block() call. Used to suppress GLOBAL_ACTION_HOME
    // for a short window after blocking, because UsageStatsManager on some OEMs
    // (Xiaomi/Realme) returns stale foreground data for several seconds after an
    // app switch, which would otherwise cause tick() to fire home and close
    // StudyMentor immediately after it's launched.
    private var blockTimestampMs = 0L
    private val BLOCK_GRACE_MS   = 3_000L

    // ── Quiz lock state ───────────────────────────────────────────────────────
    // True while the student has an active quiz session. When true the service
    // brings StudyMentor to the foreground whenever it detects that another app
    // is in front, and relaunches it (with EXTRA_QUIZ_RESTORE) on task removal.

    private var quizLockActive     = false
    // Timestamp of setQuizLockActive(true); used for a short grace period so we
    // do not immediately force-foreground while the quiz screen is still animating in.
    private var quizLockActivatedMs = 0L
    private val QUIZ_LOCK_GRACE_MS  = 4_000L

    // ── Quiz state ────────────────────────────────────────────────────────────

    private var quizDismissedForCooldown = false
    private var quizShownForCooldown     = false

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
        // No channel creation here — CHILD_TIMER is created by
        // LocalNotificationService.init() before this service ever starts.

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
                    activeStudentUid = incomingUid
                    prefs.edit().putString(KEY_ACTIVE_STUDENT_UID, incomingUid).apply()
                    restoreStudentState(incomingUid)
                    firedUsageThresholds.clear()
                    firedCooldownThresholds.clear()
                }

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
            if (cooldownRemSecs > 0) {
                cooldownRemSecs--
                thresholdAlert = checkCooldownThreshold(cooldownRemSecs)
                if (thresholdAlert >= 0) postCooldownThresholdAlert(thresholdAlert)
            }
            if (cooldownRemSecs <= 0) {
                unblock()
                return
            }

            val inGracePeriod = System.currentTimeMillis() - blockTimestampMs < BLOCK_GRACE_MS
            if (isForegroundMonitored && !inGracePeriod) {
                StudyMentorAccessibilityService.instance?.performGlobalAction(
                    android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_HOME,
                )
                OverlayPlugin.instance?.notifyMonitoredAppIntercepted(foreground!!)
            }

        } else {
            if (foreground != null && monitoredApps.contains(foreground) && usageLimitSecs > 0) {
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

        // Quiz lock enforcement backup: the Dart-side AppLifecycleState.paused
        // handler is the primary mechanism (immediate, no OEM delay). This tick
        // check is a secondary fallback for cases where the Dart engine cannot
        // call bringAppToForeground (e.g. engine suspended by the OS).
        // Also reads from prefs to catch the case where setQuizLockActive was
        // called via the prefs-fallback path (binder was not yet connected).
        val effectiveQuizLock = quizLockActive || prefs.getBoolean(KEY_QUIZ_LOCK_ACTIVE, false)
        if (effectiveQuizLock) {
            if (!quizLockActive) {
                quizLockActive = true
                quizLockActivatedMs = System.currentTimeMillis()
            }
            val ownPkg = applicationContext.packageName
            val inGrace = System.currentTimeMillis() - quizLockActivatedMs < QUIZ_LOCK_GRACE_MS
            if (!inGrace && foreground != null && foreground != ownPkg) {
                applicationContext.startActivity(
                    Intent(applicationContext, MainActivity::class.java).apply {
                        addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK
                                or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                                or Intent.FLAG_ACTIVITY_SINGLE_TOP,
                        )
                    }
                )
            }
        }

        persistState()
        broadcastState(thresholdAlert, monitoredInForeground = monitoredInForeground)
        updateFgNotification()
    }

    // Relaunches the app with EXTRA_QUIZ_RESTORE when the student swipes it
    // away from the recents screen while a quiz is active. The service itself
    // continues running (stopWithTask="false") and START_STICKY restarts it.
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        if (quizLockActive || prefs.getBoolean(KEY_QUIZ_LOCK_ACTIVE, false)) {
            applicationContext.startActivity(
                Intent(applicationContext, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    putExtra(EXTRA_QUIZ_RESTORE, true)
                }
            )
        }
    }

    // ── Block / unblock ───────────────────────────────────────────────────────

    private fun block() {
        blockTimestampMs         = System.currentTimeMillis()
        isBlocked                = true
        cooldownRemSecs          = cooldownLimitSecs
        quizDismissedForCooldown = false
        quizShownForCooldown     = false
        firedUsageThresholds.clear()
        StudyMentorAccessibilityService.isBlocked = true

        // Zero the Flutter-side earned-reward pref before broadcasting, so that
        // if Dart is suspended/killed before _onLimitReached() persists the reset,
        // a cold restart still sees 0 instead of the stale pre-cooldown balance.
        // Quizzes solved during cooldown call addRewardTime() which persists the
        // new positive value on top of this zero, so those are not affected.
        if (activeStudentUid.isNotEmpty()) {
            getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putInt("flutter.reward_earned_$activeStudentUid", 0)
                .apply()
        }

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
        // Do NOT set StudyMentorAccessibilityService.isBlocked = false here.
        // The Dart side decides whether to actually unblock based on earned
        // reward seconds — it will call setBlocked(false) if appropriate.

        applicationContext
            .getSharedPreferences(AppPrefs.PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putBoolean(AppPrefs.KEY_IS_BLOCKED, false).apply()

        persistState()
        broadcastState(-1, unblocked = true)
        updateFgNotification()
    }

    // ── Quiz dismissed flag ───────────────────────────────────────────────────

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
    //
    // Both usage and cooldown alerts post on CHILD_TIMER. The channel has
    // HIGH importance and sound=true (set by LocalNotificationService), so
    // these will vibrate and play the default sound — correct for alerts.

    /**
     * Returns a [Context] whose locale matches the language the user chose
     * inside the Flutter app (persisted at `flutter.app_locale_code` in
     * FlutterSharedPreferences). Falls back to English when the key is absent.
     * Pass this context to [Context.getString] so notification text is shown
     * in the correct language regardless of the device's system locale.
     */
    private fun localizedContext(): Context {
        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val langCode = flutterPrefs.getString("flutter.app_locale_code", "en") ?: "en"
        val locale = Locale(langCode)
        val config = Configuration(resources.configuration)
        config.setLocale(locale)
        return createConfigurationContext(config)
    }

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
        data class AlertInfo(val notifId: Int, val titleRes: Int, val bodyRes: Int)
        val alert = when {
            remainingSeconds >= 270 -> AlertInfo(
                ALERT_NOTIF_ID_5MIN,
                R.string.notif_usage_5min_title,
                R.string.notif_usage_5min_body,
            )
            remainingSeconds >= 45 -> AlertInfo(
                ALERT_NOTIF_ID_1MIN,
                R.string.notif_usage_1min_title,
                R.string.notif_usage_1min_body,
            )
            else -> AlertInfo(
                ALERT_NOTIF_ID_10S,
                R.string.notif_usage_10sec_title,
                R.string.notif_usage_10sec_body,
            )
        }
        val ctx = localizedContext()
        val notification = NotificationCompat.Builder(applicationContext, CHILD_TIMER_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(ctx.getString(alert.titleRes))
            .setContentText(ctx.getString(alert.bodyRes))
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
        data class AlertInfo(val notifId: Int, val titleRes: Int, val bodyRes: Int)
        val alert = when {
            remainingSeconds >= 270 -> AlertInfo(
                COOLDOWN_ALERT_NOTIF_ID_5MIN,
                R.string.notif_cooldown_5min_title,
                R.string.notif_cooldown_5min_body,
            )
            remainingSeconds >= 45 -> AlertInfo(
                COOLDOWN_ALERT_NOTIF_ID_1MIN,
                R.string.notif_cooldown_1min_title,
                R.string.notif_cooldown_1min_body,
            )
            else -> AlertInfo(
                COOLDOWN_ALERT_NOTIF_ID_10S,
                R.string.notif_cooldown_10sec_title,
                R.string.notif_cooldown_10sec_body,
            )
        }
        val ctx = localizedContext()
        val notification = NotificationCompat.Builder(applicationContext, CHILD_TIMER_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(ctx.getString(alert.titleRes))
            .setContentText(ctx.getString(alert.bodyRes))
            .setOngoing(false).setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setContentIntent(mainActivityPendingIntent(alert.notifId))
            .build()
        notificationManager?.notify(alert.notifId, notification)
    }

    // ── Foreground notification ───────────────────────────────────────────────
    //
    // The persistent foreground notification also uses CHILD_TIMER.
    // When the student is idle (no monitored app in foreground, not blocked)
    // we use PRIORITY_MIN + setSilent(true) to suppress sound/vibration even
    // though the channel itself has sound enabled. This matches the previous
    // two-channel approach (active = LOW importance, idle = MIN importance)
    // while using a single channel as required by the plan.

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

        val isIdle = !isBlocked && !monitoredInForeground
        val ctx = localizedContext()

        val (title, body) = when {
            isBlocked -> {
                if (cooldownNotifEnabled && cooldownRemSecs > 0) {
                    val h = cooldownRemSecs / 3600
                    val m = (cooldownRemSecs % 3600) / 60
                    val s = cooldownRemSecs % 60
                    ctx.getString(R.string.notif_cooldown_title) to
                        String.format("%02d:%02d:%02d", h, m, s)
                } else ctx.getString(R.string.notif_running) to ""
            }
            monitoredInForeground -> {
                if (timerNotifEnabled && usageLimitSecs > 0) {
                    val rem = (usageLimitSecs - totalUsageSecs).coerceAtLeast(0)
                    val h = rem / 3600; val m = (rem % 3600) / 60; val s = rem % 60
                    ctx.getString(R.string.notif_time_remaining) to
                        String.format("%02d:%02d:%02d", h, m, s)
                } else ctx.getString(R.string.notif_running) to ""
            }
            else -> ctx.getString(R.string.notif_running) to ""
        }

        return NotificationCompat.Builder(applicationContext, CHILD_TIMER_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setContentTitle(title).setContentText(body)
            .setOngoing(true).setOnlyAlertOnce(true).setSilent(true)
            .setPriority(
                if (isIdle) NotificationCompat.PRIORITY_MIN
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
        quizLockActive = prefs.getBoolean(KEY_QUIZ_LOCK_ACTIVE, false)
        if (quizLockActive) quizLockActivatedMs = System.currentTimeMillis()

        studentLoggedIn      = prefs.getBoolean(KEY_STUDENT_LOGGED_IN, false)
        timerNotifEnabled    = prefs.getBoolean(KEY_TIMER_NOTIF_ENABLED, true)
        cooldownNotifEnabled = prefs.getBoolean(KEY_COOLDOWN_NOTIF_ENABLED, true)

        // AppPrefs.KEY_IS_BLOCKED is the Dart-controlled "effective blocked" flag
        // and covers both cooldown AND zero-reward-time blocking. SUFFIX_IS_BLOCKED
        // only reflects cooldown state. Prefer AppPrefs as the source of truth so
        // restoring the service (e.g. on login or START_STICKY restart) does not
        // overwrite the value that Dart already set. Fall back to the native
        // cooldown flag only if Dart has never written the key (first-ever launch).
        val appPrefs = applicationContext
            .getSharedPreferences(AppPrefs.PREFS_NAME, Context.MODE_PRIVATE)
        val effectiveBlocked = if (appPrefs.contains(AppPrefs.KEY_IS_BLOCKED))
            appPrefs.getBoolean(AppPrefs.KEY_IS_BLOCKED, false)
        else
            isBlocked
        StudyMentorAccessibilityService.isBlocked = effectiveBlocked
        appPrefs.edit().putBoolean(AppPrefs.KEY_IS_BLOCKED, effectiveBlocked).apply()
    }

    private fun persistState() {
        if (activeStudentUid.isBlank()) return
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
        unblocked: Boolean = false,
    ) {
        val intent = Intent(BROADCAST_STATE_UPDATE).apply {
            putExtra(EXTRA_TOTAL_USAGE,     totalUsageSecs)
            putExtra(EXTRA_IS_BLOCKED,      isBlocked)
            putExtra(EXTRA_COOLDOWN_REM,    cooldownRemSecs)
            putExtra(EXTRA_THRESHOLD_ALERT, thresholdAlert)
            putExtra(EXTRA_MONITORED_IN_FG, monitoredInForeground)
            putExtra("limit_reached",       limitReached)
            putExtra(EXTRA_UNBLOCKED,       unblocked)
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

    fun setQuizLockActive(active: Boolean) {
        quizLockActive = active
        if (active) quizLockActivatedMs = System.currentTimeMillis()
        prefs.edit().putBoolean(KEY_QUIZ_LOCK_ACTIVE, active).apply()
    }

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