package com.example.todolist

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import kotlin.math.max
import kotlin.math.roundToLong

enum class AdaptiveInterventionLevel(
    val storageValue: String,
    val isWarning: Boolean,
    val isBlocking: Boolean
) {
    ALLOW("allow", false, false),
    SOFT_WARNING("soft_warning", true, false),
    STRONG_WARNING("strong_warning", true, false),
    TEMPORARY_BLOCK("temporary_block", false, true),
    HARD_BLOCK("hard_block", false, true)
}

data class AdaptiveInterventionDecision(
    val level: AdaptiveInterventionLevel,
    val usageStatsAvailable: Boolean,
    val currentSessionMs: Long,
    val todayUsageMs: Long,
    val averageDailyUsageMs: Long,
    val warningCount: Int,
    val message: String,
    val reason: String
)

private data class AdaptiveThresholds(
    val softWarningMs: Long,
    val strongWarningMs: Long,
    val temporaryBlockMs: Long,
    val hardBlockMs: Long
)

private data class UsageProfile(
    val averageDailyUsageMs: Long,
    val activeDays: Int,
    val maxDailyUsageMs: Long,
    val riskLevel: UsageRiskLevel
)

private enum class UsageRiskLevel(
    val storageValue: String,
    val thresholdScale: Double,
    val dailyHardMultiplier: Double
) {
    LIGHT("light", 1.0, 1.0),
    MODERATE("moderate", 0.8, 0.85),
    HEAVY("heavy", 0.6, 0.65),
    ABUSIVE("abusive", 0.4, 0.45)
}

object AdaptiveInterventionPolicy {
    private const val TAG = "AdaptivePolicy"

    const val KEY_ADAPTIVE_ENABLED = "flutter.adaptive_intervention_enabled"
    const val KEY_WARNING_COUNT_PREFIX = "flutter.adaptive_warning_count_"
    const val KEY_LAST_WARNING_AT_PREFIX = "flutter.adaptive_last_warning_at_"

    const val KEY_DEBUG_LAST_ADAPTIVE_PACKAGE = "flutter.debug_last_adaptive_package"
    const val KEY_DEBUG_LAST_ADAPTIVE_LEVEL = "flutter.debug_last_adaptive_level"
    const val KEY_DEBUG_LAST_ADAPTIVE_REASON = "flutter.debug_last_adaptive_reason"
    const val KEY_DEBUG_LAST_ADAPTIVE_MESSAGE = "flutter.debug_last_adaptive_message"
    const val KEY_DEBUG_LAST_ADAPTIVE_SESSION_MS = "flutter.debug_last_adaptive_session_ms"
    const val KEY_DEBUG_LAST_ADAPTIVE_TODAY_MS = "flutter.debug_last_adaptive_today_ms"
    const val KEY_DEBUG_LAST_ADAPTIVE_AVERAGE_MS = "flutter.debug_last_adaptive_average_ms"
    const val KEY_DEBUG_LAST_ADAPTIVE_USAGE_STATS_AVAILABLE =
        "flutter.debug_last_adaptive_usage_stats_available"
    const val KEY_DEBUG_LAST_ADAPTIVE_WARNING_COUNT =
        "flutter.debug_last_adaptive_warning_count"
    const val KEY_DEBUG_LAST_ADAPTIVE_AT_MILLIS = "flutter.debug_last_adaptive_at_millis"

    private const val MINUTE_MS = 60L * 1000L
    private const val WARNING_COOLDOWN_MS = 5L * MINUTE_MS
    private const val WARNING_RESET_MS = 2L * 60L * MINUTE_MS
    private const val MIN_ACTIVE_DAY_MS = 5L * MINUTE_MS
    private const val MODERATE_AVERAGE_DAILY_MS = 30L * MINUTE_MS
    private const val HEAVY_AVERAGE_DAILY_MS = 75L * MINUTE_MS
    private const val ABUSIVE_AVERAGE_DAILY_MS = 120L * MINUTE_MS
    private const val MODERATE_MAX_DAILY_MS = 60L * MINUTE_MS
    private const val HEAVY_MAX_DAILY_MS = 150L * MINUTE_MS
    private const val ABUSIVE_MAX_DAILY_MS = 240L * MINUTE_MS

    fun evaluate(
        context: Context,
        packageName: String,
        urgencyReason: UrgencyPolicyReason
    ): AdaptiveInterventionDecision {
        val prefs = UrgencyNotificationPolicy.prefs(context)
        val isAdaptiveEnabled = prefs.getBoolean(KEY_ADAPTIVE_ENABLED, true)
        if (!isAdaptiveEnabled) {
            return legacyHardBlockDecision(context, packageName, urgencyReason)
        }

        val usageStatsAvailable = UsageStatsHelper.hasUsageStatsPermission(context)
        if (!usageStatsAvailable) {
            return fallbackDecisionWithoutUsageStats(prefs, packageName, urgencyReason)
        }

        val currentSessionMs = UsageStatsHelper.getCurrentSessionMs(context, packageName)
        val todayUsageMs = UsageStatsHelper.queryRangedUsage(
            context = context,
            packageNames = listOf(packageName),
            startMs = UsageStatsHelper.todayStartMs(),
            endMs = System.currentTimeMillis()
        )[packageName] ?: 0L
        val usageProfile = calculateUsageProfile(context, packageName)
        val warningCount = getWarningCount(prefs, packageName)
        val thresholds = thresholdsForPriority(urgencyReason.priority, usageProfile)
        val level = decideLevel(
            priority = urgencyReason.priority,
            thresholds = thresholds,
            currentSessionMs = currentSessionMs,
            todayUsageMs = todayUsageMs,
            usageProfile = usageProfile,
            warningCount = warningCount
        )
        val cooledLevel = applyWarningCooldown(
            prefs = prefs,
            packageName = packageName,
            level = level
        )
        val reason = buildReason(
            level = cooledLevel,
            currentSessionMs = currentSessionMs,
            todayUsageMs = todayUsageMs,
            usageProfile = usageProfile,
            thresholds = thresholds,
            warningCount = warningCount
        )

        return AdaptiveInterventionDecision(
            level = cooledLevel,
            usageStatsAvailable = true,
            currentSessionMs = currentSessionMs,
            todayUsageMs = todayUsageMs,
            averageDailyUsageMs = usageProfile.averageDailyUsageMs,
            warningCount = warningCount,
            message = buildMessage(cooledLevel, urgencyReason, currentSessionMs, todayUsageMs),
            reason = reason
        )
    }

    fun recordWarning(context: Context, packageName: String) {
        val prefs = UrgencyNotificationPolicy.prefs(context)
        val warningCount = getWarningCount(prefs, packageName) + 1
        prefs.edit()
            .putInt("$KEY_WARNING_COUNT_PREFIX$packageName", warningCount)
            .putLong("$KEY_LAST_WARNING_AT_PREFIX$packageName", System.currentTimeMillis())
            .apply()
        Log.d(TAG, "Recorded adaptive warning: package=$packageName count=$warningCount")
    }

    fun saveDebugInfo(
        context: Context,
        packageName: String,
        decision: AdaptiveInterventionDecision
    ) {
        UrgencyNotificationPolicy.prefs(context).edit()
            .putString(KEY_DEBUG_LAST_ADAPTIVE_PACKAGE, packageName)
            .putString(KEY_DEBUG_LAST_ADAPTIVE_LEVEL, decision.level.storageValue)
            .putString(KEY_DEBUG_LAST_ADAPTIVE_REASON, decision.reason)
            .putString(KEY_DEBUG_LAST_ADAPTIVE_MESSAGE, decision.message)
            .putLong(KEY_DEBUG_LAST_ADAPTIVE_SESSION_MS, decision.currentSessionMs)
            .putLong(KEY_DEBUG_LAST_ADAPTIVE_TODAY_MS, decision.todayUsageMs)
            .putLong(KEY_DEBUG_LAST_ADAPTIVE_AVERAGE_MS, decision.averageDailyUsageMs)
            .putBoolean(
                KEY_DEBUG_LAST_ADAPTIVE_USAGE_STATS_AVAILABLE,
                decision.usageStatsAvailable
            )
            .putInt(KEY_DEBUG_LAST_ADAPTIVE_WARNING_COUNT, decision.warningCount)
            .putLong(KEY_DEBUG_LAST_ADAPTIVE_AT_MILLIS, System.currentTimeMillis())
            .apply()
    }

    private fun legacyHardBlockDecision(
        context: Context,
        packageName: String,
        urgencyReason: UrgencyPolicyReason
    ): AdaptiveInterventionDecision {
        val currentSessionMs = UsageStatsHelper.getCurrentSessionMs(context, packageName)
        val todayUsageMs = UsageStatsHelper.queryRangedUsage(
            context = context,
            packageNames = listOf(packageName),
            startMs = UsageStatsHelper.todayStartMs(),
            endMs = System.currentTimeMillis()
        )[packageName] ?: 0L
        return AdaptiveInterventionDecision(
            level = AdaptiveInterventionLevel.HARD_BLOCK,
            usageStatsAvailable = UsageStatsHelper.hasUsageStatsPermission(context),
            currentSessionMs = currentSessionMs,
            todayUsageMs = todayUsageMs,
            averageDailyUsageMs = calculateUsageProfile(context, packageName).averageDailyUsageMs,
            warningCount = 0,
            message = "Aplikasi ini diblokir karena ada tugas mendesak.",
            reason = "adaptive_disabled_legacy_hard_block_${urgencyReason.priority}"
        )
    }

    private fun fallbackDecisionWithoutUsageStats(
        prefs: SharedPreferences,
        packageName: String,
        urgencyReason: UrgencyPolicyReason
    ): AdaptiveInterventionDecision {
        val warningCount = getWarningCount(prefs, packageName)
        val level = when (urgencyReason.priority.lowercase()) {
            "high" -> AdaptiveInterventionLevel.HARD_BLOCK
            "medium" -> if (warningCount >= 1) {
                AdaptiveInterventionLevel.TEMPORARY_BLOCK
            } else {
                AdaptiveInterventionLevel.STRONG_WARNING
            }
            else -> if (warningCount >= 2) {
                AdaptiveInterventionLevel.TEMPORARY_BLOCK
            } else {
                AdaptiveInterventionLevel.SOFT_WARNING
            }
        }

        val cooledLevel = applyWarningCooldown(
            prefs = prefs,
            packageName = packageName,
            level = level
        )

        return AdaptiveInterventionDecision(
            level = cooledLevel,
            usageStatsAvailable = false,
            currentSessionMs = 0L,
            todayUsageMs = 0L,
            averageDailyUsageMs = 0L,
            warningCount = warningCount,
            message = buildUsageStatsFallbackMessage(cooledLevel, urgencyReason),
            reason = "usage_stats_unavailable;level=${cooledLevel.storageValue};" +
                "priority=${urgencyReason.priority};warnings=$warningCount"
        )
    }

    private fun calculateUsageProfile(context: Context, packageName: String): UsageProfile {
        val history = UsageStatsHelper.queryUsageHistory(
            context = context,
            packageNames = listOf(packageName),
            days = 7
        )
        if (history.isEmpty()) {
            return UsageProfile(
                averageDailyUsageMs = 0L,
                activeDays = 0,
                maxDailyUsageMs = 0L,
                riskLevel = UsageRiskLevel.LIGHT
            )
        }

        val previousDays = history.entries.toList().dropLast(1)
        if (previousDays.isEmpty()) {
            return UsageProfile(
                averageDailyUsageMs = 0L,
                activeDays = 0,
                maxDailyUsageMs = 0L,
                riskLevel = UsageRiskLevel.LIGHT
            )
        }

        val dailyUsageMs = previousDays.map { entry -> entry.value[packageName] ?: 0L }
        val totalUsageMs = dailyUsageMs.sum()
        val averageDailyUsageMs = totalUsageMs / dailyUsageMs.size
        val activeDays = dailyUsageMs.count { usageMs -> usageMs >= MIN_ACTIVE_DAY_MS }
        val maxDailyUsageMs = dailyUsageMs.maxOrNull() ?: 0L

        return UsageProfile(
            averageDailyUsageMs = averageDailyUsageMs,
            activeDays = activeDays,
            maxDailyUsageMs = maxDailyUsageMs,
            riskLevel = classifyUsageRisk(
                averageDailyUsageMs = averageDailyUsageMs,
                activeDays = activeDays,
                maxDailyUsageMs = maxDailyUsageMs
            )
        )
    }

    private fun classifyUsageRisk(
        averageDailyUsageMs: Long,
        activeDays: Int,
        maxDailyUsageMs: Long
    ): UsageRiskLevel {
        return when {
            averageDailyUsageMs >= ABUSIVE_AVERAGE_DAILY_MS ||
                maxDailyUsageMs >= ABUSIVE_MAX_DAILY_MS ||
                (activeDays >= 5 && averageDailyUsageMs >= 90L * MINUTE_MS) ->
                UsageRiskLevel.ABUSIVE
            averageDailyUsageMs >= HEAVY_AVERAGE_DAILY_MS ||
                maxDailyUsageMs >= HEAVY_MAX_DAILY_MS ||
                (activeDays >= 5 && averageDailyUsageMs >= 45L * MINUTE_MS) ->
                UsageRiskLevel.HEAVY
            averageDailyUsageMs >= MODERATE_AVERAGE_DAILY_MS ||
                maxDailyUsageMs >= MODERATE_MAX_DAILY_MS ||
                (activeDays >= 4 && averageDailyUsageMs >= 15L * MINUTE_MS) ->
                UsageRiskLevel.MODERATE
            else -> UsageRiskLevel.LIGHT
        }
    }

    private fun decideLevel(
        priority: String,
        thresholds: AdaptiveThresholds,
        currentSessionMs: Long,
        todayUsageMs: Long,
        usageProfile: UsageProfile,
        warningCount: Int
    ): AdaptiveInterventionLevel {
        val dailyHardMs = dailyHardBlockMs(thresholds, usageProfile)
        val adaptiveStrongMs = max(thresholds.strongWarningMs, (dailyHardMs * 0.45).roundToLong())
        val adaptiveTemporaryMs = max(thresholds.temporaryBlockMs, (dailyHardMs * 0.75).roundToLong())

        if (currentSessionMs >= thresholds.hardBlockMs || todayUsageMs >= dailyHardMs) {
            return AdaptiveInterventionLevel.HARD_BLOCK
        }

        if (currentSessionMs >= thresholds.temporaryBlockMs ||
            todayUsageMs >= adaptiveTemporaryMs ||
            (warningCount >= 3 && currentSessionMs >= thresholds.strongWarningMs)
        ) {
            return AdaptiveInterventionLevel.TEMPORARY_BLOCK
        }

        if (currentSessionMs >= thresholds.strongWarningMs ||
            todayUsageMs >= adaptiveStrongMs ||
            (warningCount >= 1 && currentSessionMs >= thresholds.softWarningMs)
        ) {
            return AdaptiveInterventionLevel.STRONG_WARNING
        }

        if (priority.lowercase() == "high" ||
            currentSessionMs >= thresholds.softWarningMs ||
            todayUsageMs >= thresholds.softWarningMs
        ) {
            return AdaptiveInterventionLevel.SOFT_WARNING
        }

        return AdaptiveInterventionLevel.ALLOW
    }

    private fun applyWarningCooldown(
        prefs: SharedPreferences,
        packageName: String,
        level: AdaptiveInterventionLevel
    ): AdaptiveInterventionLevel {
        if (!level.isWarning) {
            return level
        }

        val lastWarningAt = prefs.getLong("$KEY_LAST_WARNING_AT_PREFIX$packageName", 0L)
        if (lastWarningAt <= 0L) {
            return level
        }

        val elapsedMs = System.currentTimeMillis() - lastWarningAt
        if (elapsedMs in 0 until WARNING_COOLDOWN_MS) {
            return AdaptiveInterventionLevel.ALLOW
        }

        return level
    }

    private fun getWarningCount(prefs: SharedPreferences, packageName: String): Int {
        val lastWarningAt = prefs.getLong("$KEY_LAST_WARNING_AT_PREFIX$packageName", 0L)
        if (lastWarningAt > 0L && System.currentTimeMillis() - lastWarningAt > WARNING_RESET_MS) {
            prefs.edit()
                .remove("$KEY_WARNING_COUNT_PREFIX$packageName")
                .remove("$KEY_LAST_WARNING_AT_PREFIX$packageName")
                .apply()
            return 0
        }

        return prefs.getInt("$KEY_WARNING_COUNT_PREFIX$packageName", 0).coerceAtLeast(0)
    }

    private fun thresholdsForPriority(
        priority: String,
        usageProfile: UsageProfile
    ): AdaptiveThresholds {
        val base = baseThresholdsForPriority(priority)
        val minimum = minimumThresholdsForPriority(priority)

        return AdaptiveThresholds(
            softWarningMs = scaledThreshold(base.softWarningMs, minimum.softWarningMs, usageProfile),
            strongWarningMs = scaledThreshold(
                base.strongWarningMs,
                minimum.strongWarningMs,
                usageProfile
            ),
            temporaryBlockMs = scaledThreshold(
                base.temporaryBlockMs,
                minimum.temporaryBlockMs,
                usageProfile
            ),
            hardBlockMs = scaledThreshold(base.hardBlockMs, minimum.hardBlockMs, usageProfile)
        )
    }

    private fun baseThresholdsForPriority(priority: String): AdaptiveThresholds {
        return when (priority.lowercase()) {
            "high" -> AdaptiveThresholds(
                softWarningMs = 5L * MINUTE_MS,
                strongWarningMs = 10L * MINUTE_MS,
                temporaryBlockMs = 30L * MINUTE_MS,
                hardBlockMs = 60L * MINUTE_MS
            )
            "medium" -> AdaptiveThresholds(
                softWarningMs = 10L * MINUTE_MS,
                strongWarningMs = 20L * MINUTE_MS,
                temporaryBlockMs = 45L * MINUTE_MS,
                hardBlockMs = 90L * MINUTE_MS
            )
            else -> AdaptiveThresholds(
                softWarningMs = 15L * MINUTE_MS,
                strongWarningMs = 30L * MINUTE_MS,
                temporaryBlockMs = 60L * MINUTE_MS,
                hardBlockMs = 120L * MINUTE_MS
            )
        }
    }

    private fun minimumThresholdsForPriority(priority: String): AdaptiveThresholds {
        return when (priority.lowercase()) {
            "high" -> AdaptiveThresholds(
                softWarningMs = 2L * MINUTE_MS,
                strongWarningMs = 5L * MINUTE_MS,
                temporaryBlockMs = 10L * MINUTE_MS,
                hardBlockMs = 15L * MINUTE_MS
            )
            "medium" -> AdaptiveThresholds(
                softWarningMs = 3L * MINUTE_MS,
                strongWarningMs = 8L * MINUTE_MS,
                temporaryBlockMs = 15L * MINUTE_MS,
                hardBlockMs = 25L * MINUTE_MS
            )
            else -> AdaptiveThresholds(
                softWarningMs = 5L * MINUTE_MS,
                strongWarningMs = 10L * MINUTE_MS,
                temporaryBlockMs = 20L * MINUTE_MS,
                hardBlockMs = 40L * MINUTE_MS
            )
        }
    }

    private fun scaledThreshold(
        baseMs: Long,
        minimumMs: Long,
        usageProfile: UsageProfile
    ): Long {
        return max(minimumMs, (baseMs * usageProfile.riskLevel.thresholdScale).roundToLong())
    }

    private fun dailyHardBlockMs(
        thresholds: AdaptiveThresholds,
        usageProfile: UsageProfile
    ): Long {
        return max(
            thresholds.hardBlockMs,
            (usageProfile.averageDailyUsageMs * usageProfile.riskLevel.dailyHardMultiplier)
                .roundToLong()
        )
    }

    private fun buildMessage(
        level: AdaptiveInterventionLevel,
        urgencyReason: UrgencyPolicyReason,
        currentSessionMs: Long,
        todayUsageMs: Long
    ): String {
        val sessionText = formatDuration(currentSessionMs)
        val todayText = formatDuration(todayUsageMs)
        val priorityText = when (urgencyReason.priority.lowercase()) {
            "high" -> "prioritas tinggi"
            "medium" -> "prioritas sedang"
            else -> "prioritas rendah"
        }

        return when (level) {
            AdaptiveInterventionLevel.ALLOW -> "Masih dalam batas adaptif."
            AdaptiveInterventionLevel.SOFT_WARNING ->
                "Kamu punya tugas $priorityText. Rehat sebentar boleh, tapi sesi ini sudah $sessionText."
            AdaptiveInterventionLevel.STRONG_WARNING ->
                "Waktu distraksi hari ini sudah $todayText. Sebaiknya kembali ke tugas: ${urgencyReason.taskTitle}."
            AdaptiveInterventionLevel.TEMPORARY_BLOCK ->
                "Sesi distraksi sudah terlalu panjang. myTask menahan aplikasi ini sementara agar kamu kembali fokus."
            AdaptiveInterventionLevel.HARD_BLOCK ->
                "Batas distraksi sudah tercapai hari ini. Selesaikan tugas mendesak sebelum membuka aplikasi ini lagi."
        }
    }

    private fun buildUsageStatsFallbackMessage(
        level: AdaptiveInterventionLevel,
        urgencyReason: UrgencyPolicyReason
    ): String {
        return when (level) {
            AdaptiveInterventionLevel.ALLOW -> "Usage Access belum tersedia, evaluasi adaptif ditunda."
            AdaptiveInterventionLevel.SOFT_WARNING,
            AdaptiveInterventionLevel.STRONG_WARNING ->
                "Usage Access belum aktif. Aktifkan izin agar myTask bisa menilai waktu distraksi dengan akurat."
            AdaptiveInterventionLevel.TEMPORARY_BLOCK,
            AdaptiveInterventionLevel.HARD_BLOCK ->
                "Usage Access belum aktif, jadi myTask memakai proteksi konservatif untuk tugas mendesak: ${urgencyReason.taskTitle}."
        }
    }

    private fun buildReason(
        level: AdaptiveInterventionLevel,
        currentSessionMs: Long,
        todayUsageMs: Long,
        usageProfile: UsageProfile,
        thresholds: AdaptiveThresholds,
        warningCount: Int
    ): String {
        val dailyHardMs = dailyHardBlockMs(thresholds, usageProfile)
        return "level=${level.storageValue};sessionMs=$currentSessionMs;" +
            "todayMs=$todayUsageMs;averageDailyMs=${usageProfile.averageDailyUsageMs};" +
            "maxDailyMs=${usageProfile.maxDailyUsageMs};activeDays=${usageProfile.activeDays};" +
            "usageRisk=${usageProfile.riskLevel.storageValue};" +
            "sessionHardMs=${thresholds.hardBlockMs};dailyHardMs=$dailyHardMs;" +
            "warnings=$warningCount"
    }

    private fun formatDuration(durationMs: Long): String {
        val totalMinutes = (durationMs / MINUTE_MS).coerceAtLeast(0L)
        val hours = totalMinutes / 60L
        val minutes = totalMinutes % 60L

        if (hours > 0L && minutes > 0L) {
            return "${hours}j ${minutes}m"
        }

        if (hours > 0L) {
            return "${hours}j"
        }

        return "${minutes}m"
    }
}
