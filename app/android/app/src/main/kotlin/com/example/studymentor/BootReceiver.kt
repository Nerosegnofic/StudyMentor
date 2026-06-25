package com.example.studymentor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Receives [Intent.ACTION_BOOT_COMPLETED] after the device starts up
 * and restarts all StudyMentor background services.
 *
 * Why this matters
 * ────────────────
 * A student might reboot the phone to bypass app-usage restrictions:
 * after a normal cold boot [UsageTimerService] is dead, the accessibility
 * service needs to be re-enabled by the system (it survives reboots
 * automatically once enabled), and no monitoring is running.
 *
 * This receiver fires as soon as the device finishes booting and:
 * 1. Restarts [UsageTimerService] with ACTION_START so the persisted
 * timer/blocked state is immediately restored (the service calls
 * restoreState() inside onCreate, then resumes ticking or cooling down).
 * 2. Launches [MainActivity] if a student was logged in when the phone was
 * shut down, so the app is visible and the quiz/overlay is shown if
 * the student was mid-cooldown.
 *
 * SharedPreferences key used
 * ──────────────────────────
 * [AppPrefs.KEY_STUDENT_MODE] — written by DeviceAdminPlugin whenever
 * setStudentMode() is called from Flutter. If this is false (parent logged
 * in, or no account at all) we do nothing on boot.
 *
 * Compatibility: Android 6 (API 23) – Android 15+ (API 35).
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        if (action != Intent.ACTION_BOOT_COMPLETED) return

        // Only act when a student was logged in before the reboot.
        // This is the same SharedPreferences key that DeviceAdminPlugin
        // writes via setStudentMode() from the Flutter side.
        val prefs = context.getSharedPreferences(AppPrefs.PREFS_NAME, Context.MODE_PRIVATE)
        val studentWasLoggedIn = prefs.getBoolean(AppPrefs.KEY_STUDENT_MODE, false)

        if (!studentWasLoggedIn) return

        // ── 1. Restart the usage timer service ────────────────────────────────
        // We send ACTION_START without extras so UsageTimerService falls into
        // the `null` action branch in onStartCommand, restores persisted state
        // via restoreState(), and resumes ticking.
        //
        // On Android 8+ foreground services must be started with
        // startForegroundService(); the service then calls startForeground()
        // within 5 seconds to satisfy the OS requirement.
        val serviceIntent = Intent(context, UsageTimerService::class.java).apply {
            // FIXED: Added 'this.' to avoid ambiguity with the outer read-only local variable 'action'
            this.action = UsageTimerService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // ── 2. Bring the app to the foreground ────────────────────────────────
        // If a quiz was active when the device was rebooted, add
        // EXTRA_QUIZ_RESTORE so MainActivity can invoke onQuizRestore on the
        // Flutter side and the student resumes exactly where they left off.
        val timerPrefs = UsageTimerService.prefs(context)
        val quizLockActive = timerPrefs.getBoolean(
            UsageTimerService.KEY_QUIZ_LOCK_ACTIVE, false)

        val activityIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK
                    or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                    or Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            if (quizLockActive) {
                putExtra(UsageTimerService.EXTRA_QUIZ_RESTORE, true)
            }
        }
        context.startActivity(activityIntent)
    }
}