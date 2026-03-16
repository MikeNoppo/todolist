package com.example.todolist

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class InterventionRecoveryReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "InterventionRecovery"
        private const val ACTION_RETRY =
            "com.example.todolist.action.INTERVENTION_RECOVERY_RETRY"
        private const val EXTRA_REASON = "reason"
        private const val RETRY_SHORT_DELAY_MILLIS = 15_000L
        private const val RETRY_LONG_DELAY_MILLIS = 60_000L
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action.orEmpty()
        Log.d(TAG, "Recovery receiver invoked: action=$action")

        val reason = intent?.getStringExtra(EXTRA_REASON)?.takeIf { it.isNotBlank() }
            ?: if (action.isBlank()) "broadcast_unknown" else "broadcast_$action"

        InterventionPersistenceService.start(context, reason)

        when (action) {
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON" -> {
                scheduleRetry(context, RETRY_SHORT_DELAY_MILLIS, "boot_retry_short")
                scheduleRetry(context, RETRY_LONG_DELAY_MILLIS, "boot_retry_long")
            }

            Intent.ACTION_USER_UNLOCKED -> {
                scheduleRetry(context, RETRY_SHORT_DELAY_MILLIS, "unlock_retry_short")
            }

            ACTION_RETRY -> {
                Log.d(TAG, "Recovery retry broadcast handled: reason=$reason")
            }
        }
    }

    private fun scheduleRetry(context: Context, delayMillis: Long, reason: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: run {
            Log.w(TAG, "AlarmManager unavailable; cannot schedule recovery retry")
            return
        }

        val retryIntent = Intent(context, InterventionRecoveryReceiver::class.java).apply {
            action = ACTION_RETRY
            putExtra(EXTRA_REASON, reason)
        }

        val pendingIntentFlags = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            }

            else -> PendingIntent.FLAG_UPDATE_CURRENT
        }

        val requestCode = reason.hashCode()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            retryIntent,
            pendingIntentFlags
        )

        val triggerAtMillis = System.currentTimeMillis() + delayMillis
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent
            )
        } else {
            alarmManager.set(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent
            )
        }
        Log.d(
            TAG,
            "Scheduled recovery retry: reason=$reason delayMillis=$delayMillis triggerAt=$triggerAtMillis"
        )
    }
}
