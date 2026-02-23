package com.example.todolist

import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils.SimpleStringSplitter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Locale

class MainActivity : FlutterActivity() {
    companion object {
        const val EXTRA_BLOCKED_PACKAGE = "blocked_package"

        @Volatile
        private var pendingBlockedPackage: String? = null
    }

    private val CHANNEL = "app_blocker/permissions"
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
        consumeBlockedPackageFromIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        consumeBlockedPackageFromIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                "consumeBlockedPackage" -> {
                    val blockedPackage = pendingBlockedPackage
                    pendingBlockedPackage = null
                    result.success(blockedPackage)
                }
                "getInstalledFocusApps" -> {
                    result.success(getInstalledFocusApps())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun consumeBlockedPackageFromIntent(intent: Intent?) {
        val blockedPackage = intent?.getStringExtra(EXTRA_BLOCKED_PACKAGE)
        if (!blockedPackage.isNullOrBlank()) {
            pendingBlockedPackage = blockedPackage
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
        val accessibilityEnabled = Settings.Secure.getInt(
            contentResolver,
            Settings.Secure.ACCESSIBILITY_ENABLED, 0
        )
        
        if (accessibilityEnabled == 1) {
            val settingValue = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            
            if (settingValue != null) {
                val splitter = SimpleStringSplitter(':')
                splitter.setString(settingValue)
                while (splitter.hasNext()) {
                    val accessibilityService = splitter.next()
                    if (accessibilityService.equals(
                            ComponentName(this, AppBlockerAccessibilityService::class.java).flattenToString(),
                            ignoreCase = true
                        )) {
                        return true
                    }
                }
            }
        }
        return false
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }

    private fun isUsageStatsPermissionGranted(): Boolean {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            time - 1000 * 10,
            time
        )
        return stats != null && stats.isNotEmpty()
    }

    private fun openUsageStatsSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }
}
