package com.example.studymentor

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private lateinit var overlayPlugin: OverlayPlugin
    private lateinit var installedAppsPlugin: InstalledAppsPlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        overlayPlugin = OverlayPlugin(this)
        overlayPlugin.registerWith(flutterEngine)
        installedAppsPlugin = InstalledAppsPlugin(this)
        installedAppsPlugin.registerWith(flutterEngine)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        overlayPlugin.onActivityResult(requestCode)
    }
}
