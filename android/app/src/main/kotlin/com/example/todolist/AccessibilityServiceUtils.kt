package com.example.todolist

import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import android.text.TextUtils.SimpleStringSplitter

object AccessibilityServiceUtils {

    fun isAppBlockerServiceEnabled(context: Context): Boolean {
        val accessibilityEnabled = Settings.Secure.getInt(
            context.contentResolver,
            Settings.Secure.ACCESSIBILITY_ENABLED,
            0
        )

        if (accessibilityEnabled != 1) {
            return false
        }

        val settingValue = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val splitter = SimpleStringSplitter(':')
        splitter.setString(settingValue)

        while (splitter.hasNext()) {
            val accessibilityService = splitter.next()
            if (accessibilityService.equals(
                    ComponentName(
                        context,
                        AppBlockerAccessibilityService::class.java
                    ).flattenToString(),
                    ignoreCase = true
                )) {
                return true
            }
        }

        return false
    }
}
