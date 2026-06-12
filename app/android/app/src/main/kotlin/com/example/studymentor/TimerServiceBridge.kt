package com.example.studymentor

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.ServiceConnection
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class TimerServiceBridge(private val activity: FlutterActivity) {

    companion object {
        const val CHANNEL = "com.example.studymentor/timer_service"
    }

    private var channel: MethodChannel? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // ── Service binding ───────────────────────────────────────────────────────

    private var timerService: UsageTimerService? = null
    private var serviceBound = false

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
            timerService = (binder as? UsageTimerService.LocalBinder)?.getService()
            serviceBound = true
        }
        override fun onServiceDisconnected(name: ComponentName?) {
            timerService = null
            serviceBound = false
        }
    }

    // ── Broadcast receiver ────────────────────────────────────────────────────

    private val stateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != UsageTimerService.BROADCAST_STATE_UPDATE) return

            val totalUsage    = intent.getIntExtra(UsageTimerService.EXTRA_TOTAL_USAGE, 0)
            val isBlocked     = intent.getBooleanExtra(UsageTimerService.EXTRA_IS_BLOCKED, false)
            val cooldownRem   = intent.getIntExtra(UsageTimerService.EXTRA_COOLDOWN_REM, 0)
            val alertSecs     = intent.getIntExtra(UsageTimerService.EXTRA_THRESHOLD_ALERT, -1)
            val limitReached  = intent.getBooleanExtra("limit_reached", false)
            val monitoredInFg = intent.getBooleanExtra(UsageTimerService.EXTRA_MONITORED_IN_FG, false)

            // Prefer the live bound service value; fall back to prefs using the
            // active UID so we always read the correct per-student key.
            val usageLimit = timerService?.getUsageLimitSecs() ?: run {
                val uid = UsageTimerService.activeUid(activity)
                UsageTimerService.prefs(activity)
                    .getInt(UsageTimerService.studentKey(uid, "usage_limit_seconds"), 1800)
            }

            mainHandler.post {
                if (limitReached) {
                    channel?.invokeMethod("onLimitReached", null)
                }
                if (alertSecs >= 0) {
                    channel?.invokeMethod(
                        "onThresholdAlert",
                        mapOf(
                            "remainingSeconds" to alertSecs,
                            "isCooldown"       to isBlocked,
                        ),
                    )
                }
                channel?.invokeMethod(
                    "onTimerTick",
                    mapOf(
                        "totalUsage"            to totalUsage,
                        "isBlocked"             to isBlocked,
                        "cooldownRemaining"     to cooldownRem,
                        "usageLimit"            to usageLimit,
                        "monitoredInForeground" to monitoredInFg,
                    ),
                )
            }
        }
    }

    // ── Registration ──────────────────────────────────────────────────────────

    fun registerWith(flutterEngine: FlutterEngine) {
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {

                    "startTimerService" -> {
                        val studentUid    = call.argument<String>("studentUid") ?: ""
                        val apps          = call.argument<List<String>>("monitoredApps") ?: emptyList()
                        val usageLimit    = call.argument<Int>("usageLimitSecs") ?: 1800
                        val cooldownLimit = call.argument<Int>("cooldownLimitSecs") ?: 600

                        val intent = serviceIntent(ACTION_START).apply {
                            putExtra(UsageTimerService.EXTRA_STUDENT_UID,         studentUid)
                            putStringArrayListExtra(
                                UsageTimerService.EXTRA_MONITORED_APPS,
                                ArrayList(apps),
                            )
                            putExtra(UsageTimerService.EXTRA_USAGE_LIMIT_SECS,    usageLimit)
                            putExtra(UsageTimerService.EXTRA_COOLDOWN_LIMIT_SECS, cooldownLimit)
                            putExtra(UsageTimerService.EXTRA_STUDENT_LOGGED_IN,   true)
                            putExtra(UsageTimerService.EXTRA_STUDENT_UID,         studentUid)
                        }
                        startService(intent)
                        bindService()
                        result.success(null)
                    }

                    "stopTimerService" -> {
                        // Mark the student as logged out (device-wide flag) but
                        // do NOT stop or reset the service — the timer must keep
                        // running so the cooldown/usage counts are intact on the
                        // next login.
                        val intent = serviceIntent(ACTION_START).apply {
                            putExtra(UsageTimerService.EXTRA_STUDENT_LOGGED_IN, false)
                        }
                        startService(intent)
                        startService(serviceIntent(ACTION_STOP))
                        unbindService()
                        result.success(null)
                    }

                    "unblockTimerService" -> {
                        timerService?.unblock()
                            ?: startService(serviceIntent(ACTION_UNBLOCK))
                        result.success(null)
                    }

                    "updateTimerConfig" -> {
                        val studentUid    = call.argument<String>("studentUid") ?: ""
                        val apps          = call.argument<List<String>>("monitoredApps") ?: emptyList()
                        val usageLimit    = call.argument<Int>("usageLimitSecs") ?: 1800
                        val cooldownLimit = call.argument<Int>("cooldownLimitSecs") ?: 600

                        val intent = serviceIntent(ACTION_START).apply {
                            putExtra(UsageTimerService.EXTRA_STUDENT_UID,         studentUid)
                            putStringArrayListExtra(
                                UsageTimerService.EXTRA_MONITORED_APPS,
                                ArrayList(apps),
                            )
                            putExtra(UsageTimerService.EXTRA_USAGE_LIMIT_SECS,    usageLimit)
                            putExtra(UsageTimerService.EXTRA_COOLDOWN_LIMIT_SECS, cooldownLimit)
                            putExtra(UsageTimerService.EXTRA_STUDENT_LOGGED_IN,   true)
                            putExtra(UsageTimerService.EXTRA_STUDENT_UID,         studentUid)
                        }
                        startService(intent)
                        result.success(null)
                    }

                    "getTimerState" -> {
                        // Prefer the bound service (always accurate). Fall back
                        // to SharedPreferences using the active UID prefix so we
                        // never read another student's values.
                        val svc = timerService
                        if (svc != null) {
                            result.success(
                                mapOf(
                                    "totalUsage"        to svc.getTotalUsageSecs(),
                                    "isBlocked"         to svc.getIsBlocked(),
                                    "cooldownRemaining" to svc.getCooldownRemSecs(),
                                    "usageLimit"        to svc.getUsageLimitSecs(),
                                    "quizDismissed"     to svc.getQuizDismissed(),
                                    "quizShown"         to svc.getQuizShown(),
                                ),
                            )
                        } else {
                            val uid   = UsageTimerService.activeUid(activity)
                            val prefs = UsageTimerService.prefs(activity)
                            result.success(
                                mapOf(
                                    "totalUsage"        to prefs.getInt(
                                        UsageTimerService.studentKey(uid, "total_usage_seconds"), 0),
                                    "isBlocked"         to prefs.getBoolean(
                                        UsageTimerService.studentKey(uid, "is_blocked"), false),
                                    "cooldownRemaining" to prefs.getInt(
                                        UsageTimerService.studentKey(uid, "cooldown_remaining_seconds"), 0),
                                    "usageLimit"        to prefs.getInt(
                                        UsageTimerService.studentKey(uid, "usage_limit_seconds"), 1800),
                                    "quizDismissed"     to prefs.getBoolean(
                                        UsageTimerService.studentKey(uid, UsageTimerService.KEY_QUIZ_DISMISSED), false),
                                    "quizShown"         to prefs.getBoolean(
                                        UsageTimerService.studentKey(uid, UsageTimerService.KEY_QUIZ_SHOWN), false),
                                ),
                            )
                        }
                    }

                    // ── Quiz state mutations ───────────────────────────────────

                    "setQuizDismissed" -> {
                        val dismissed = call.argument<Boolean>("dismissed") ?: false
                        // Update via the live service if bound (it writes prefs itself).
                        // Otherwise write directly to the per-student prefs key.
                        if (timerService != null) {
                            timerService!!.setQuizDismissed(dismissed)
                        } else {
                            val uid   = UsageTimerService.activeUid(activity)
                            val prefs = UsageTimerService.prefs(activity)
                            val quizShownKey     = UsageTimerService.studentKey(uid, UsageTimerService.KEY_QUIZ_SHOWN)
                            val quizDismissedKey = UsageTimerService.studentKey(uid, UsageTimerService.KEY_QUIZ_DISMISSED)
                            prefs.edit()
                                .putBoolean(quizDismissedKey, dismissed)
                                .putBoolean(
                                    quizShownKey,
                                    if (dismissed) true
                                    else prefs.getBoolean(quizShownKey, false),
                                )
                                .apply()
                        }
                        result.success(null)
                    }

                    "markQuizShown" -> {
                        if (timerService != null) {
                            timerService!!.markQuizShown()
                        } else {
                            val uid = UsageTimerService.activeUid(activity)
                            UsageTimerService.prefs(activity)
                                .edit()
                                .putBoolean(
                                    UsageTimerService.studentKey(uid, UsageTimerService.KEY_QUIZ_SHOWN),
                                    true,
                                )
                                .apply()
                        }
                        result.success(null)
                    }

                    "setTimerNotificationEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        UsageTimerService.prefs(activity)
                            .edit()
                            .putBoolean(UsageTimerService.KEY_TIMER_NOTIF_ENABLED, enabled)
                            .apply()
                        timerService?.setTimerNotifEnabled(enabled)
                        result.success(null)
                    }

                    "setCooldownNotificationEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        UsageTimerService.prefs(activity)
                            .edit()
                            .putBoolean(UsageTimerService.KEY_COOLDOWN_NOTIF_ENABLED, enabled)
                            .apply()
                        timerService?.setCooldownNotifEnabled(enabled)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
        }

        val filter = IntentFilter(UsageTimerService.BROADCAST_STATE_UPDATE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.registerReceiver(stateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            activity.registerReceiver(stateReceiver, filter)
        }

        tryBindExistingService()
    }

    fun unregister() {
        try { activity.unregisterReceiver(stateReceiver) } catch (_: Exception) {}
        unbindService()
        channel?.setMethodCallHandler(null)
        channel = null
    }

    fun rebindIfNeeded() {
        if (!serviceBound) tryBindExistingService()
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private val ACTION_START   = UsageTimerService.ACTION_START
    private val ACTION_STOP    = UsageTimerService.ACTION_STOP
    private val ACTION_UNBLOCK = UsageTimerService.ACTION_UNBLOCK

    private fun serviceIntent(action: String) =
        Intent(activity, UsageTimerService::class.java).apply { this.action = action }

    private fun startService(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.startForegroundService(intent)
        } else {
            activity.startService(intent)
        }
    }

    private fun bindService() {
        if (!serviceBound) {
            activity.bindService(
                serviceIntent(ACTION_START),
                serviceConnection,
                Context.BIND_AUTO_CREATE,
            )
        }
    }

    private fun tryBindExistingService() {
        if (!serviceBound) {
            activity.bindService(
                serviceIntent(ACTION_START),
                serviceConnection,
                0, // no BIND_AUTO_CREATE — do not start the service if not running
            )
        }
    }

    private fun unbindService() {
        if (serviceBound) {
            try { activity.unbindService(serviceConnection) } catch (_: Exception) {}
            serviceBound = false
            timerService = null
        }
    }
}