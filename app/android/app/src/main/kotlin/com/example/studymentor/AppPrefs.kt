package com.example.studymentor

/**
 * Single source of truth for SharedPreferences keys used across the app.
 *
 * Both [DeviceAdminPlugin] (writer) and [StudyMentorAccessibilityService]
 * (reader) reference these constants so a rename in one place is
 * automatically reflected in the other.
 */
object AppPrefs {
    const val PREFS_NAME = "studymentor_prefs"

    /** Persisted by DeviceAdminPlugin.setStudentMode. */
    const val KEY_STUDENT_MODE = "is_student_logged_in"

    /** Persisted by DeviceAdminPlugin.setPermissionSetupMode. */
    const val KEY_PERMISSION_SETUP = "is_in_permission_setup"

    /**
     * Persisted by UsageTimerService whenever block() / unblock() is called.
     * Read by StudyMentorAccessibilityService on onServiceConnected() so that
     * the blocked state is immediately restored without waiting for
     * UsageTimerService to finish restarting after a process kill.
     *
     * This lives in AppPrefs (studymentor_prefs) rather than the timer-service
     * prefs (studymentor_timer_prefs) so that both services can read it from
     * the same file without a cross-prefs dependency.
     */
    const val KEY_IS_BLOCKED = "is_blocked_shared"
}