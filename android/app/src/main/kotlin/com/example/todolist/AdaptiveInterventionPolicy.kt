package com.example.todolist

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import kotlin.math.max

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
    const val KEY_DEBUG_LAST_ADAPTIVE_WARNING_COUNT =
        "flutter.debug_last_adaptive_warning_count"
    const val KEY_DEBUG_LAST_ADAPTIVE_AT_MILLIS = "flutter.debug_last_adaptive_at_millis"

    private const val MINUTE_MS = 60L * 1000L
    private const val WARNING_COOLDOWN_MS = 5L * MINUTE_MS
    private const val WARNING_RESET_MS = 2L * 60L * MINUTE_MS

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

        val currentSessionMs = UsageStatsHelper.getCurrentSessionMs(context, packageName)
        val todayUsageMs = UsageStatsHelper.queryRangedUsage(
            context = context,
            packageNames = listOf(packageName),
            startMs = UsageStatsHelper.todayStartMs(),
            endMs = System.currentTimeMillis()
        )[packageName] ?: 0L
        val averageDailyUsageMs = calculateAverageDailyUsageMs(context, packageName)
        val warningCount = getWarningCount(prefs, packageName)
        val thresholds = thresholdsForPriority(urgencyReason.priority)
        val level = decideLevel(
            priority = urgencyReason.priority,
            thresholds = thresholds,
            currentSessionMs = currentSessionMs,
            todayUsageMs = todayUsageMs,
            averageDailyUsageMs = averageDailyUsageMs,
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
            averageDailyUsageMs = averageDailyUsageMs,
            warningCount = warningCount
        )

        return AdaptiveInterventionDecision(
            level = cooledLevel,
            currentSessionMs = currentSessionMs,
            todayUsageMs = todayUsageMs,
            averageDailyUsageMs = averageDailyUsageMs,
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
            currentSessionMs = currentSessionMs,
            todayUsageMs = todayUsageMs,
            averageDailyUsageMs = calculateAverageDailyUsageMs(context, packageName),
            warningCount = 0,
            message = "Aplikasi ini diblokir karena ada tugas mendesak.",
            reason = "adaptive_disabled_legacy_hard_block_${urgencyReason.priority}"
        )
    }

    private fun calculateAverageDailyUsageMs(context: Context, packageName: String): Long {
        val history = UsageStatsHelper.queryUsageHistory(
            context = context,
            packageNames = listOf(packageName),
            days = 7
        )
        if (history.isEmpty()) {
            return 0L
        }

        val previousDays = history.entries.toList().dropLast(1)
        if (previousDays.isEmpty()) {
            return 0L
        }

        val totalUsageMs = previousDays.sumOf { entry ->
            entry.value[packageName] ?: 0L
        }

        return totalUsageMs / previousDays.size
    }

    private fun decideLevel(
        priority: String,
        thresholds: AdaptiveThresholds,
        currentSessionMs: Long,
        todayUsageMs: Long,
        averageDailyUsageMs: Long,
        warningCount: Int
    ): AdaptiveInterventionLevel {
        val adaptiveStrongMs = max(thresholds.strongWarningMs, (averageDailyUsageMs * 0.85).toLong())
        val adaptiveTemporaryMs = max(thresholds.temporaryBlockMs, averageDailyUsageMs)
        val adaptiveHardMs = max(thresholds.hardBlockMs, (averageDailyUsageMs * 1.5).toLong())

        if (currentSessionMs >= thresholds.hardBlockMs || todayUsageMs >= adaptiveHardMs) {
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

        if (priority == "high" ||
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

    private fun thresholdsForPriority(priority: String): AdaptiveThresholds {
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

    private fun buildReason(
        level: AdaptiveInterventionLevel,
        currentSessionMs: Long,
        todayUsageMs: Long,
        averageDailyUsageMs: Long,
        warningCount: Int
    ): String {
        return "level=${level.storageValue};sessionMs=$currentSessionMs;" +
            "todayMs=$todayUsageMs;averageDailyMs=$averageDailyUsageMs;warnings=$warningCount"
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
