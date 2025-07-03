package com.example.todolist

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class AppBlockerAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockerService"
        var instance: AppBlockerAccessibilityService? = null
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "Accessibility Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            packageName?.let {
                Log.d(TAG, "Current app: $it")
                // Kirim event ke Flutter
                sendAppChangeEvent(it)
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "Accessibility Service destroyed")
    }

    private fun sendAppChangeEvent(packageName: String) {
        // TODO : 
        // Method untuk mengirim event ke Flutter akan ditambahkan nanti
        // Untuk saat ini, hanya log
        Log.d(TAG, "App changed to: $packageName")
    }

    fun isServiceRunning(): Boolean {
        return instance != null
    }
}
