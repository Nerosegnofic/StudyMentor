package com.example.studymentor

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private lateinit var overlayPlugin: 
OverlayPlugin
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        overlayPlugin = OverlayPlugin(this)
        overlayPlugin.registerWith(flutterEngine)
    }

    // Forward the Settings-screen result back to the plugin so it can
    // resolve the pending MethodChannel.Result.
    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        overlayPlugin.onActivityResult(requestCode)
    }
}
