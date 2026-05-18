package com.example.studymentor

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
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
         */
        @Volatile var isStudentLoggedIn = false

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
         * isRequestingAdmin acts as a bypass: while the Device Admin dialog is
         * open this entire block is suppressed so the system can show the
         * dialog without us kicking the student back to the home screen.
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
        // When a student is logged in, block the entire Settings app and every
        // OEM-equivalent package that could expose:
        //   • App Info  → disable "Display over other apps" or force-stop us
        //   • Accessibility  → disable our accessibility service
        //   • Device Admin / Permission manager  → revoke admin or permissions
        //
        // isRequestingAdmin is a temporary bypass: while the Device Admin
        // activation dialog is open this guard is suspended so Android can
        // present the system dialog without us kicking the student home.
        // It is cleared in MainActivity.onActivityResult once the dialog ends.
        if (isStudentLoggedIn && !isRequestingAdmin) {
            if (BLOCKED_SETTINGS_PACKAGES.any { pkg.startsWith(it) }) {
                performGlobalAction(GLOBAL_ACTION_HOME)
                return
            }
        }

        // ── App-blocking guard (existing feature) ────────────────────────────
        if (!isBlocked) return

        val isLauncher  = LAUNCHER_PACKAGES.any { pkg.startsWith(it) }
        val isMonitored = monitoredApps.contains(pkg)

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