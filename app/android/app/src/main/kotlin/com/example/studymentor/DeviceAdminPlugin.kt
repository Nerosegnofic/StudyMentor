package com.example.studymentor

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class DeviceAdminPlugin(private val activity: MainActivity) {

    companion object {
        const val CHANNEL = "com.example.studymentor/device_admin"
        const val REQUEST_CODE_ENABLE_ADMIN = 9001
    }

    private val dpm: DevicePolicyManager by lazy {
        activity.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    }

    private val adminComponent: ComponentName by lazy {
        ComponentName(activity, MyDeviceAdminReceiver::class.java)
    }

    fun registerWith(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "isAdminActive" -> {
                        result.success(dpm.isAdminActive(adminComponent))
                    }

                    "requestAdmin" -> {
                        // Raise the bypass flag BEFORE opening the dialog.
                        // The accessibility service reads this flag and skips
                        // the Settings guard while it is true, so the Device
                        // Admin system dialog is not immediately dismissed.
                        // The flag is cleared in MainActivity.onActivityResult
                        // once the dialog finishes (user grants or denies).
                        StudyMentorAccessibilityService.isRequestingAdmin = true

                        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                            putExtra(
                                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                                "StudyMentor needs this permission to protect your study " +
                                "session and prevent the app from being removed."
                            )
                        }
                        activity.startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN)
                        result.success(null)
                    }

                    "setStudentMode" -> {
                        val active = call.argument<Boolean>("active") ?: false
                        StudyMentorAccessibilityService.isStudentLoggedIn = active
                        result.success(null)
                    }

                    // Suppresses the Settings guard for the entire permission
                    // setup flow (PermissionGateScreen). Unlike isRequestingAdmin
                    // — which only covers the narrow Device Admin dialog window —
                    // this flag covers all five permission steps so the student
                    // can reach Settings freely until setup is complete.
                    "setPermissionSetupMode" -> {
                        val active = call.argument<Boolean>("active") ?: false
                        StudyMentorAccessibilityService.isInPermissionSetup = active
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}