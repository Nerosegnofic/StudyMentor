package com.example.study_mentor_prototype

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.getSystemService
import androidx.privacysandbox.tools.core.generator.build

class UsageTrackingService : Service() {

    private val CHANNEL_ID = "UsageTrackingServiceChannel"
    private val NOTIFICATION_ID = 1

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d("UsageTrackingService", "Service created.")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("UsageTrackingService", "Service started.")

        val notification = createNotification("Monitoring app usage...")
        startForeground(NOTIFICATION_ID, notification)

        // TODO: Implement the app usage tracking logic here.
        // We will add a loop here later to check the foreground app periodically.

        // If the service is killed by the system, it will be automatically restarted.
        return START_STICKY
    }

    private fun createNotification(contentText: String): Notification {
        // Create a basic notification for the foreground service.
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Study Mentor is Active")
            .setContentText(contentText)
            .setSmallIcon(R.mipmap.ic_launcher) // Use the default launcher icon
            .setPriority(NotificationCompat.PRIORITY_LOW)
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
        Log.d("UsageTrackingService", "Service destroyed.")
    }
}
