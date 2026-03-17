package com.example.todolist

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

enum class NotificationInterruptionMode(val storageValue: String) {
    OFF("off"),
    FILTER_DISTRACTING_APPS("filter_distracting_apps"),
    DND("dnd");

    companion object {
        fun fromStorageValue(value: String?): NotificationInterruptionMode {
            return values().firstOrNull { it.storageValue == value } ?: OFF
        }
    }
}

data class UrgencyPolicyReason(
    val taskTitle: String,
    val priority: String,
    val remainingMinutes: Int,
    val windowHours: Int
)

object UrgencyNotificationPolicy {
    private const val TAG = "UrgencyNotificationPolicy"

    const val FLUTTER_PREFS = "FlutterSharedPreferences"
    const val KEY_TODOS = "flutter.todos"
    const val KEY_LOW_WINDOW_HOURS = "flutter.intervention_window_low_hours"
    const val KEY_MEDIUM_WINDOW_HOURS = "flutter.intervention_window_medium_hours"
    const val KEY_HIGH_WINDOW_HOURS = "flutter.intervention_window_high_hours"
    const val KEY_BLOCK_PREFIX = "flutter.block_"
    const val KEY_ALLOW_PREFIX = "flutter.allow_"
    const val KEY_NOTIFICATION_INTERRUPTION_MODE = "flutter.notification_interruption_mode"
    const val KEY_NATIVE_APP_MANAGED_DND_ACTIVE = "flutter.native_app_managed_dnd_active"

    private const val DEFAULT_LOW_WINDOW_HOURS = 2
    private const val DEFAULT_MEDIUM_WINDOW_HOURS = 8
    private const val DEFAULT_HIGH_WINDOW_HOURS = 24
    private const val MILLIS_PER_HOUR = 60L * 60L * 1000L

    fun prefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
    }

    fun getNotificationInterruptionMode(context: Context): NotificationInterruptionMode {
        val rawValue = prefs(context).getString(KEY_NOTIFICATION_INTERRUPTION_MODE, null)
        return NotificationInterruptionMode.fromStorageValue(rawValue)
    }

    fun isNotificationFilteringEnabled(context: Context): Boolean {
        return getNotificationInterruptionMode(context) ==
            NotificationInterruptionMode.FILTER_DISTRACTING_APPS
    }

    fun isDoNotDisturbModeEnabled(context: Context): Boolean {
        return getNotificationInterruptionMode(context) == NotificationInterruptionMode.DND
    }

    fun hasActiveUrgencyWindow(context: Context): Boolean {
        return findBlockingReason(context) != null
    }

    fun findBlockingReason(context: Context): UrgencyPolicyReason? {
        return findBlockingReason(prefs(context))
    }

    fun getBlockingReasonForPackage(context: Context, packageName: String): UrgencyPolicyReason? {
        val prefs = prefs(context)
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

    fun shouldFilterNotificationFromPackage(context: Context, packageName: String): Boolean {
        if (!isNotificationFilteringEnabled(context)) {
            return false
        }

        return getBlockingReasonForPackage(context, packageName) != null
    }

    fun isAppManagedDndActive(context: Context): Boolean {
        return prefs(context).getBoolean(KEY_NATIVE_APP_MANAGED_DND_ACTIVE, false)
    }

    fun setAppManagedDndActive(context: Context, isActive: Boolean) {
        prefs(context).edit().putBoolean(KEY_NATIVE_APP_MANAGED_DND_ACTIVE, isActive).apply()
    }

    fun isPackageBlockedByUserPolicy(
        prefs: SharedPreferences,
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
            false
        }

        Log.d(
            TAG,
            "User policy evaluation: package=$packageName hasUserConfig=$hasAnyUserBlockConfig blocked=$isBlocked"
        )
        return isBlocked
    }

    private fun findBlockingReason(prefs: SharedPreferences): UrgencyPolicyReason? {
        val todosJson = prefs.getString(KEY_TODOS, null)
        if (todosJson.isNullOrBlank()) {
            Log.d(TAG, "No todos found in shared preferences; skipping urgency evaluation")
            return null
        }

        val lowWindowHours = getStoredInt(prefs, KEY_LOW_WINDOW_HOURS, DEFAULT_LOW_WINDOW_HOURS)
        val mediumWindowHours = getStoredInt(
            prefs,
            KEY_MEDIUM_WINDOW_HOURS,
            DEFAULT_MEDIUM_WINDOW_HOURS
        )
        val highWindowHours = getStoredInt(
            prefs,
            KEY_HIGH_WINDOW_HOURS,
            DEFAULT_HIGH_WINDOW_HOURS
        )
        val now = System.currentTimeMillis()

        return try {
            var selectedReason: UrgencyPolicyReason? = null
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
                if (deadlineDeltaMillis > windowHours * MILLIS_PER_HOUR) {
                    continue
                }

                if (deadlineDeltaMillis < selectedDeltaMillis) {
                    selectedDeltaMillis = deadlineDeltaMillis
                    selectedReason = UrgencyPolicyReason(
                        taskTitle = todo.optString("title", "Tugas tanpa judul"),
                        priority = priority,
                        remainingMinutes = (deadlineDeltaMillis / 60_000L).toInt(),
                        windowHours = windowHours
                    )
                }
            }

            selectedReason
        } catch (error: Exception) {
            Log.e(TAG, "Failed to parse todos JSON for urgency policy", error)
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
        prefs: SharedPreferences,
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
}
