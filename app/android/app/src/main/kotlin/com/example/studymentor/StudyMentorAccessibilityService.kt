package com.example.studymentor

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent

class StudyMentorAccessibilityService : AccessibilityService() {

    companion object {
        /** True while the warning overlay is active. */
        @Volatile var isBlocked = false

        /**
         * Set to true immediately before calling GLOBAL_ACTION_BACK on a
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
        if (!isBlocked) return

        val pkg = event.packageName?.toString() ?: return
        if (pkg == "com.example.studymentor") return
        if (pkg == "com.android.systemui") return

        val isLauncher  = LAUNCHER_PACKAGES.any { pkg.startsWith(it) }
        val isMonitored = monitoredApps.contains(pkg)

        if (isLauncher || !isMonitored) {
            // User navigated to the home screen or a non-monitored app.
            // If we just redirected them here via GLOBAL_ACTION_BACK (because
            // they tried to open a monitored app), don't dismiss the overlay —
            // it was just shown. Otherwise dismiss it: the user chose to leave.
            if (!justIntercepted) {
                OverlayPlugin.instance?.dismissOverlay()
            }
            justIntercepted = false
            return
        }

        // Monitored app detected — send student to the home screen (not just
        // one step back inside the app's own activity stack), then re-show
        // the overlay on top of the launcher so pressing back on the overlay
        // reveals the home screen, not the monitored app.
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
