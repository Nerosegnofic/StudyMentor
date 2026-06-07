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

            val usageLimit = timerService?.getUsageLimitSecs()
                ?: UsageTimerService.prefs(activity).getInt("usage_limit_seconds", 1800)

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
                        val apps          = call.argument<List<String>>("monitoredApps") ?: emptyList()
                        val usageLimit    = call.argument<Int>("usageLimitSecs") ?: 1800
                        val cooldownLimit = call.argument<Int>("cooldownLimitSecs") ?: 600

                        val intent = serviceIntent(ACTION_START).apply {
                            putStringArrayListExtra(
                                UsageTimerService.EXTRA_MONITORED_APPS,
                                ArrayList(apps),
                            )
                            putExtra(UsageTimerService.EXTRA_USAGE_LIMIT_SECS,    usageLimit)
                            putExtra(UsageTimerService.EXTRA_COOLDOWN_LIMIT_SECS, cooldownLimit)
                            putExtra(UsageTimerService.EXTRA_STUDENT_LOGGED_IN,   true)
                        }
                        startService(intent)
                        bindService()
                        result.success(null)
                    }

                    "stopTimerService" -> {
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
                        val apps          = call.argument<List<String>>("monitoredApps") ?: emptyList()
                        val usageLimit    = call.argument<Int>("usageLimitSecs") ?: 1800
                        val cooldownLimit = call.argument<Int>("cooldownLimitSecs") ?: 600

                        val intent = serviceIntent(ACTION_START).apply {
                            putStringArrayListExtra(
                                UsageTimerService.EXTRA_MONITORED_APPS,
                                ArrayList(apps),
                            )
                            putExtra(UsageTimerService.EXTRA_USAGE_LIMIT_SECS,    usageLimit)
                            putExtra(UsageTimerService.EXTRA_COOLDOWN_LIMIT_SECS, cooldownLimit)
                            putExtra(UsageTimerService.EXTRA_STUDENT_LOGGED_IN,   true)
                        }
                        startService(intent)
                        result.success(null)
                    }

                    "getTimerState" -> {
                        val prefs         = UsageTimerService.prefs(activity)
                        val total         = prefs.getInt("total_usage_seconds", 0)
                        val blocked       = prefs.getBoolean("is_blocked", false)
                        val cdRem         = prefs.getInt("cooldown_remaining_seconds", 0)
                        val limit         = prefs.getInt("usage_limit_seconds", 1800)
                        // ── Quiz state ────────────────────────────────────────
                        // quizDismissed: student explicitly tapped away without finishing
                        // quizShown:     quiz was pushed onto the screen at least once
                        //
                        // On cold relaunch the Dart layer uses these to decide:
                        //   dismissed=true  → suppress the quiz for this cooldown
                        //   dismissed=false, shown=true  → quiz was open when app died,
                        //                                  show it again
                        //   dismissed=false, shown=false → normal first trigger
                        val quizDismissed = prefs.getBoolean(UsageTimerService.KEY_QUIZ_DISMISSED, false)
                        val quizShown     = prefs.getBoolean(UsageTimerService.KEY_QUIZ_SHOWN, false)
                        result.success(
                            mapOf(
                                "totalUsage"        to total,
                                "isBlocked"         to blocked,
                                "cooldownRemaining" to cdRem,
                                "usageLimit"        to limit,
                                "quizDismissed"     to quizDismissed,
                                "quizShown"         to quizShown,
                            ),
                        )
                    }

                    // ── Quiz state mutations ───────────────────────────────────
                    // Called by Flutter's MascotOverlayService when the quiz
                    // overlay is pushed or popped so native prefs stay in sync.

                    "setQuizDismissed" -> {
                        // Student explicitly dismissed (tapped away without finishing).
                        val dismissed = call.argument<Boolean>("dismissed") ?: false
                        UsageTimerService.prefs(activity)
                            .edit()
                            .putBoolean(UsageTimerService.KEY_QUIZ_DISMISSED, dismissed)
                            // Dismissing implies the quiz was shown at some point.
                            .putBoolean(UsageTimerService.KEY_QUIZ_SHOWN, if (dismissed) true
                                else UsageTimerService.prefs(activity)
                                         .getBoolean(UsageTimerService.KEY_QUIZ_SHOWN, false))
                            .apply()
                        timerService?.setQuizDismissed(dismissed)
                        result.success(null)
                    }

                    "markQuizShown" -> {
                        // Quiz overlay has been pushed — mark as shown without dismissing.
                        UsageTimerService.prefs(activity)
                            .edit()
                            .putBoolean(UsageTimerService.KEY_QUIZ_SHOWN, true)
                            .apply()
                        timerService?.markQuizShown()
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

        // If UsageTimerService is already running (e.g. the Activity was
        // destroyed and recreated while the foreground service stayed alive),
        // restore the binder reference immediately.
        tryBindExistingService()
    }

    fun unregister() {
        try { activity.unregisterReceiver(stateReceiver) } catch (_: Exception) {}
        unbindService()
        channel?.setMethodCallHandler(null)
        channel = null
    }

    /**
     * Called from Activity.onResume to restore the service binding if it was
     * lost without a full process restart. Safe to call when already bound.
     */
    fun rebindIfNeeded() {
        if (!serviceBound) {
            tryBindExistingService()
        }
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