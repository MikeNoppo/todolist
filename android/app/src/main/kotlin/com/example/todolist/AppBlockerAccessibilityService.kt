package com.example.todolist

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AppBlockerAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockerService"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val KEY_LOW_WINDOW_HOURS = "flutter.intervention_window_low_hours"
        private const val KEY_MEDIUM_WINDOW_HOURS = "flutter.intervention_window_medium_hours"
        private const val KEY_HIGH_WINDOW_HOURS = "flutter.intervention_window_high_hours"
        private const val KEY_LAST_BLOCKED_PACKAGE = "flutter.debug_last_blocked_package"
        private const val KEY_LAST_BLOCKED_PRIORITY = "flutter.debug_last_blocked_priority"
        private const val KEY_LAST_BLOCKED_TASK_TITLE = "flutter.debug_last_blocked_task_title"
        private const val KEY_LAST_BLOCKED_REMAINING_MINUTES =
            "flutter.debug_last_blocked_remaining_minutes"
        private const val KEY_LAST_BLOCKED_WINDOW_HOURS = "flutter.debug_last_blocked_window_hours"
        private const val KEY_LAST_BLOCKED_AT_MILLIS = "flutter.debug_last_blocked_at_millis"

        private const val DEFAULT_LOW_WINDOW_HOURS = 2
        private const val DEFAULT_MEDIUM_WINDOW_HOURS = 8
        private const val DEFAULT_HIGH_WINDOW_HOURS = 24
        private const val MILLIS_PER_HOUR = 60L * 60L * 1000L
        private const val COOLDOWN_MILLIS = 10_000L

        private val DEFAULT_BLOCKED_APPS = setOf(
            "com.facebook.katana",
            "com.instagram.android",
            "com.twitter.android",
            "com.snapchat.android",
            "com.zhiliaoapp.musically",
            "com.google.android.youtube",
            "com.spotify.music",
            "com.netflix.mediaclient"
        )

        var instance: AppBlockerAccessibilityService? = null
            private set

        @Volatile
        private var lastBlockedPackage: String? = null

        @Volatile
        private var lastBlockedAtMillis: Long = 0L
    }

    private data class BlockingReason(
        val taskTitle: String,
        val priority: String,
        val remainingMinutes: Int,
        val windowHours: Int
    )

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "Accessibility Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val currentPackageName = event.packageName?.toString() ?: return
        if (!shouldEvaluatePackage(currentPackageName)) {
            return
        }

        if (isInCooldown(currentPackageName)) {
            return
        }

        val blockingReason = getBlockingReasonForPackage(currentPackageName) ?: return
        triggerHardBlock(currentPackageName, blockingReason)
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "Accessibility Service destroyed")
    }

    private fun shouldEvaluatePackage(packageName: String): Boolean {
        if (packageName == this.packageName) {
            return false
        }

        if (packageName.startsWith("com.android.systemui")) {
            return false
        }

        if (packageName.startsWith("com.android.launcher")) {
            return false
        }

        return true
    }

    private fun isInCooldown(packageName: String): Boolean {
        val now = System.currentTimeMillis()
        return packageName == lastBlockedPackage && now - lastBlockedAtMillis < COOLDOWN_MILLIS
    }

    private fun getBlockingReasonForPackage(packageName: String): BlockingReason? {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        if (!isPackageBlockedByUserPolicy(prefs, packageName)) {
            return null
        }

        return findBlockingReason(prefs)
    }

    private fun isPackageBlockedByUserPolicy(
        prefs: android.content.SharedPreferences,
        packageName: String
    ): Boolean {
        val hasAnyUserBlockConfig = prefs.all.keys.any { key ->
            key.startsWith("flutter.block_")
        }

        return if (hasAnyUserBlockConfig) {
            prefs.getBoolean("flutter.block_$packageName", false)
        } else {
            DEFAULT_BLOCKED_APPS.contains(packageName)
        }
    }

    private fun findBlockingReason(
        prefs: android.content.SharedPreferences
    ): BlockingReason? {
        val todosJson = prefs.getString("flutter.todos", null) ?: return null
        val lowWindowHours = getStoredInt(prefs, KEY_LOW_WINDOW_HOURS, DEFAULT_LOW_WINDOW_HOURS)
        val mediumWindowHours = getStoredInt(
            prefs,
            KEY_MEDIUM_WINDOW_HOURS,
            DEFAULT_MEDIUM_WINDOW_HOURS
        )
        val highWindowHours = getStoredInt(prefs, KEY_HIGH_WINDOW_HOURS, DEFAULT_HIGH_WINDOW_HOURS)
        val now = System.currentTimeMillis()

        return try {
            var selectedReason: BlockingReason? = null
            var selectedDeltaMillis = Long.MAX_VALUE
            val todos = JSONArray(todosJson)
            for (index in 0 until todos.length()) {
                val todo = todos.optJSONObject(index) ?: continue
                if (todo.optBoolean("isCompleted", false)) {
                    continue
                }

                val priority = todo.optString("priority", "").lowercase(Locale.US)
                val deadlineIso = todo.optString("deadline", "")
                val deadlineMillis = parseIsoDateToMillis(deadlineIso) ?: continue

                val windowHours = when (priority) {
                    "low" -> lowWindowHours
                    "medium" -> mediumWindowHours
                    "high" -> highWindowHours
                    else -> 0
                }

                if (windowHours <= 0) {
                    continue
                }

                val deadlineDeltaMillis = deadlineMillis - now
                if (deadlineDeltaMillis <= windowHours * MILLIS_PER_HOUR) {
                    if (deadlineDeltaMillis < selectedDeltaMillis) {
                        selectedDeltaMillis = deadlineDeltaMillis
                        selectedReason = BlockingReason(
                            taskTitle = todo.optString("title", "Tugas tanpa judul"),
                            priority = priority,
                            remainingMinutes = (deadlineDeltaMillis / 60_000L).toInt(),
                            windowHours = windowHours
                        )
                    }
                }
            }

            selectedReason
        } catch (error: Exception) {
            Log.e(TAG, "Failed to parse todos JSON for hard block policy", error)
            null
        }
    }

    private fun parseIsoDateToMillis(value: String): Long? {
        if (value.isBlank()) {
            return null
        }

        val supportedPatterns = listOf(
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
            "yyyy-MM-dd'T'HH:mm:ssXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'"
        )

        for (pattern in supportedPatterns) {
            try {
                val parser = SimpleDateFormat(pattern, Locale.US)
                val date: Date = parser.parse(value) ?: continue
                return date.time
            } catch (_: Exception) {
            }
        }

        return null
    }

    private fun getStoredInt(
        prefs: android.content.SharedPreferences,
        key: String,
        defaultValue: Int
    ): Int {
        val rawValue = prefs.all[key] ?: return defaultValue
        return when (rawValue) {
            is Int -> rawValue
            is Long -> rawValue.toInt()
            is Float -> rawValue.toInt()
            is Double -> rawValue.toInt()
            is String -> rawValue.toIntOrNull() ?: defaultValue
            else -> defaultValue
        }
    }

    private fun triggerHardBlock(packageName: String, reason: BlockingReason) {
        lastBlockedPackage = packageName
        lastBlockedAtMillis = System.currentTimeMillis()

        saveLastBlockedDebugInfo(packageName, reason)

        Log.d(TAG, "Hard block triggered for package=$packageName")
        performGlobalAction(GLOBAL_ACTION_HOME)

        val interventionIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
            putExtra(MainActivity.EXTRA_BLOCKED_PACKAGE, packageName)
        }

        startActivity(interventionIntent)
    }

    private fun saveLastBlockedDebugInfo(packageName: String, reason: BlockingReason) {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_LAST_BLOCKED_PACKAGE, packageName)
            .putString(KEY_LAST_BLOCKED_PRIORITY, reason.priority)
            .putString(KEY_LAST_BLOCKED_TASK_TITLE, reason.taskTitle)
            .putInt(KEY_LAST_BLOCKED_REMAINING_MINUTES, reason.remainingMinutes)
            .putInt(KEY_LAST_BLOCKED_WINDOW_HOURS, reason.windowHours)
            .putLong(KEY_LAST_BLOCKED_AT_MILLIS, System.currentTimeMillis())
            .apply()
    }

    fun isServiceRunning(): Boolean {
        return instance != null
    }
}
