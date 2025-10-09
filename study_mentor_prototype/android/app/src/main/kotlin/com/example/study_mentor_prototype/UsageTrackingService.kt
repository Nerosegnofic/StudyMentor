package com.example.study_mentor_prototype

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.CountDownTimer
import android.os.IBinder
import android.util.Log
import androidx.compose.ui.test.cancel
import androidx.core.app.NotificationCompat
import androidx.core.content.getSystemService
import androidx.privacysandbox.tools.core.generator.build
import java.util.concurrent.TimeUnit

class UsageTrackingService : Service() {

    private val CHANNEL_ID = "UsageTrackingServiceChannel"
    private val NOTIFICATION_ID = 1

    private var countdownTimer: CountDownTimer? = null
    private var sessionTimeMillis: Long = 0

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d("UsageTrackingService", "Service created.")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("UsageTrackingService", "Service started.")

        // Retrieve the session time from the intent, default to 0 if not provided
        val sessionTimeMinutes = intent?.getIntExtra("sessionTimeMinutes", 0) ?: 0
        sessionTimeMillis = TimeUnit.MINUTES.toMillis(sessionTimeMinutes.toLong())

        val notification = createNotification("Study session started. Time remaining: $sessionTimeMinutes minutes")
        startForeground(NOTIFICATION_ID, notification)

        // Start the countdown
        startTimer()

        return START_STICKY
    }

    private fun startTimer() {
        // Cancel any existing timer before starting a new one
        countdownTimer?.cancel()

        if (sessionTimeMillis <= 0) {
            Log.d("UsageTrackingService", "Invalid session time. Not starting timer.")
            return
        }

        countdownTimer = object : CountDownTimer(sessionTimeMillis, 1000) { // Tick every second
            override fun onTick(millisUntilFinished: Long) {
                // Update notification with remaining time
                val minutesRemaining = TimeUnit.MILLISECONDS.toMinutes(millisUntilFinished)
                val secondsRemaining = TimeUnit.MILLISECONDS.toSeconds(millisUntilFinished) % 60
                val timeString = String.format("%02d:%02d", minutesRemaining, secondsRemaining)

                Log.d("UsageTrackingService", "Time remaining: $timeString")
                updateNotification("Time remaining: $timeString")
            }

            override fun onFinish() {
                Log.d("UsageTrackingService", "Timer finished! Time to trigger quiz.")

                // -----------------------------------------------------------------
                // TODO: TASK 2B & 2C - Trigger the lock screen / quiz screen here.
                // We will later invoke a method on the platform channel to tell Flutter
                // to show the quiz screen.
                // -----------------------------------------------------------------

                updateNotification("Study session finished!")
                // Stop the service gracefully
                stopSelf()
            }
        }.start()
    }

    private fun updateNotification(contentText: String) {
        val notification = createNotification(contentText)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotification(contentText: String): Notification {
        // Create a basic notification for the foreground service.
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Study Mentor is Active")
            .setContentText(contentText)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOnlyAlertOnce(true) // Prevents sound/vibration on update
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
            // Register the channel with the system
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        // This is an unbound service, so we return null.
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        // IMPORTANT: Clean up the timer when the service is destroyed
        countdownTimer?.cancel()
        Log.d("UsageTrackingService", "Service destroyed, timer cancelled.")
    }
}
