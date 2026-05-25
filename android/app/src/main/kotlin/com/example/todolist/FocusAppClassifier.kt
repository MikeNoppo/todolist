package com.example.todolist

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import java.util.Locale

enum class FocusCategory(val value: String) {
    SOCIAL("social"),
    GAME("game")
}

object FocusAppClassifier {
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

    fun isFocusApp(context: Context, packageName: String): Boolean {
        return detect(context, packageName) != null
    }

    fun detect(context: Context, packageName: String): FocusCategory? {
        if (packageName.isBlank()) {
            return null
        }

        val packageManager = context.packageManager
        val appInfo = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getApplicationInfo(
                    packageName,
                    PackageManager.ApplicationInfoFlags.of(0L)
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getApplicationInfo(packageName, 0)
            }
        } catch (_: PackageManager.NameNotFoundException) {
            return null
        }

        val appLabel = appInfo.loadLabel(packageManager)?.toString()?.trim().orEmpty()
        return detect(appInfo, packageName, appLabel)
    }

    fun detect(
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
}