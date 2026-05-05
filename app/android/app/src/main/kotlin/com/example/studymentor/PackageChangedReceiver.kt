package com.example.studymentor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Listens for package install / uninstall / replace broadcasts and marks the
 * student's installed-app inventory as stale.
 *
 * Flutter reads the dirty flag on every app resume and re-syncs the inventory
 * to DataConnect if it is set, then clears it.
 */
class PackageChangedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_PACKAGE_ADDED,
            Intent.ACTION_PACKAGE_REMOVED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                context.getSharedPreferences(
                    InstalledAppsPlugin.PREFS_NAME,
                    Context.MODE_PRIVATE,
                ).edit().putBoolean(InstalledAppsPlugin.KEY_INVENTORY_DIRTY, true).apply()
            }
        }
    }
}
