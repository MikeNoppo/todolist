package com.example.todolist

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Locale

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        const val EXTRA_BLOCKED_PACKAGE = "blocked_package"

        @Volatile
        private var pendingBlockedPackage: String? = null

        @JvmStatic
        fun queueBlockedPackage(packageName: String) {
            pendingBlockedPackage = packageName
            Log.d(TAG, "Queued blocked package: package=$packageName")
        }

        @JvmStatic
        fun acknowledgeQueuedBlockedPackage(packageName: String?): Boolean {
            val acknowledged = !packageName.isNullOrBlank() &&
                packageName == pendingBlockedPackage
            if (acknowledged) {
                pendingBlockedPackage = null
            }
            Log.d(TAG, "acknowledgeQueuedBlockedPackage called: package=$packageName acknowledged=$acknowledged")
            return acknowledged
        }
    }

    private val CHANNEL = "app_blocker/permissions"
    private var methodChannel: MethodChannel? = null
    private val socialKeywords = listOf(
        "facebook",
        "instagram",
        "twitter",
        "threads",
        "snapchat",
        "tiktok",
        "whatsapp",
        "telegram",
        "discord",
        "line",
        "wechat",
        "messenger",
        "reddit",
        "pinterest",
        "linkedin",
        "youtube",
        "brave",
        "viber",
        "signal",
        "zalo",
        "skype"
    )
    private val gameKeywords = listOf(
        "game",
        "games",
        "roblox",
        "mlbb",
        "mobilelegends",
        "pubg",
        "freefire",
        "genshin",
        "honkai",
        "clashofclans",
        "clashroyale",
        "pokemon",
        "subwaysurf",
        "candycrush"
    )

    private enum class FocusCategory(val value: String) {
        SOCIAL("social"),
        GAME("game")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        InterventionPersistenceService.refreshForPolicy(this, "main_activity_created")
        consumeBlockedPackageFromIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        consumeBlockedPackageFromIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(null)
                }
                "isUsageStatsPermissionGranted" -> {
                    result.success(isUsageStatsPermissionGranted())
                }
                "openUsageStatsSettings" -> {
                    openUsageStatsSettings()
                    result.success(null)
                }
                "isNotificationListenerAccessGranted" -> {
                    result.success(UrgencyNotificationControlManager.hasNotificationListenerAccess(this))
                }
                "openNotificationListenerSettings" -> {
                    openNotificationListenerSettings()
                    result.success(null)
                }
                "isDoNotDisturbAccessGranted" -> {
                    result.success(UrgencyNotificationControlManager.hasDoNotDisturbAccess(this))
                }
                "openDoNotDisturbSettings" -> {
                    openDoNotDisturbSettings()
                    result.success(null)
                }
                "syncNotificationInterruptionState" -> {
                    val synced = UrgencyNotificationControlManager.sync(
                        this,
                        "method_channel_sync"
                    )
                    InterventionPersistenceService.refreshForPolicy(
                        this,
                        "method_channel_sync"
                    )
                    result.success(synced)
                }
                "consumeBlockedPackage" -> {
                    val blockedPackage = pendingBlockedPackage
                    pendingBlockedPackage = null
                    Log.d(TAG, "consumeBlockedPackage called: package=$blockedPackage")
                    result.success(blockedPackage)
                }
                "peekBlockedPackage" -> {
                    Log.d(TAG, "peekBlockedPackage called: package=$pendingBlockedPackage")
                    result.success(pendingBlockedPackage)
                }
                "acknowledgeBlockedPackage" -> {
                    val packageName = call.argument<String>("packageName")
                    val acknowledged = !packageName.isNullOrBlank() &&
                        packageName == pendingBlockedPackage
                    if (acknowledged) {
                        pendingBlockedPackage = null
                    }

                    Log.d(
                        TAG,
                        "acknowledgeBlockedPackage called: package=$packageName acknowledged=$acknowledged"
                    )
                    result.success(acknowledged)
                }
                "getInstalledFocusApps" -> {
                    result.success(getInstalledFocusApps())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        pendingBlockedPackage?.let { packageName ->
            notifyBlockedPackageQueued(packageName)
        }
    }

    private fun consumeBlockedPackageFromIntent(intent: Intent?) {
        val blockedPackage = intent?.getStringExtra(EXTRA_BLOCKED_PACKAGE)
        if (!blockedPackage.isNullOrBlank()) {
            queueBlockedPackage(blockedPackage)
            Log.d(TAG, "Received blocked package from intent: package=$blockedPackage")
            notifyBlockedPackageQueued(blockedPackage)
        }
    }

    private fun notifyBlockedPackageQueued(packageName: String) {
        try {
            methodChannel?.invokeMethod("blockedPackageQueued", packageName)
            Log.d(TAG, "Notified Flutter blocked package queued: package=$packageName")
        } catch (error: Exception) {
            Log.w(TAG, "Failed notifying Flutter blocked package queued: package=$packageName", error)
        }
    }

    private fun getInstalledFocusApps(): List<Map<String, Any>> {
        val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.queryIntentActivities(
                launcherIntent,
                android.content.pm.PackageManager.ResolveInfoFlags.of(0L)
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentActivities(launcherIntent, 0)
        }

        val apps = mutableListOf<Map<String, Any>>()

        for (resolveInfo in resolveInfos) {
            val activityInfo = resolveInfo.activityInfo ?: continue
            val appInfo = activityInfo.applicationInfo ?: continue
            val packageId = activityInfo.packageName ?: continue

            if (packageId == packageName || isSystemApp(appInfo)) {
                continue
            }

            val appLabel = resolveInfo.loadLabel(packageManager)?.toString()?.trim().orEmpty()
            if (appLabel.isEmpty()) {
                continue
            }

            val focusCategory = detectFocusCategory(appInfo, packageId, appLabel) ?: continue
            val iconBytes = drawableToPngBytes(resolveInfo.loadIcon(packageManager))

            apps.add(
                mapOf(
                    "packageName" to packageId,
                    "appName" to appLabel,
                    "category" to focusCategory.value,
                    "iconBytes" to iconBytes
                )
            )
        }

        return apps.sortedWith(
            compareBy<Map<String, Any>>(
                { if ((it["category"] as String) == FocusCategory.SOCIAL.value) 0 else 1 },
                { (it["appName"] as String).lowercase(Locale.US) }
            )
        )
    }

    private fun detectFocusCategory(
        appInfo: ApplicationInfo,
        packageId: String,
        appLabel: String
    ): FocusCategory? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            when (appInfo.category) {
                ApplicationInfo.CATEGORY_GAME -> return FocusCategory.GAME
                ApplicationInfo.CATEGORY_SOCIAL -> return FocusCategory.SOCIAL
            }
        }

        val packageLower = packageId.lowercase(Locale.US)
        val labelLower = appLabel.lowercase(Locale.US)

        if (containsKeyword(packageLower, labelLower, socialKeywords)) {
            return FocusCategory.SOCIAL
        }

        if (containsKeyword(packageLower, labelLower, gameKeywords)) {
            return FocusCategory.GAME
        }

        return null
    }

    private fun containsKeyword(
        packageName: String,
        appLabel: String,
        keywords: List<String>
    ): Boolean {
        return keywords.any { keyword ->
            packageName.contains(keyword) || appLabel.contains(keyword)
        }
    }

    private fun isSystemApp(appInfo: ApplicationInfo): Boolean {
        val isSystem = appInfo.flags and ApplicationInfo.FLAG_SYSTEM != 0
        val isUpdatedSystem = appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP != 0
        return isSystem && !isUpdatedSystem
    }

    private fun drawableToPngBytes(drawable: Drawable): ByteArray {
        val baseBitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
            val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
            Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).apply {
                val canvas = Canvas(this)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
            }
        }

        val iconBitmap = scaleBitmapIfNeeded(baseBitmap, maxSize = 96)
        val stream = ByteArrayOutputStream()
        iconBitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    private fun scaleBitmapIfNeeded(bitmap: Bitmap, maxSize: Int): Bitmap {
        if (bitmap.width <= maxSize && bitmap.height <= maxSize) {
            return bitmap
        }

        val scale = minOf(maxSize.toFloat() / bitmap.width, maxSize.toFloat() / bitmap.height)
        val targetWidth = (bitmap.width * scale).toInt().coerceAtLeast(1)
        val targetHeight = (bitmap.height * scale).toInt().coerceAtLeast(1)

        return Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        return AccessibilityServiceUtils.isAppBlockerServiceEnabled(this)
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }

    private fun isUsageStatsPermissionGranted(): Boolean {
        val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOpsManager.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOpsManager.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }

        if (mode == AppOpsManager.MODE_ALLOWED) {
            return true
        }

        if (mode != AppOpsManager.MODE_DEFAULT) {
            return false
        }

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val lookbackWindowMillis = 24L * 60L * 60L * 1000L
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            time - lookbackWindowMillis,
            time
        )
        return stats != null && stats.isNotEmpty()
    }

    private fun openUsageStatsSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    private fun openNotificationListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }

    private fun openDoNotDisturbSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
        } else {
            Intent(Settings.ACTION_SETTINGS)
        }
        startActivity(intent)
    }
}
