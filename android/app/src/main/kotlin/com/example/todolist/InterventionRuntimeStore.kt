package com.example.todolist

import android.content.Context

object InterventionRuntimeStore {
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"

    private const val KEY_ACCESSIBILITY_HEARTBEAT_MILLIS =
        "flutter.native_accessibility_heartbeat_millis"
    private const val KEY_ACCESSIBILITY_LAST_EVENT_PACKAGE =
        "flutter.native_accessibility_last_event_package"
    private const val KEY_ACCESSIBILITY_DISCONNECTED_AT_MILLIS =
        "flutter.native_accessibility_disconnected_at_millis"
    private const val KEY_KEEPER_LAST_START_AT_MILLIS =
        "flutter.native_keeper_last_start_at_millis"
    private const val KEY_KEEPER_LAST_START_REASON =
        "flutter.native_keeper_last_start_reason"

    private fun prefs(context: Context) =
        context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)

    fun touchAccessibilityHeartbeat(context: Context, packageName: String? = null) {
        val now = System.currentTimeMillis()
        prefs(context).edit().apply {
            putLong(KEY_ACCESSIBILITY_HEARTBEAT_MILLIS, now)
            remove(KEY_ACCESSIBILITY_DISCONNECTED_AT_MILLIS)
            if (!packageName.isNullOrBlank()) {
                putString(KEY_ACCESSIBILITY_LAST_EVENT_PACKAGE, packageName)
            }
        }.apply()
    }

    fun markAccessibilityDisconnected(context: Context) {
        prefs(context).edit().putLong(
            KEY_ACCESSIBILITY_DISCONNECTED_AT_MILLIS,
            System.currentTimeMillis()
        ).apply()
    }

    fun recordKeeperStart(context: Context, reason: String) {
        prefs(context).edit()
            .putLong(KEY_KEEPER_LAST_START_AT_MILLIS, System.currentTimeMillis())
            .putString(KEY_KEEPER_LAST_START_REASON, reason)
            .apply()
    }

    fun getAccessibilityHeartbeatAgeMillis(context: Context): Long? {
        val lastHeartbeat = prefs(context).getLong(KEY_ACCESSIBILITY_HEARTBEAT_MILLIS, 0L)
        if (lastHeartbeat <= 0L) {
            return null
        }

        return (System.currentTimeMillis() - lastHeartbeat).coerceAtLeast(0L)
    }
}
