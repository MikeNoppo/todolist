package com.example.todolist

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import kotlin.math.min

object UsageStatsHelper {
    private const val DEFAULT_HISTORY_DAYS = 7
    private const val MAX_HISTORY_DAYS = 31
    private const val MILLIS_PER_SECOND = 1000L

    fun todayStartMs(): Long {
        return startOfDay(Calendar.getInstance()).timeInMillis
    }

    fun queryRangedUsage(
        context: Context,
        packageNames: List<String>,
        startMs: Long,
        endMs: Long
    ): Map<String, Long> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP || startMs >= endMs) {
            return emptyMap()
        }

        val targetPackages = packageNames.filter { it.isNotBlank() }.toSet()
        if (targetPackages.isEmpty()) {
            return emptyMap()
        }

        val usageStatsManager = context.getSystemService(
            Context.USAGE_STATS_SERVICE
        ) as? UsageStatsManager ?: return emptyMap()

        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_BEST,
            startMs,
            endMs
        ) ?: return emptyMap()

        val totals = linkedMapOf<String, Long>()
        for (stat in usageStats) {
            val packageName = stat.packageName ?: continue
            if (!targetPackages.contains(packageName)) {
                continue
            }

            val foregroundMs = stat.totalTimeInForeground
            if (foregroundMs <= 0L) {
                continue
            }

            totals[packageName] = (totals[packageName] ?: 0L) + foregroundMs
        }

        return totals
    }

    fun queryUsageHistory(
        context: Context,
        packageNames: List<String>,
        days: Int = DEFAULT_HISTORY_DAYS
    ): Map<String, Map<String, Long>> {
        val dayCount = days.coerceIn(1, MAX_HISTORY_DAYS)
        val nowMs = System.currentTimeMillis()
        val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val result = linkedMapOf<String, Map<String, Long>>()

        for (offset in dayCount - 1 downTo 0) {
            val dayStart = startOfDay(Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, -offset)
            })
            val dayEnd = Calendar.getInstance().apply {
                timeInMillis = dayStart.timeInMillis
                add(Calendar.DAY_OF_YEAR, 1)
            }
            val startMs = dayStart.timeInMillis
            val endMs = min(dayEnd.timeInMillis, nowMs)
            val dateKey = formatter.format(dayStart.time)

            result[dateKey] = queryRangedUsage(
                context = context,
                packageNames = packageNames,
                startMs = startMs,
                endMs = endMs
            )
        }

        return result
    }

    fun getCurrentSessionMs(context: Context, packageName: String): Long {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP || packageName.isBlank()) {
            return 0L
        }

        val usageStatsManager = context.getSystemService(
            Context.USAGE_STATS_SERVICE
        ) as? UsageStatsManager ?: return 0L

        val nowMs = System.currentTimeMillis()
        val events = usageStatsManager.queryEvents(todayStartMs(), nowMs) ?: return 0L
        val event = UsageEvents.Event()
        var lastForegroundMs = 0L
        var isInForeground = false

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.packageName != packageName) {
                continue
            }

            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    lastForegroundMs = event.timeStamp
                    isInForeground = true
                }
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    isInForeground = false
                    lastForegroundMs = 0L
                }
            }
        }

        if (!isInForeground || lastForegroundMs <= 0L) {
            return 0L
        }

        return ((nowMs - lastForegroundMs) / MILLIS_PER_SECOND) * MILLIS_PER_SECOND
    }

    private fun startOfDay(calendar: Calendar): Calendar {
        return calendar.apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
    }
}
