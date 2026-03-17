package com.example.todolist

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

class InterventionPersistenceService : Service() {

    companion object {
        private const val TAG = "InterventionKeeper"
        private const val CHANNEL_ID = "intervention_guard_channel"
        private const val NOTIFICATION_ID = 4107
        private const val ACTION_START = "com.example.todolist.action.START_INTERVENTION_KEEPER"
        private const val EXTRA_REASON = "reason"
        private const val ACTION_NOTIFICATION_POLICY_ACCESS_GRANTED_CHANGED =
            "android.app.action.NOTIFICATION_POLICY_ACCESS_GRANTED_CHANGED"

        fun start(context: Context, reason: String) {
            if (!UrgencyNotificationControlManager.requiresBackgroundSync(context)) {
                Log.d(TAG, "Skip keeper start because background sync is not needed: reason=$reason")
                return
            }

            InterventionRuntimeStore.recordKeeperStart(context, reason)

            val intent = Intent(context, InterventionPersistenceService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_REASON, reason)
            }

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (error: Exception) {
                Log.w(TAG, "Failed to start intervention persistence service: reason=$reason", error)
            }
        }

        fun refreshForPolicy(context: Context, reason: String) {
            if (UrgencyNotificationControlManager.requiresBackgroundSync(context)) {
                start(context, reason)
                return
            }

            try {
                val stopped = context.stopService(Intent(context, InterventionPersistenceService::class.java))
                Log.d(TAG, "Requested keeper stop: reason=$reason stopped=$stopped")
            } catch (error: Exception) {
                Log.w(TAG, "Failed to stop intervention persistence service: reason=$reason", error)
            }
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val notificationManager by lazy {
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    private val refreshNotificationRunnable = object : Runnable {
        override fun run() {
            if (refreshNotification()) {
                mainHandler.postDelayed(this, 60_000L)
            }
        }
    }
    private val notificationPolicyAccessReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != ACTION_NOTIFICATION_POLICY_ACCESS_GRANTED_CHANGED) {
                return
            }

            val syncReason = "notification_policy_access_changed"
            UrgencyNotificationControlManager.sync(this@InterventionPersistenceService, syncReason)
            notificationManager.notify(NOTIFICATION_ID, buildNotification())
            Log.d(TAG, "Handled DND policy access change broadcast")
        }
    }
    private var notificationPolicyAccessReceiverRegistered = false

    override fun onCreate() {
        super.onCreate()
        ensureNotificationChannel()
        registerNotificationPolicyAccessReceiverIfNeeded()
        Log.d(TAG, "Intervention persistence service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val reason = intent?.getStringExtra(EXTRA_REASON).orEmpty()
        if (!UrgencyNotificationControlManager.requiresBackgroundSync(this)) {
            Log.d(TAG, "Stopping keeper because background sync is not needed")
            stopSelf()
            return START_NOT_STICKY
        }

        UrgencyNotificationControlManager.sync(this, reason.ifBlank { "onStartCommand" })
        InterventionRuntimeStore.recordKeeperStart(this, reason.ifBlank { "onStartCommand" })
        startForeground(NOTIFICATION_ID, buildNotification())

        mainHandler.removeCallbacks(refreshNotificationRunnable)
        mainHandler.postDelayed(refreshNotificationRunnable, 60_000L)

        Log.d(TAG, "Intervention persistence service started: reason=$reason")
        return START_STICKY
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(refreshNotificationRunnable)
        unregisterNotificationPolicyAccessReceiverIfNeeded()
        Log.d(TAG, "Intervention persistence service destroyed")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun refreshNotification(): Boolean {
        if (!UrgencyNotificationControlManager.requiresBackgroundSync(this)) {
            Log.d(TAG, "Stopping keeper during refresh because background sync is not needed")
            stopSelf()
            return false
        }

        UrgencyNotificationControlManager.sync(this, "keeper_refresh")
        notificationManager.notify(NOTIFICATION_ID, buildNotification())
        return true
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)

        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val contentIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            pendingIntentFlags
        )

        val heartbeatAge = InterventionRuntimeStore.getAccessibilityHeartbeatAgeMillis(this)
        val dndModeEnabled = UrgencyNotificationPolicy.isDoNotDisturbModeEnabled(this)
        val dndAccessGranted = UrgencyNotificationControlManager.hasDoNotDisturbAccess(this)
        val contentText = if (!AccessibilityServiceUtils.isAppBlockerServiceEnabled(this) && dndModeEnabled) {
            if (dndAccessGranted) {
                getString(R.string.intervention_guard_notification_dnd)
            } else {
                getString(R.string.intervention_guard_notification_dnd_waiting_access)
            }
        } else {
            when {
                heartbeatAge == null -> getString(R.string.intervention_guard_notification_waiting)
                heartbeatAge > 90_000L -> getString(R.string.intervention_guard_notification_reconnecting)
                else -> getString(R.string.intervention_guard_notification_active)
            }
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(getString(R.string.intervention_guard_notification_title))
            .setContentText(contentText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(contentText))
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setContentIntent(contentIntent)
            .build()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.intervention_guard_channel_name),
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = getString(R.string.intervention_guard_channel_description)
            setShowBadge(false)
        }

        notificationManager.createNotificationChannel(channel)
    }

    private fun registerNotificationPolicyAccessReceiverIfNeeded() {
        if (notificationPolicyAccessReceiverRegistered || Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return
        }

        val filter = IntentFilter(ACTION_NOTIFICATION_POLICY_ACCESS_GRANTED_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(notificationPolicyAccessReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(notificationPolicyAccessReceiver, filter)
        }
        notificationPolicyAccessReceiverRegistered = true
    }

    private fun unregisterNotificationPolicyAccessReceiverIfNeeded() {
        if (!notificationPolicyAccessReceiverRegistered) {
            return
        }

        try {
            unregisterReceiver(notificationPolicyAccessReceiver)
        } catch (error: Exception) {
            Log.w(TAG, "Failed to unregister DND policy access receiver", error)
        } finally {
            notificationPolicyAccessReceiverRegistered = false
        }
    }
}
