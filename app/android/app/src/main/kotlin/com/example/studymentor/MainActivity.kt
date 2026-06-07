package com.example.studymentor

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private lateinit var overlayPlugin: OverlayPlugin
    private lateinit var installedAppsPlugin: InstalledAppsPlugin
    private lateinit var timerServiceBridge: TimerServiceBridge
    private lateinit var deviceAdminPlugin: DeviceAdminPlugin
    private lateinit var permissionPlugin: PermissionPlugin

    // Cached channel reference so onNewIntent can invoke onLimitReached even
    // after configureFlutterEngine has run.
    private var timerChannel: MethodChannel? = null

    // True when we need to fire the quiz trigger once the first frame renders.
    // Set in configureFlutterEngine and consumed in onFlutterUiDisplayed.
    private var pendingQuizOnLaunch = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        overlayPlugin = OverlayPlugin(this)
        overlayPlugin.registerWith(flutterEngine)

        installedAppsPlugin = InstalledAppsPlugin(this)
        installedAppsPlugin.registerWith(flutterEngine)

        timerServiceBridge = TimerServiceBridge(this)
        timerServiceBridge.registerWith(flutterEngine)

        deviceAdminPlugin = DeviceAdminPlugin(this)
        deviceAdminPlugin.registerWith(flutterEngine)

        permissionPlugin = PermissionPlugin(this)
        permissionPlugin.registerWith(flutterEngine)

        timerChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TimerServiceBridge.CHANNEL,
        )

        // Cold-launch path: UsageTimerService.block() attached EXTRA_QUIZ_ON_LAUNCH
        // to the intent that started this Activity.
        //
        // We CANNOT call dispatchQuizOnLaunch() here — the Dart isolate has not
        // started yet, so MascotOverlayService.init() has not registered its
        // MethodChannel handler. The invokeMethod call would fire into the void.
        //
        // Instead, park a flag and deliver the trigger from onFlutterUiDisplayed(),
        // which is called by the FlutterEngine after the first frame has been
        // rendered. At that point the Dart tree is fully built and all channel
        // handlers are registered.
        if (intent?.getBooleanExtra(UsageTimerService.EXTRA_QUIZ_ON_LAUNCH, false) == true) {
            pendingQuizOnLaunch = true
            intent.removeExtra(UsageTimerService.EXTRA_QUIZ_ON_LAUNCH)
        }
    }

    /**
     * Called by the FlutterEngine once the first frame has been rasterised and
     * displayed. At this point the Dart isolate is fully running, main() has
     * completed, and all MethodChannel handlers registered inside initState()
     * (including MascotOverlayService.init()) are live.
     *
     * This is the earliest safe moment to call invokeMethod("onLimitReached")
     * on a cold launch, so that MascotOverlayService._handleTimerServiceCallback
     * actually receives the call and the quiz overlay is shown.
     */
    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        if (pendingQuizOnLaunch) {
            pendingQuizOnLaunch = false
            dispatchQuizOnLaunch()
        }
    }

    /**
     * Warm-resume path: the Activity was already in the back stack (not swiped
     * away) when UsageTimerService.block() called startActivity(). Android
     * delivers the new Intent here instead of recreating the Activity.
     *
     * On warm resume the Flutter engine is already running, so we can call
     * dispatchQuizOnLaunch() immediately — no frame-render delay needed.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        if (intent.getBooleanExtra(UsageTimerService.EXTRA_QUIZ_ON_LAUNCH, false)) {
            dispatchQuizOnLaunch()
            intent.removeExtra(UsageTimerService.EXTRA_QUIZ_ON_LAUNCH)
        }
    }

    /**
     * Restores the service binding on every resume in case it was lost without
     * a full process restart. This covers two scenarios:
     *
     *   1. The Activity was recreated due to a configuration change (rotation,
     *      theme switch, locale change). configureFlutterEngine is not called
     *      again in this case, so registerWith() — and the tryBindExistingService()
     *      call at its end — do not run. rebindIfNeeded() fills that gap.
     *
     *   2. Android unbound the service while the app was in the background
     *      (low-memory trim, OEM battery optimisation). The service itself stays
     *      alive as a foreground service, but serviceBound becomes false and
     *      timerService becomes null. rebindIfNeeded() restores the reference
     *      before the user can interact with anything.
     *
     * rebindIfNeeded() is a no-op when already bound, so there is no cost to
     * calling it unconditionally here.
     */
    override fun onResume() {
        super.onResume()
        timerServiceBridge.rebindIfNeeded()
    }

    /**
     * Invokes onLimitReached on the Dart-side timer-service channel.
     *
     * Only call this after the Flutter UI has been displayed (cold launch) or
     * on warm resume where the engine is already running.
     */
    private fun dispatchQuizOnLaunch() {
        timerChannel?.invokeMethod("onLimitReached", null)
    }

    override fun onDestroy() {
        timerServiceBridge.unregister()
        super.onDestroy()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        overlayPlugin.onActivityResult(requestCode)

        // The Device Admin dialog just closed (user granted or denied).
        // Clear the bypass flag so the accessibility Settings guard resumes.
        if (requestCode == DeviceAdminPlugin.REQUEST_CODE_ENABLE_ADMIN) {
            StudyMentorAccessibilityService.isRequestingAdmin = false
        }
    }
}