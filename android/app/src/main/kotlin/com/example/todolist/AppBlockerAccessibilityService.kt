package com.example.todolist

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class AppBlockerAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockerService"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val KEY_LOW_WINDOW_HOURS = "flutter.intervention_window_low_hours"
        private const val KEY_MEDIUM_WINDOW_HOURS = "flutter.intervention_window_medium_hours"
        private const val KEY_HIGH_WINDOW_HOURS = "flutter.intervention_window_high_hours"
        private const val KEY_BLOCK_PREFIX = "flutter.block_"
        private const val KEY_ALLOW_PREFIX = "flutter.allow_"
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
        private const val REENTRY_GUARD_MILLIS = 1_200L

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
        private var lastTriggeredPackage: String? = null

        @Volatile
        private var lastTriggeredAtMillis: Long = 0L
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
        val isWindowEvent = event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            event.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED
        if (!isWindowEvent) {
            return
        }

        val currentPackageName = event.packageName?.toString() ?: return
        if (!shouldEvaluatePackage(currentPackageName)) {
            return
        }

        if (isInReentryGuard(currentPackageName)) {
            Log.d(TAG, "Skipping package due reentry guard: package=$currentPackageName")
            return
        }

        Log.d(TAG, "Evaluating package for hard block: package=$currentPackageName")

        val blockingReason = getBlockingReasonForPackage(currentPackageName) ?: return
        Log.d(
            TAG,
            "Hard block eligible: package=$currentPackageName task=${blockingReason.taskTitle} " +
                "priority=${blockingReason.priority} remainingMinutes=${blockingReason.remainingMinutes} " +
                "windowHours=${blockingReason.windowHours}"
        )
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
            Log.d(TAG, "Skipping own package event: package=$packageName")
            return false
        }

        if (packageName.startsWith("com.android.systemui")) {
            Log.d(TAG, "Skipping system ui package event: package=$packageName")
            return false
        }

        if (packageName.startsWith("com.android.launcher")) {
            Log.d(TAG, "Skipping launcher package event: package=$packageName")
            return false
        }

        if (packageName.startsWith("com.miui.home") ||
            packageName.startsWith("com.mi.android.globallauncher")
        ) {
            Log.d(TAG, "Skipping MIUI launcher package event: package=$packageName")
            return false
        }

        return true
    }

    private fun getBlockingReasonForPackage(packageName: String): BlockingReason? {
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        if (!isPackageBlockedByUserPolicy(prefs, packageName)) {
            Log.d(TAG, "Package is not blocked by user policy: package=$packageName")
            return null
        }

        val reason = findBlockingReason(prefs)
        if (reason == null) {
            Log.d(TAG, "No urgent task candidate found for package=$packageName")
        }

        return reason
    }

    private fun isPackageBlockedByUserPolicy(
        prefs: android.content.SharedPreferences,
        packageName: String
    ): Boolean {
        val isAlwaysAllowed = prefs.getBoolean("$KEY_ALLOW_PREFIX$packageName", false)
        if (isAlwaysAllowed) {
            Log.d(TAG, "Package is whitelisted (always allow): package=$packageName")
            return false
        }

        val hasAnyUserBlockConfig = prefs.all.keys.any { key ->
            key.startsWith(KEY_BLOCK_PREFIX)
        }

        val isBlocked = if (hasAnyUserBlockConfig) {
            prefs.getBoolean("$KEY_BLOCK_PREFIX$packageName", false)
        } else {
            DEFAULT_BLOCKED_APPS.contains(packageName)
        }

        Log.d(
            TAG,
            "User policy evaluation: package=$packageName hasUserConfig=$hasAnyUserBlockConfig blocked=$isBlocked"
        )
        return isBlocked
    }

    private fun findBlockingReason(
        prefs: android.content.SharedPreferences
    ): BlockingReason? {
        val todosJson = prefs.getString("flutter.todos", null)
        if (todosJson.isNullOrBlank()) {
            Log.d(TAG, "No todos found in shared preferences; skipping hard block")
            return null
        }

        val lowWindowHours = getStoredInt(prefs, KEY_LOW_WINDOW_HOURS, DEFAULT_LOW_WINDOW_HOURS)
        val mediumWindowHours = getStoredInt(
            prefs,
            KEY_MEDIUM_WINDOW_HOURS,
            DEFAULT_MEDIUM_WINDOW_HOURS
        )
        val highWindowHours = getStoredInt(prefs, KEY_HIGH_WINDOW_HOURS, DEFAULT_HIGH_WINDOW_HOURS)
        val now = System.currentTimeMillis()

        Log.d(
            TAG,
            "Evaluating todo urgency windows: low=${lowWindowHours}h medium=${mediumWindowHours}h high=${highWindowHours}h"
        )

        return try {
            var selectedReason: BlockingReason? = null
            var selectedDeltaMillis = Long.MAX_VALUE
            val todos = JSONArray(todosJson)
            var evaluatedTodos = 0

            for (index in 0 until todos.length()) {
                val todo = todos.optJSONObject(index) ?: continue
                if (todo.optBoolean("isCompleted", false)) {
                    continue
                }

                evaluatedTodos += 1

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

            if (selectedReason == null) {
                Log.d(
                    TAG,
                    "No task falls inside intervention window. evaluatedTodos=$evaluatedTodos"
                )
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

        val normalizedValue = normalizeIsoDate(value)

        val supportedPatterns = listOf(
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
            "yyyy-MM-dd'T'HH:mm:ssXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss"
        )

        for (pattern in supportedPatterns) {
            try {
                val parser = SimpleDateFormat(pattern, Locale.US)
                parser.isLenient = false
                if (pattern.contains("'Z'")) {
                    parser.timeZone = TimeZone.getTimeZone("UTC")
                } else if (!pattern.contains("XXX")) {
                    parser.timeZone = TimeZone.getDefault()
                }

                val date: Date = parser.parse(normalizedValue) ?: continue
                return date.time
            } catch (_: Exception) {
            }
        }

        Log.w(TAG, "Unable to parse todo deadline value: $value")

        return null
    }

    private fun normalizeIsoDate(value: String): String {
        val trimmed = value.trim()
        return trimmed.replace(
            Regex("(\\.\\d{3})\\d+(?=(Z|[+-]\\d{2}:?\\d{2})?$)"),
            "$1"
        )
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
        lastTriggeredPackage = packageName
        lastTriggeredAtMillis = System.currentTimeMillis()

        saveLastBlockedDebugInfo(packageName, reason)
        MainActivity.queueBlockedPackage(packageName)

        val interventionIntent = buildInterventionIntent(packageName, reason)

        val homeActionSucceeded = performGlobalAction(GLOBAL_ACTION_HOME)
        Log.d(
            TAG,
            "Prepared intervention intent for package=$packageName homeActionSucceeded=$homeActionSucceeded"
        )

        Handler(Looper.getMainLooper()).postDelayed({
            try {
                startActivity(interventionIntent)
                Log.d(TAG, "Requested intervention activity launch for package=$packageName")
            } catch (error: Exception) {
                Log.e(TAG, "Failed to launch intervention activity for package=$packageName", error)
                try {
                    startActivity(buildMainActivityFallbackIntent(packageName))
                    Log.d(TAG, "Fallback launch to MainActivity succeeded for package=$packageName")
                } catch (fallbackError: Exception) {
                    Log.e(
                        TAG,
                        "Fallback launch to MainActivity failed for package=$packageName",
                        fallbackError
                    )
                }
            }
        }, 140L)
    }

    private fun buildInterventionIntent(packageName: String, reason: BlockingReason): Intent {
        return Intent(this, NativeInterventionActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            )
            putExtra(NativeInterventionActivity.EXTRA_BLOCKED_PACKAGE, packageName)
            putExtra(NativeInterventionActivity.EXTRA_BLOCKING_TASK_TITLE, reason.taskTitle)
            putExtra(NativeInterventionActivity.EXTRA_BLOCKING_PRIORITY, reason.priority)
            putExtra(NativeInterventionActivity.EXTRA_BLOCKING_REMAINING_MINUTES, reason.remainingMinutes)
            putExtra(NativeInterventionActivity.EXTRA_BLOCKING_WINDOW_HOURS, reason.windowHours)
        }
    }

    private fun buildMainActivityFallbackIntent(packageName: String): Intent {
        return Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            )
            putExtra(MainActivity.EXTRA_BLOCKED_PACKAGE, packageName)
        }
    }

    private fun isInReentryGuard(packageName: String): Boolean {
        val lastPackage = lastTriggeredPackage ?: return false
        if (lastPackage != packageName) {
            return false
        }

        val elapsedMillis = System.currentTimeMillis() - lastTriggeredAtMillis
        return elapsedMillis in 0 until REENTRY_GUARD_MILLIS
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
