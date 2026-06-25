package com.example.studymentor

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.accessibility.AccessibilityEvent

class StudyMentorAccessibilityService : AccessibilityService() {

    companion object {
        /** True while the warning overlay is active (app-blocking feature). */
        @Volatile var isBlocked = false

        /**
         * True while a student is logged in.
         * Enables the full Settings block that prevents the student from
         * opening Settings at all — including app info, accessibility settings,
         * and any other page they could use to revoke our permissions.
         *
         * This flag is set to true only AFTER the permission gate completes
         * (i.e. every required permission has been granted). It must not be
         * set at login time, because the student still needs Settings access
         * to grant the remaining permissions.
         */
        @Volatile var isStudentLoggedIn = false

        /**
         * True while the permission setup flow (PermissionGateScreen) is
         * active. Suppresses the Settings guard so the student can navigate
         * to Settings freely to grant each required permission.
         *
         * Set to true by PermissionGateScreen.initState() and cleared to false
         * atomically with isStudentLoggedIn being set to true once all
         * permissions are confirmed (DeviceAdminService.onPermissionsGranted).
         *
         * This is intentionally separate from isRequestingAdmin: that flag
         * handles the narrow Device Admin dialog window, whereas this flag
         * covers the entire multi-step setup flow.
         */
        @Volatile var isInPermissionSetup = false

        /**
         * Temporarily true while the Device Admin activation dialog is open.
         * Suppresses the Settings guard so the system dialog can appear and
         * the student can grant admin rights without being kicked back home.
         * Cleared in MainActivity.onActivityResult once the dialog closes.
         */
        @Volatile var isRequestingAdmin = false

        /**
         * Set to true immediately before calling GLOBAL_ACTION_HOME on a
         * monitored app, so the launcher event that follows is not mistaken
         * for the user intentionally pressing home.
         */
        @Volatile var justIntercepted = false

        var monitoredApps = mutableListOf<String>()
        var instance: StudyMentorAccessibilityService? = null

        private val LAUNCHER_PACKAGES = setOf(
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

        /**
         * Every package that can expose app info, accessibility settings, or
         * permission management to the student.
         *
         * Covers stock Android and the most common OEM skins. The check uses
         * startsWith so sub-packages (e.g. com.android.settings.intelligence)
         * are caught automatically.
         *
         * The guard is only active when ALL of the following are true:
         *   • isStudentLoggedIn  — a student session is active
         *   • !isInPermissionSetup — the setup gate has fully completed
         *   • !isRequestingAdmin   — the Device Admin dialog is not open
         */
        private val BLOCKED_SETTINGS_PACKAGES = listOf(
            // ── Stock / AOSP ──────────────────────────────────────────────────
            "com.android.settings",
            "com.android.permissioncontroller",  // Permission manager (Android 10+)
            "com.google.android.permissioncontroller",

            // ── Samsung ───────────────────────────────────────────────────────
            "com.samsung.android.settings",
            "com.samsung.android.lool",          // Device Care / app permissions
            "com.samsung.android.app.aodservice",

            // ── Xiaomi / MIUI ─────────────────────────────────────────────────
            "com.miui.securitycenter",
            "com.miui.permcenter",

            // ── Huawei / HarmonyOS ────────────────────────────────────────────
            "com.huawei.systemmanager",
            "com.huawei.permissionmanager",

            // ── OPPO / ColorOS ────────────────────────────────────────────────
            "com.oppo.safe",
            "com.coloros.safecenter",
            "com.coloros.oppoguardelf",

            // ── Vivo / FuntouchOS ─────────────────────────────────────────────
            "com.vivo.permissionmanager",
            "com.iqoo.secure",

            // ── OnePlus / OxygenOS ────────────────────────────────────────────
            "com.oneplus.security",

            // ── ASUS / ZenUI ──────────────────────────────────────────────────
            "com.asus.mobilemanager",

            // ── Nothing OS ────────────────────────────────────────────────────
            "com.nothing.settings",
        )
    }

    // Timestamp of the last throttled isBlocked refresh-from-prefs in
    // onAccessibilityEvent (self-heal for a stale static after login).
    private var lastBlockedRefreshMs = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this

        // Restore persisted flags so the Settings guard and app-blocking guard
        // are immediately active if the service was killed and restarted while
        // a student was logged in.
        //
        // KEY_IS_BLOCKED is read from AppPrefs (studymentor_prefs) — the shared
        // prefs file that UsageTimerService also writes to on every block() /
        // unblock() call. This eliminates the window where UsageTimerService is
        // still restarting (after an OEM process kill on swipe-to-dismiss) but
        // the accessibility service has already come back online with isBlocked
        // defaulting to false, causing restrictions to briefly lift.
        val prefs = getSharedPreferences(AppPrefs.PREFS_NAME, Context.MODE_PRIVATE)
        isStudentLoggedIn   = prefs.getBoolean(AppPrefs.KEY_STUDENT_MODE, false)
        isInPermissionSetup = prefs.getBoolean(AppPrefs.KEY_PERMISSION_SETUP, false)
        isBlocked           = prefs.getBoolean(AppPrefs.KEY_IS_BLOCKED, false)

        // Restore monitored apps from UsageTimerService shared prefs. The live
        // set is persisted per-student under "<uid>_monitored_apps"
        // (UsageTimerService.saveMonitoredApps + OverlayPlugin.setMonitoredApps);
        // the bare "monitored_apps" key is only a legacy fallback. Reading the
        // per-student key is what makes a fresh-process reconnect recover the set
        // instead of leaving it empty until a Dart push lands.
        val timerPrefs = UsageTimerService.prefs(applicationContext)
        val restoreUid = timerPrefs.getString("student_uid", "") ?: ""
        val savedApps = timerPrefs.getStringSet(
            UsageTimerService.studentKey(restoreUid, "monitored_apps"), null,
        ) ?: timerPrefs.getStringSet("monitored_apps", null)
        if (savedApps != null) {
            synchronized(monitoredApps) {
                monitoredApps.clear()
                monitoredApps.addAll(savedApps)
            }
        }

        // ── Watchdog: revive the usage-timer service ─────────────────────────
        //
        // The system restarts accessibility services independently of our app
        // process, which makes this the single most reliable revival point after
        // an aggressive OEM kills the process and swallows the UsageTimerService
        // START_STICKY restart. If a student is logged in, (re)start the timer
        // service with a null-action intent so it falls into the onStartCommand
        // `null` branch — restoring persisted state and resuming the tick loop.
        // No-op if the service is already running. Starting a FGS from the
        // background here is permitted because the app holds SYSTEM_ALERT_WINDOW.
        if (isStudentLoggedIn) {
            startTimerServiceIfNeeded()
        }

        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes          = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType        = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags               = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val pkg = event.packageName?.toString() ?: return
        if (pkg == "com.example.studymentor") return
        if (pkg == "com.android.systemui") return

        // ── Settings guard (student mode only) ───────────────────────────────
        //
        // Block Settings and every OEM-equivalent package once a student
        // session is fully active. Three bypass conditions exist:
        //
        //   isInPermissionSetup — the PermissionGateScreen is still running;
        //     the student must be able to reach Settings to grant permissions.
        //
        //   isRequestingAdmin — the Device Admin activation dialog is open;
        //     Android must be able to display the system dialog without us
        //     immediately kicking the student home.
        //
        // Both flags are cleared atomically with isStudentLoggedIn being set
        // to true, so there is no window where the guard is active but a
        // bypass is stale.
        if (isStudentLoggedIn && !isInPermissionSetup && !isRequestingAdmin) {
            if (BLOCKED_SETTINGS_PACKAGES.any { pkg.startsWith(it) }) {
                performGlobalAction(GLOBAL_ACTION_HOME)
                return
            }
        }

        // ── App-blocking guard (existing feature) ────────────────────────────

        // ONE-DIRECTIONAL self-heal of the blocked flag from prefs (throttled to
        // ≤ once/sec). Only ever ADOPT blocked=true — recovering a stale-false
        // static after login (the Dart setBlocked(true) push can lag behind the
        // heavy login render: the "not blocked until I reopen the app" bug). It must
        // NEVER copy false onto the static: native unblock() writes
        // KEY_IS_BLOCKED=false on a cooldown flip while the student should stay
        // blocked (reward 0), and the only thing that legitimately unblocks the
        // static is Dart setBlocked(false), which sets it directly. Copying false
        // here disabled the instant accessibility bounce and forced the slow
        // native-tick fallback — the post-quiz re-bounce delay.
        val nowMs = System.currentTimeMillis()
        if (nowMs - lastBlockedRefreshMs > 1000L) {
            lastBlockedRefreshMs = nowMs
            if (getSharedPreferences(AppPrefs.PREFS_NAME, Context.MODE_PRIVATE)
                    .getBoolean(AppPrefs.KEY_IS_BLOCKED, false)
            ) {
                isBlocked = true
            }
        }

        // TEMP diagnostics — logged BEFORE the guard so a logcat distinguishes
        // "isBlocked=false" from "no event at all". Remove once verified.
        android.util.Log.d(
            "StudyMentorA11y",
            "evt pkg=$pkg isBlocked=$isBlocked monitored=${monitoredApps.size} " +
                "contains=${monitoredApps.contains(pkg)}",
        )

        if (!isBlocked) return

        val isLauncher  = LAUNCHER_PACKAGES.any { pkg.startsWith(it) }

        // Fetch studentUid from UsageTimerService shared prefs
        val timerPrefs = UsageTimerService.prefs(this)
        val studentUid = timerPrefs.getString("student_uid", "") ?: ""

        // Self-heal an empty monitored set from prefs — the missing half of the
        // isBlocked self-heal above. On every login the Dart setMonitoredApps push
        // can fail to "stick" during the heavy first render; isBlocked recovers
        // (so the quiz fires) but monitoredApps did not, so nothing was recognised
        // as blockable until a manual reopen re-pushed it. Repair from the
        // per-student key UsageTimerService persists. Only when empty, so a live
        // Dart push always wins; runs only while blocked (after the guard above).
        if (monitoredApps.isEmpty() && studentUid.isNotEmpty()) {
            val saved = timerPrefs.getStringSet(
                UsageTimerService.studentKey(studentUid, "monitored_apps"), null,
            )
            if (!saved.isNullOrEmpty()) {
                synchronized(monitoredApps) {
                    monitoredApps.clear()
                    monitoredApps.addAll(saved)
                }
            }
        }

        // Fetch paused packages from FlutterSharedPreferences
        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
        val pausedAppsValue = flutterPrefs.all["flutter.paused_packages_$studentUid"]
        val isPaused = when (pausedAppsValue) {
            is Set<*> -> pausedAppsValue.contains(pkg)
            is List<*> -> pausedAppsValue.contains(pkg)
            is Collection<*> -> pausedAppsValue.contains(pkg)
            is String -> pausedAppsValue.contains("\"$pkg\"") || pausedAppsValue.contains(pkg)
            else -> false
        }

        val isMonitored = monitoredApps.contains(pkg) && !isPaused

        if (isLauncher || !isMonitored) {
            if (!justIntercepted) {
                OverlayPlugin.instance?.dismissOverlay()
            }
            justIntercepted = false
            return
        }

        justIntercepted = true
        performGlobalAction(GLOBAL_ACTION_HOME)

        // Bring StudyMentor forward and show the unmet gate (quiz or cooldown).
        // We start MainActivity directly with EXTRA_SHOW_QUIZ rather than relying
        // solely on OverlayPlugin.instance, which is null whenever the Flutter
        // engine/activity has been destroyed (e.g. after a process kill). The
        // intent guarantees the gate appears even on a cold start; the Dart side
        // decides quiz-vs-cooldown. Background activity launch is permitted via
        // the app's SYSTEM_ALERT_WINDOW permission.
        startActivity(
            Intent(this, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK
                        or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                        or Intent.FLAG_ACTIVITY_SINGLE_TOP,
                )
                putExtra(UsageTimerService.EXTRA_SHOW_QUIZ, true)
            },
        )

        // Fast path when the engine is already alive — brings the app forward
        // immediately without waiting for the Activity launch above to settle.
        OverlayPlugin.instance?.notifyMonitoredAppIntercepted(pkg)
    }

    /**
     * (Re)starts [UsageTimerService] with a null-action intent so it restores
     * persisted per-student state and resumes ticking. Idempotent — a no-op when
     * the service is already running. Used by the onServiceConnected watchdog.
     */
    private fun startTimerServiceIfNeeded() {
        try {
            val intent = Intent(applicationContext, UsageTimerService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                applicationContext.startForegroundService(intent)
            } else {
                applicationContext.startService(intent)
            }
        } catch (_: Exception) {
            // Background-start may be refused on some OEMs without SYSTEM_ALERT_WINDOW;
            // the START_STICKY / boot-receiver paths remain as fallbacks.
        }
    }

    override fun onInterrupt() {
        instance = null
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }
}