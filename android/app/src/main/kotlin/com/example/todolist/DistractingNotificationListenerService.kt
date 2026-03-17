package com.example.todolist

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class DistractingNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "DistractingNotifFilter"
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        UrgencyNotificationControlManager.sync(this, "notification_listener_connected")
        Log.d(TAG, "Notification listener connected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val sourcePackage = sbn.packageName ?: return
        if (sourcePackage == packageName) {
            return
        }

        if (!UrgencyNotificationPolicy.isNotificationFilteringEnabled(this)) {
            return
        }

        val reason = UrgencyNotificationPolicy.getBlockingReasonForPackage(this, sourcePackage)
            ?: return

        try {
            cancelNotification(sbn.key)
            Log.i(
                TAG,
                "Suppressed notification: package=$sourcePackage task=${reason.taskTitle} " +
                    "priority=${reason.priority} remainingMinutes=${reason.remainingMinutes}"
            )
        } catch (error: Exception) {
            Log.w(TAG, "Failed to suppress notification: package=$sourcePackage", error)
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Notification listener disconnected")
    }
}
