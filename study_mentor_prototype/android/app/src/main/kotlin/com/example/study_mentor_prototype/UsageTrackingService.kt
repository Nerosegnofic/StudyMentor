package com.example.study_mentor_prototype

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
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
    private val NOTIFICATION_ID = 12345

    private var countdownTimer: CountDownTimer? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val sessionTimeMinutes = intent?.getIntExtra("sessionTimeMinutes", 1) ?: 1
        val sessionTimeMillis = TimeUnit.MINUTES.toMillis(sessionTimeMinutes.toLong())

        Log.d("UsageTrackingService", "Service started with session time: $sessionTimeMinutes minutes.")

        val notification = createNotification("Study session in progress...")
        startForeground(NOTIFICATION_ID, notification)

        startTimer(sessionTimeMillis)

        return START_NOT_STICKY
    }

    private fun startTimer(sessionTimeMillis: Long) {
        countdownTimer?.cancel() // Cancel any existing timer
        countdownTimer = object : CountDownTimer(sessionTimeMillis, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val minutes = TimeUnit.MILLISECONDS.toMinutes(millisUntilFinished)
                val seconds = TimeUnit.MILLISECONDS.toSeconds(millisUntilFinished) % 60
                val timeString = String.format("%02d:%02d", minutes, seconds)
                updateNotification("Time remaining: $timeString")
            }

            override fun onFinish() {
                Log.d("UsageTrackingService", "Timer finished! Notifying Flutter to lock screen.")

                // *** THIS IS THE CRITICAL FIX ***
                // Use a Handler to post the action to the main thread.
                // Invoke the "onTimeUp" method on the channel stored in MainActivity.
                Handler(Looper.getMainLooper()).post {
                    MainActivity.channel?.invokeMethod("onTimeUp", null)
                }

                updateNotification("Study session finished!")
                stopSelf() // Stop the service
            }
        }.start()
    }

    private fun updateNotification(contentText: String) {
        val notification = createNotification(contentText)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotification(contentText: String): Notification {
        // You must have an 'ic_launcher' icon in your mipmap folders
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Study Mentor")
            .setContentText(contentText)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOnlyAlertOnce(true) // Prevents the notification from making a sound on every update
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Study Mentor Service"
            val descriptionText = "Channel for the Study Mentor background service."
            val importance = NotificationManager.IMPORTANCE_LOW // Use LOW to avoid sound on each update
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        // We don't provide binding, so return null
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        countdownTimer?.cancel()
        Log.d("UsageTrackingService", "Service destroyed, timer cancelled.")
    }
}
