package com.example.todolist

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.service.notification.NotificationListenerService
import android.util.Log
import androidx.core.app.NotificationManagerCompat

object UrgencyNotificationControlManager {
    private const val TAG = "UrgencyNotificationCtrl"

    fun hasNotificationListenerAccess(context: Context): Boolean {
        return NotificationManagerCompat.getEnabledListenerPackages(context)
            .contains(context.packageName)
    }

    fun hasDoNotDisturbAccess(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false
        }

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: return false
        return notificationManager.isNotificationPolicyAccessGranted
    }

    fun requiresBackgroundSync(context: Context): Boolean {
        if (AccessibilityServiceUtils.isAppBlockerServiceEnabled(context)) {
            return true
        }

        return UrgencyNotificationPolicy.isDoNotDisturbModeEnabled(context)
    }

    fun sync(context: Context, reason: String): Boolean {
        return try {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    ?: return false

            when (UrgencyNotificationPolicy.getNotificationInterruptionMode(context)) {
                NotificationInterruptionMode.OFF -> {
                    disableAppManagedDndIfNeeded(context, notificationManager, reason)
                }

                NotificationInterruptionMode.FILTER_DISTRACTING_APPS -> {
                    disableAppManagedDndIfNeeded(context, notificationManager, reason)
                    requestNotificationListenerRebind(context)
                }

                NotificationInterruptionMode.DND -> {
                    syncDoNotDisturbState(context, notificationManager, reason)
                }
            }

            true
        } catch (error: Exception) {
            Log.e(TAG, "Failed syncing notification interruption state: reason=$reason", error)
            false
        }
    }

    private fun syncDoNotDisturbState(
        context: Context,
        notificationManager: NotificationManager,
        reason: String
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return
        }

        val hasAccess = notificationManager.isNotificationPolicyAccessGranted
        val appManaged = UrgencyNotificationPolicy.isAppManagedDndActive(context)
        if (!hasAccess) {
            relinquishAppManagedDndOwnershipIfNeeded(context, appManaged, reason)
            Log.w(TAG, "Skip DND sync because access is missing: reason=$reason")
            return
        }

        val hasActiveUrgency = UrgencyNotificationPolicy.hasActiveUrgencyWindow(context)
        val currentFilter = notificationManager.currentInterruptionFilter

        if (!hasActiveUrgency) {
            if (!appManaged) {
                return
            }

            if (currentFilter != NotificationManager.INTERRUPTION_FILTER_ALL) {
                notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
            }
            UrgencyNotificationPolicy.setAppManagedDndActive(context, false)
            Log.i(TAG, "Disabled app-managed DND: reason=$reason")
            return
        }

        if (appManaged) {
            if (currentFilter != NotificationManager.INTERRUPTION_FILTER_PRIORITY) {
                notificationManager.setInterruptionFilter(
                    NotificationManager.INTERRUPTION_FILTER_PRIORITY
                )
            }
            Log.d(TAG, "Maintained app-managed DND during active urgency: reason=$reason")
            return
        }

        if (currentFilter != NotificationManager.INTERRUPTION_FILTER_ALL) {
            Log.d(
                TAG,
                "Respecting existing system DND state: filter=$currentFilter reason=$reason"
            )
            return
        }

        notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
        UrgencyNotificationPolicy.setAppManagedDndActive(context, true)
        Log.i(TAG, "Enabled app-managed DND for active urgency: reason=$reason")
    }

    private fun disableAppManagedDndIfNeeded(
        context: Context,
        notificationManager: NotificationManager,
        reason: String
    ) {
        if (!UrgencyNotificationPolicy.isAppManagedDndActive(context)) {
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            UrgencyNotificationPolicy.setAppManagedDndActive(context, false)
            return
        }

        if (!notificationManager.isNotificationPolicyAccessGranted) {
            relinquishAppManagedDndOwnershipIfNeeded(context, isAppManaged = true, reason = reason)
            Log.w(TAG, "Cannot disable app-managed DND because access is missing: reason=$reason")
            return
        }

        if (notificationManager.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL) {
            notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
        }
        UrgencyNotificationPolicy.setAppManagedDndActive(context, false)
        Log.i(TAG, "Cleared app-managed DND state: reason=$reason")
    }

    private fun relinquishAppManagedDndOwnershipIfNeeded(
        context: Context,
        isAppManaged: Boolean,
        reason: String
    ) {
        if (!isAppManaged) {
            return
        }

        UrgencyNotificationPolicy.setAppManagedDndActive(context, false)
        Log.w(TAG, "Relinquished app-managed DND ownership: reason=$reason")
    }

    private fun requestNotificationListenerRebind(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return
        }

        if (!hasNotificationListenerAccess(context)) {
            return
        }

        try {
            NotificationListenerService.requestRebind(
                ComponentName(context, DistractingNotificationListenerService::class.java)
            )
        } catch (error: Exception) {
            Log.w(TAG, "Failed to request notification listener rebind", error)
        }
    }
}
