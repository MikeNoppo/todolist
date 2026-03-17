package com.example.todolist

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityWindowInfo
import android.util.Log
import android.view.accessibility.AccessibilityEvent

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
        private const val REENTRY_GUARD_MILLIS = 300L
        private const val POST_DISMISS_WATCH_DURATION_MILLIS = 15_000L
        private const val POST_DISMISS_WATCH_INTERVAL_MILLIS = 250L

        var instance: AppBlockerAccessibilityService? = null
            private set

        @Volatile
        private var lastTriggeredPackage: String? = null

        @Volatile
        private var lastTriggeredAtMillis: Long = 0L
    }

    // Overlay manager - created once and reused
    private var overlayManager: InterventionOverlayManager? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var watchedBlockedPackage: String? = null
    private var watchBlockedPackageUntilMillis: Long = 0L
    private val blockedPackageWatchRunnable = object : Runnable {
        override fun run() {
            val watchedPackage = watchedBlockedPackage
            if (watchedPackage.isNullOrBlank()) {
                return
            }

            if (System.currentTimeMillis() >= watchBlockedPackageUntilMillis) {
                stopBlockedPackageWatch("expired")
                return
            }

            if (overlayManager?.isOverlayShowing == true) {
                mainHandler.postDelayed(this, POST_DISMISS_WATCH_INTERVAL_MILLIS)
                return
            }

            val activePackageName = getActivePackageName()
            if (activePackageName == watchedPackage && !isInReentryGuard(activePackageName)) {
                val blockingReason = getBlockingReasonForPackage(activePackageName)
                if (blockingReason != null) {
                    Log.d(
                        TAG,
                        "Watchdog re-blocking active package=$activePackageName after overlay dismiss"
                    )
                    triggerHardBlock(activePackageName, blockingReason)
                }
            }

            mainHandler.postDelayed(this, POST_DISMISS_WATCH_INTERVAL_MILLIS)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        overlayManager = InterventionOverlayManager(this, ::handleBackToWorkTapped)
        InterventionRuntimeStore.touchAccessibilityHeartbeat(this)
        InterventionPersistenceService.refreshForPolicy(this, "accessibility_connected")
        Log.d(TAG, "Accessibility Service connected; overlay manager ready")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val isWindowEvent = event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            event.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED ||
            event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        if (!isWindowEvent) {
            return
        }

        val currentPackageName = event.packageName?.toString() ?: return
        InterventionRuntimeStore.touchAccessibilityHeartbeat(this, currentPackageName)
        if (!shouldEvaluatePackage(currentPackageName)) {
            return
        }

        // If our own overlay is showing, don't re-trigger
        if (overlayManager?.isOverlayShowing == true) {
            Log.d(TAG, "Overlay already visible; skip evaluation for package=$currentPackageName")
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
        InterventionRuntimeStore.touchAccessibilityHeartbeat(this)
        Log.d(TAG, "Accessibility Service interrupted")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        InterventionRuntimeStore.markAccessibilityDisconnected(this)
        InterventionPersistenceService.refreshForPolicy(this, "accessibility_unbound")
        Log.d(TAG, "Accessibility Service unbound")
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        InterventionRuntimeStore.markAccessibilityDisconnected(this)
        InterventionPersistenceService.refreshForPolicy(this, "accessibility_destroyed")
        stopBlockedPackageWatch("service_destroyed")
        super.onDestroy()
        overlayManager?.dismiss()
        overlayManager = null
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

        if (packageName.startsWith("com.miui.home") ||
            packageName.startsWith("com.mi.android.globallauncher")
        ) {
            return false
        }

        return true
    }

    private fun getBlockingReasonForPackage(packageName: String): UrgencyPolicyReason? {
        return UrgencyNotificationPolicy.getBlockingReasonForPackage(this, packageName)
    }

    private fun triggerHardBlock(packageName: String, reason: UrgencyPolicyReason) {
        lastTriggeredPackage = packageName
        lastTriggeredAtMillis = System.currentTimeMillis()

        saveLastBlockedDebugInfo(packageName, reason)

        // Step 1: Show overlay IMMEDIATELY - this bypasses Android's background
        // startActivity restriction entirely because TYPE_ACCESSIBILITY_OVERLAY
        // is drawn directly by the Accessibility Service.
        Log.d(
            TAG,
            "Showing overlay for package=$packageName task=${reason.taskTitle} " +
                "priority=${reason.priority} remainingMinutes=${reason.remainingMinutes}"
        )
        overlayManager?.show(packageName, reason.taskTitle)

        // Step 2: Send blocked app to home in the background, so it stops running.
        // This is safe AFTER the overlay is already on screen.
        val homeSucceeded = performGlobalAction(GLOBAL_ACTION_HOME)
        Log.d(TAG, "Home action sent: homeSucceeded=$homeSucceeded package=$packageName")
    }

    private fun handleBackToWorkTapped(packageName: String) {
        val homeSucceeded = performGlobalAction(GLOBAL_ACTION_HOME)
        Log.d(
            TAG,
            "Back to work tapped; forcing home before watch: package=$packageName homeSucceeded=$homeSucceeded"
        )
        startBlockedPackageWatch(packageName)
    }

    private fun startBlockedPackageWatch(packageName: String) {
        watchedBlockedPackage = packageName
        watchBlockedPackageUntilMillis =
            System.currentTimeMillis() + POST_DISMISS_WATCH_DURATION_MILLIS
        mainHandler.removeCallbacks(blockedPackageWatchRunnable)
        mainHandler.postDelayed(blockedPackageWatchRunnable, POST_DISMISS_WATCH_INTERVAL_MILLIS)
        Log.d(
            TAG,
            "Started blocked package watch: package=$packageName durationMillis=$POST_DISMISS_WATCH_DURATION_MILLIS"
        )
    }

    private fun stopBlockedPackageWatch(reason: String) {
        mainHandler.removeCallbacks(blockedPackageWatchRunnable)
        watchedBlockedPackage = null
        watchBlockedPackageUntilMillis = 0L
        Log.d(TAG, "Stopped blocked package watch: reason=$reason")
    }

    private fun getActivePackageName(): String? {
        val rootPackageName = rootInActiveWindow?.packageName?.toString()
        if (!rootPackageName.isNullOrBlank()) {
            return rootPackageName
        }

        val activeWindow = windows.firstOrNull { window ->
            window.type == AccessibilityWindowInfo.TYPE_APPLICATION &&
                (window.isActive || window.isFocused)
        }

        return activeWindow?.root?.packageName?.toString()
    }

    private fun isInReentryGuard(packageName: String): Boolean {
        val lastPackage = lastTriggeredPackage ?: return false
        if (lastPackage != packageName) {
            return false
        }

        val elapsedMillis = System.currentTimeMillis() - lastTriggeredAtMillis
        return elapsedMillis in 0 until REENTRY_GUARD_MILLIS
    }

    private fun saveLastBlockedDebugInfo(packageName: String, reason: UrgencyPolicyReason) {
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
