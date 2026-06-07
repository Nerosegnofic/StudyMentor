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
}