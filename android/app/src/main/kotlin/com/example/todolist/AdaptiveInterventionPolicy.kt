package com.example.todolist

enum class InterventionLevel {
    ALLOW,
    SOFT_WARNING,
    STRONG_WARNING,
    TEMPORARY_BLOCK,
    HARD_BLOCK
}

data class AdaptiveDecision(
    val level: InterventionLevel,
    val reason: String,
    val message: String,
    val remainingGraceMs: Long = 0L
)

object AdaptiveInterventionPolicy {
    // High Priority
    private const val HIGH_SOFT_WARNING_MS = 5L * 60L * 1000L      // 5 min
    private const val HIGH_STRONG_WARNING_MS = 10L * 60L * 1000L   // 10 min
    private const val HIGH_TEMP_BLOCK_MS = 30L * 60L * 1000L       // 30 min
    private const val HIGH_HARD_BLOCK_MS = 60L * 60L * 1000L       // 60 min

    // Medium Priority
    private const val MEDIUM_SOFT_WARNING_MS = 10L * 60L * 1000L   // 10 min
    private const val MEDIUM_STRONG_WARNING_MS = 20L * 60L * 1000L // 20 min
    private const val MEDIUM_TEMP_BLOCK_MS = 45L * 60L * 1000L     // 45 min
    private const val MEDIUM_HARD_BLOCK_MS = 90L * 60L * 1000L     // 90 min

    // Low Priority
    private const val LOW_SOFT_WARNING_MS = 15L * 60L * 1000L      // 15 min
    private const val LOW_STRONG_WARNING_MS = 30L * 60L * 1000L    // 30 min
    private const val LOW_TEMP_BLOCK_MS = 60L * 60L * 1000L        // 60 min
    private const val LOW_HARD_BLOCK_MS = 120L * 60L * 1000L       // 120 min

    fun evaluate(currentSessionMs: Long, priority: String): AdaptiveDecision {
        val softMs: Long
        val strongMs: Long
        val tempBlockMs: Long
        val hardBlockMs: Long

        when (priority.lowercase()) {
            "high" -> {
                softMs = HIGH_SOFT_WARNING_MS
                strongMs = HIGH_STRONG_WARNING_MS
                tempBlockMs = HIGH_TEMP_BLOCK_MS
                hardBlockMs = HIGH_HARD_BLOCK_MS
            }
            "medium" -> {
                softMs = MEDIUM_SOFT_WARNING_MS
                strongMs = MEDIUM_STRONG_WARNING_MS
                tempBlockMs = MEDIUM_TEMP_BLOCK_MS
                hardBlockMs = MEDIUM_HARD_BLOCK_MS
            }
            else -> {
                softMs = LOW_SOFT_WARNING_MS
                strongMs = LOW_STRONG_WARNING_MS
                tempBlockMs = LOW_TEMP_BLOCK_MS
                hardBlockMs = LOW_HARD_BLOCK_MS
            }
        }

        if (currentSessionMs >= hardBlockMs) {
            return AdaptiveDecision(
                level = InterventionLevel.HARD_BLOCK,
                reason = "Exceeded hard block threshold",
                message = "Aplikasi diblokir karena kamu sudah terlalu lama membuka aplikasi ini, sedangkan ada tugas penting."
            )
        } else if (currentSessionMs >= tempBlockMs) {
            return AdaptiveDecision(
                level = InterventionLevel.TEMPORARY_BLOCK,
                reason = "Exceeded temporary block threshold",
                message = "Kamu harus kembali mengerjakan tugasmu sekarang.",
                remainingGraceMs = hardBlockMs - currentSessionMs
            )
        } else if (currentSessionMs >= strongMs) {
            return AdaptiveDecision(
                level = InterventionLevel.STRONG_WARNING,
                reason = "Exceeded strong warning threshold",
                message = "Peringatan: Kamu sudah cukup lama membuka aplikasi ini. Segera selesaikan tugasmu.",
                remainingGraceMs = tempBlockMs - currentSessionMs
            )
        } else if (currentSessionMs >= softMs) {
            return AdaptiveDecision(
                level = InterventionLevel.SOFT_WARNING,
                reason = "Exceeded soft warning threshold",
                message = "Kamu punya tugas penting. Ambil jeda sebentar boleh, tapi jangan terlalu lama.",
                remainingGraceMs = strongMs - currentSessionMs
            )
        }

        return AdaptiveDecision(
            level = InterventionLevel.ALLOW,
            reason = "Session duration below warning threshold",
            message = ""
        )
    }
}
