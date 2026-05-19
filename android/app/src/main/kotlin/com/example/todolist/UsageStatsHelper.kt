package com.example.todolist

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Process
import android.util.Log
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

object UsageStatsHelper {
    private const val TAG = "UsageStatsHelper"
    private const val DEFAULT_HISTORY_DAYS = 7
    private const val MAX_HISTORY_DAYS = 31
    private const val MILLIS_PER_SECOND = 1000L
    private const val CURRENT_SESSION_QUERY_CHUNK_MS = 15L * 60L * MILLIS_PER_SECOND
    private const val MIN_CURRENT_SESSION_QUERY_CHUNK_MS = 60L * MILLIS_PER_SECOND

    private data class SessionBoundaryEvent(
        val eventType: Int,
        val timestampMs: Long
    )

    fun todayStartMs(): Long {
        return startOfDay(Calendar.getInstance()).timeInMillis
    }

    fun hasUsageStatsPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return false
        }

        val appOpsManager = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOpsManager.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOpsManager.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }

        if (mode == AppOpsManager.MODE_ALLOWED) {
            return true
        }

        if (mode != AppOpsManager.MODE_DEFAULT) {
            return false
        }

        val usageStatsManager = context.getSystemService(
            Context.USAGE_STATS_SERVICE
        ) as? UsageStatsManager ?: return false
        val nowMs = System.currentTimeMillis()
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            nowMs - 24L * 60L * 60L * 1000L,
            nowMs
        )

        return !stats.isNullOrEmpty()
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
        return getCurrentSessionsMs(context, listOf(packageName))[packageName] ?: 0L
    }

    fun getCurrentSessionsMs(context: Context, packageNames: List<String>): Map<String, Long> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return emptyMap()
        }

        val targetPackages = packageNames.filter { it.isNotBlank() }.toSet()
        if (targetPackages.isEmpty()) {
            return emptyMap()
        }

        val usageStatsManager = context.getSystemService(
            Context.USAGE_STATS_SERVICE
        ) as? UsageStatsManager ?: return emptyMap()

        val nowMs = System.currentTimeMillis()
        val dayStartMs = todayStartMs()
        val latestEvents = mutableMapOf<String, SessionBoundaryEvent>()
        val unresolvedPackages = targetPackages.toMutableSet()
        var chunkEndMs = nowMs

        while (chunkEndMs > dayStartMs && unresolvedPackages.isNotEmpty()) {
            val chunkStartMs = max(dayStartMs, chunkEndMs - CURRENT_SESSION_QUERY_CHUNK_MS)
            val chunkEvents = queryLatestSessionEvents(
                usageStatsManager = usageStatsManager,
                targetPackages = unresolvedPackages,
                startMs = chunkStartMs,
                endMs = chunkEndMs
            )

            for ((trackedPackageName, sessionEvent) in chunkEvents) {
                latestEvents[trackedPackageName] = sessionEvent
                unresolvedPackages.remove(trackedPackageName)
            }

            chunkEndMs = chunkStartMs
        }

        return targetPackages.associateWith { trackedPackageName ->
            val latestEvent = latestEvents[trackedPackageName]
            if (latestEvent == null || !isForegroundEvent(latestEvent.eventType)) {
                0L
            } else {
                ((nowMs - latestEvent.timestampMs).coerceAtLeast(0L) / MILLIS_PER_SECOND) *
                    MILLIS_PER_SECOND
            }
        }
    }

    private fun queryLatestSessionEvents(
        usageStatsManager: UsageStatsManager,
        targetPackages: Set<String>,
        startMs: Long,
        endMs: Long
    ): Map<String, SessionBoundaryEvent> {
        if (targetPackages.isEmpty() || startMs >= endMs) {
            return emptyMap()
        }

        return try {
            readLatestSessionEvents(
                usageStatsManager = usageStatsManager,
                targetPackages = targetPackages,
                startMs = startMs,
                endMs = endMs
            )
        } catch (error: Throwable) {
            val durationMs = endMs - startMs
            if (durationMs <= MIN_CURRENT_SESSION_QUERY_CHUNK_MS) {
                Log.w(TAG, "Skipping usage events chunk after Binder failure.", error)
                emptyMap()
            } else {
                val midpointMs = startMs + durationMs / 2L
                val olderEvents = queryLatestSessionEvents(
                    usageStatsManager = usageStatsManager,
                    targetPackages = targetPackages,
                    startMs = startMs,
                    endMs = midpointMs
                )
                val newerEvents = queryLatestSessionEvents(
                    usageStatsManager = usageStatsManager,
                    targetPackages = targetPackages,
                    startMs = midpointMs,
                    endMs = endMs
                )
                olderEvents.toMutableMap().apply { putAll(newerEvents) }
            }
        }
    }

    private fun readLatestSessionEvents(
        usageStatsManager: UsageStatsManager,
        targetPackages: Set<String>,
        startMs: Long,
        endMs: Long
    ): Map<String, SessionBoundaryEvent> {
        val events = usageStatsManager.queryEvents(startMs, endMs) ?: return emptyMap()
        val latestEvents = mutableMapOf<String, SessionBoundaryEvent>()
        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)

            val eventPackageName = event.packageName ?: continue
            if (!targetPackages.contains(eventPackageName) ||
                !isSessionBoundaryEvent(event.eventType)
            ) {
                continue
            }

            latestEvents[eventPackageName] = SessionBoundaryEvent(
                eventType = event.eventType,
                timestampMs = event.timeStamp
            )
        }

        return latestEvents
    }

    private fun isSessionBoundaryEvent(eventType: Int): Boolean {
        return isForegroundEvent(eventType) || isBackgroundEvent(eventType)
    }

    private fun isForegroundEvent(eventType: Int): Boolean {
        return eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
            (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                eventType == UsageEvents.Event.ACTIVITY_RESUMED)
    }

    private fun isBackgroundEvent(eventType: Int): Boolean {
        return eventType == UsageEvents.Event.MOVE_TO_BACKGROUND ||
            (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                eventType == UsageEvents.Event.ACTIVITY_PAUSED)
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
