package com.example.study_mentor_prototype

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.CountDownTimer
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.concurrent.TimeUnit

class UsageTrackingService : Service() {

    private val CHANNEL_ID = "UsageTrackingServiceChannel"
    private val NOTIFICATION_ID = 1

    private var countdownTimer: CountDownTimer? = null
    private var sessionTimeMillis: Long = 0

    // Handler and Runnable for periodic foreground app checking
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var usageCheckRunnable: Runnable // Corrected type: No "kotlinx.coroutines"

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d("UsageTrackingService", "Service created.")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("UsageTrackingService", "Service started.")

        val sessionTimeMinutes = intent?.getIntExtra("sessionTimeMinutes", 0) ?: 0
        sessionTimeMillis = TimeUnit.MINUTES.toMillis(sessionTimeMinutes.toLong())

        val notification = createNotification("Study session started. Time remaining: $sessionTimeMinutes minutes")
        startForeground(NOTIFICATION_ID, notification)

        startTimer()
        startUsageChecking() // Start checking the foreground app

        return START_STICKY
    }

    private fun startTimer() {
        countdownTimer?.cancel() // Correct usage of cancel()

        if (sessionTimeMillis <= 0) {
            Log.w("UsageTrackingService", "Invalid session time. Not starting timer.")
            return
        }

        countdownTimer = object : CountDownTimer(sessionTimeMillis, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val minutesRemaining = TimeUnit.MILLISECONDS.toMinutes(millisUntilFinished)
                val secondsRemaining = TimeUnit.MILLISECONDS.toSeconds(millisUntilFinished) % 60
                val timeString = String.format("%02d:%02d", minutesRemaining, secondsRemaining)
                updateNotification("Time remaining: $timeString")
            }

            override fun onFinish() {
                Log.d("UsageTrackingService", "Timer finished! Time to trigger quiz.")
                // TODO: TASK 2B & 2C - Trigger the lock screen / quiz screen here.
                updateNotification("Study session finished!")
                stopSelf()
            }
        }.start()
    }

    private fun startUsageChecking() {
        // Use the correct Runnable from java.lang
        usageCheckRunnable = Runnable {
            val foregroundApp = getForegroundApp()
            Log.d("UsageTrackingService", "Current foreground app: $foregroundApp")

            // TODO: Add logic here to check if the foregroundApp is allowed or not.
            // For example: if (foregroundApp !in allowedApps) { triggerWarning(); }

            // Schedule the next check in 2 seconds
            handler.postDelayed(usageCheckRunnable, 2000)
        }
        // Start the first check
        handler.post(usageCheckRunnable)
    }

    private fun getForegroundApp(): String? {
        // Correct usage of getSystemService
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        // Query stats for the last 10 seconds
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 1000 * 10, time)

        if (stats != null && stats.isNotEmpty()) {
            val sortedStats = stats.sortedByDescending { it.lastTimeUsed }
            return sortedStats.firstOrNull()?.packageName
        }
        return null
    }

    private fun updateNotification(contentText: String) {
        val notification = createNotification(contentText)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotification(contentText: String): Notification {
        // Correct usage of NotificationCompat.Builder
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Study Mentor is Active")
            .setContentText(contentText)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOnlyAlertOnce(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Usage Tracking Service"
            val descriptionText = "Monitors app usage to enforce study sessions."
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        // Stop the timer and the usage checking loop
        countdownTimer?.cancel()
        handler.removeCallbacks(usageCheckRunnable)
        Log.d("UsageTrackingService", "Service destroyed, timer and usage checking stopped.")
    }
}
