package com.example.studymentor

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.CountDownTimer
import android.provider.Settings
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.media.AudioFocusRequest
import android.media.AudioAttributes
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class OverlayPlugin(private val activity: FlutterActivity) {

    companion object {
        const val OVERLAY_CHANNEL = "com.example.studymentor/overlay"
        const val USAGE_CHANNEL  = "com.example.studymentor/usage_stats"
        private const val REQUEST_OVERLAY_PERMISSION     = 1001
        private const val REQUEST_USAGE_STATS_PERMISSION = 1002
        private const val BLOCK_DURATION_MS = 60_000L
    }

    private var overlayView: View? = null
    private var windowManager: WindowManager? = null
    private var countdownText: TextView? = null
    private var quizZone: LinearLayout? = null
    private var countDownTimer: CountDownTimer? = null
    private var overlayChannel: MethodChannel? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    private var pendingOverlayResult: MethodChannel.Result? = null
    private var pendingUsageResult: MethodChannel.Result? = null

    // ── Channel registration ─────────────────────────────────────────────────

    fun registerWith(flutterEngine: FlutterEngine) {
        overlayChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OVERLAY_CHANNEL,
        ).also {
            it.setMethodCallHandler { call, result -> handleOverlay(call, result) }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            USAGE_CHANNEL,
        ).setMethodCallHandler { call, result -> handleUsage(call, result) }

        audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    // ── Overlay channel ──────────────────────────────────────────────────────

    private fun handleOverlay(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestOverlayPermission" -> {
                if (Settings.canDrawOverlays(activity)) {
                    result.success(true)
                } else {
                    pendingOverlayResult = result
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${activity.packageName}"),
                    )
                    activity.startActivityForResult(intent, REQUEST_OVERLAY_PERMISSION)
                }
            }
            "showOverlay" -> {
                if (!Settings.canDrawOverlays(activity)) {
                    result.error("NO_PERMISSION", "SYSTEM_ALERT_WINDOW not granted", null)
                    return
                }
                val state = call.argument<String>("state") ?: "idle"
                activity.runOnUiThread { showBlockingOverlay(state) }
                result.success(null)
            }
            "hideOverlay" -> {
                activity.runOnUiThread { removeOverlay(notifyFlutter = false) }
                result.success(null)
            }
            "updateState" -> {
                result.success(null)
            }
            "showQuizZone" -> {
                activity.runOnUiThread {
                    countdownText?.visibility = View.GONE
                    quizZone?.visibility = View.VISIBLE
                    countDownTimer?.cancel()
                }
                result.success(null)
            }
            "hideQuizZone" -> {
                activity.runOnUiThread {
                    quizZone?.visibility = View.GONE
                    countdownText?.visibility = View.VISIBLE
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // ── Usage stats channel ──────────────────────────────────────────────────

    private fun handleUsage(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestUsageStatsPermission" -> {
                if (hasUsageStatsPermission()) {
                    result.success(true)
                } else {
                    pendingUsageResult = result
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    activity.startActivityForResult(intent, REQUEST_USAGE_STATS_PERMISSION)
                }
            }
            "getForegroundApp" -> {
                result.success(getForegroundPackage())
            }
            else -> result.notImplemented()
        }
    }

    // ── Permission result ────────────────────────────────────────────────────

    fun onActivityResult(requestCode: Int) {
        when (requestCode) {
            REQUEST_OVERLAY_PERMISSION -> {
                pendingOverlayResult?.success(Settings.canDrawOverlays(activity))
                pendingOverlayResult = null
            }
            REQUEST_USAGE_STATS_PERMISSION -> {
                pendingUsageResult?.success(hasUsageStatsPermission())
                pendingUsageResult = null
            }
        }
    }

    // ── Audio focus — steals audio from YouTube/any app ──────────────────────

    private fun requestAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
            val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attrs)
                .setAcceptsDelayedFocusGain(false)
                .setOnAudioFocusChangeListener { }
                .build()
            audioFocusRequest = focusRequest
            audioManager?.requestAudioFocus(focusRequest)
        } else {
            @Suppress("DEPRECATION")
            audioManager?.requestAudioFocus(
                { },
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN,
            )
        }
    }

    private fun releaseAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus { }
        }
        audioFocusRequest = null
    }

    // ── Full-screen blocking overlay ─────────────────────────────────────────

    private fun showBlockingOverlay(state: String) {
        if (overlayView != null) return

       

        // Steal audio focus — this pauses YouTube/any media app
        requestAudioFocus()

        windowManager = activity.getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_SYSTEM_ERROR,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.OPAQUE,
        )

        val root = object : FrameLayout(activity) {
            override fun onTouchEvent(event: MotionEvent): Boolean = true
            override fun dispatchKeyEvent(event: KeyEvent): Boolean = true
        }.apply {
            setBackgroundColor(Color.parseColor("#FF000000"))
            isFocusable = true
            isFocusableInTouchMode = true
        }

        val center = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            )
        }

        val mascotCircle = TextView(activity).apply {
            val size = dpToPx(120)
            layoutParams = LinearLayout.LayoutParams(size, size).apply {
                gravity = Gravity.CENTER_HORIZONTAL
            }
            setBackgroundColor(Color.parseColor("#5C6BC0"))
            textSize = 48f
            gravity = Gravity.CENTER
            text = "OO"
            setTextColor(Color.WHITE)
        }

        val titleText = TextView(activity).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                topMargin = dpToPx(24)
            }
            text = "Study Time!"
            textSize = 28f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }

        val subtitleText = TextView(activity).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                topMargin = dpToPx(8)
            }
            text = "Take a break from your app"
            textSize = 16f
            setTextColor(Color.parseColor("#B0B0B0"))
            gravity = Gravity.CENTER
        }

        countdownText = TextView(activity).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                topMargin = dpToPx(32)
            }
            text = "01:00"
            textSize = 56f
            setTextColor(Color.parseColor("#5C6BC0"))
            gravity = Gravity.CENTER
        }

        val timerLabel = TextView(activity).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                topMargin = dpToPx(4)
            }
            text = "Please wait before continuing"
            textSize = 14f
            setTextColor(Color.parseColor("#808080"))
            gravity = Gravity.CENTER
        }

        quizZone = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
            setBackgroundColor(Color.parseColor("#1A1A2E"))
            setPadding(dpToPx(24), dpToPx(24), dpToPx(24), dpToPx(24))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                topMargin = dpToPx(24)
                marginStart = dpToPx(24)
                marginEnd = dpToPx(24)
            }
            val quizPlaceholder = TextView(activity).apply {
                text = "Quiz goes here"
                textSize = 18f
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                setPadding(0, dpToPx(32), 0, dpToPx(32))
            }
            addView(quizPlaceholder)
        }

        center.addView(mascotCircle)
        center.addView(titleText)
        center.addView(subtitleText)
        center.addView(countdownText)
        center.addView(timerLabel)
        center.addView(quizZone)

        root.addView(center)
        overlayView = root
        windowManager?.addView(root, params)

        startCountdown()
    }

    private fun startCountdown() {
        countDownTimer?.cancel()
        countDownTimer = object : CountDownTimer(BLOCK_DURATION_MS, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val seconds = (millisUntilFinished / 1000) % 60
                val minutes = (millisUntilFinished / 1000) / 60
                activity.runOnUiThread {
                    countdownText?.text = String.format("%02d:%02d", minutes, seconds)
                }
            }
            override fun onFinish() {
                activity.runOnUiThread { removeOverlay(notifyFlutter = true) }
            }
        }.start()
    }

    private fun removeOverlay(notifyFlutter: Boolean = false) {
        countDownTimer?.cancel()
        countDownTimer = null
        overlayView?.let { windowManager?.removeView(it) }
        overlayView = null
        countdownText = null
        quizZone = null
        // Release audio focus so YouTube/other apps can resume
        releaseAudioFocus()
        if (notifyFlutter) {
            activity.runOnUiThread {
                overlayChannel?.invokeMethod("onOverlayDismissed", null)
            }
        }
    }

    // ── Usage stats ──────────────────────────────────────────────────────────

    private fun getForegroundPackage(): String? {
        val usageManager = activity.getSystemService(Context.USAGE_STATS_SERVICE)
            as? UsageStatsManager ?: return null
        val now = System.currentTimeMillis()
        val stats = usageManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, now - 10_000, now,
        )
        return stats
            ?.filter { it.lastTimeUsed > 0 }
            ?.maxByOrNull { it.lastTimeUsed }
            ?.packageName
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = activity.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                activity.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                activity.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun dpToPx(dp: Int): Int =
        (dp * activity.resources.displayMetrics.density).toInt()
}
