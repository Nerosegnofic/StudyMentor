package com.example.studymentor

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
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
        if (!isBlocked) return

        val isLauncher  = LAUNCHER_PACKAGES.any { pkg.startsWith(it) }

        // Fetch studentUid from UsageTimerService shared prefs
        val timerPrefs = UsageTimerService.prefs(this)
        val studentUid = timerPrefs.getString("student_uid", "") ?: ""

        // Fetch paused packages from FlutterSharedPreferences
        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
        val pausedAppsValue = flutterPrefs.all["flutter.paused_packages_$studentUid"]
        val isPaused = when (pausedAppsValue) {
            is Set<*> -> pausedAppsValue.contains(pkg)
            is String -> pausedAppsValue.contains("\"$pkg\"")
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
        OverlayPlugin.instance?.notifyMonitoredAppIntercepted(pkg)
    }

    override fun onInterrupt() {
        instance = null
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }
}