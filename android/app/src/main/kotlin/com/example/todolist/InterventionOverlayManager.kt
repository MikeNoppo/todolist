package com.example.todolist

import android.content.Context
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.HapticFeedbackConstants
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

class InterventionOverlayManager(
    private val context: Context,
    private val onBackToWorkTapped: (String) -> Unit
) {

    companion object {
        private const val TAG = "InterventionOverlay"

        private val QUOTES = listOf(
            Pair(
                "\"Penundaan adalah pembunuh alami kesempatan.\"",
                "— Victor Kiam"
            ),
            Pair(
                "\"Fokus adalah kekuatan super rahasia untuk mencapai kesuksesan.\"",
                "— Unknown"
            ),
            Pair(
                "\"Produktivitas bukan tentang waktu yang Anda habiskan, tetapi tentang perhatian yang Anda berikan.\"",
                "— Unknown"
            ),
            Pair(
                "\"Distraksi adalah musuh terbesar dari pencapaian.\"",
                "— Unknown"
            ),
            Pair(
                "\"Setiap detik yang Anda fokus adalah investasi untuk masa depan yang lebih baik.\"",
                "— Unknown"
            ),
        )
    }

    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var overlayView: View? = null

    @Volatile
    private var isShowing = false

    fun show(
        blockedPackage: String,
        taskTitle: String?,
        customQuote: String? = null,
        messageOverride: String? = null
    ) {
        if (isShowing) {
            Log.d(TAG, "Overlay already showing; skipping duplicate for package=$blockedPackage")
            return
        }

        mainHandler.post {
            showOnMainThread(
                blockedPackage = blockedPackage,
                taskTitle = taskTitle,
                customQuote = customQuote,
                messageOverride = messageOverride,
                warningOnly = false
            )
        }
    }

    fun showWarning(
        blockedPackage: String,
        taskTitle: String?,
        warningMessage: String,
        warningLevel: AdaptiveInterventionLevel = AdaptiveInterventionLevel.SOFT_WARNING
    ) {
        if (isShowing) {
            Log.d(TAG, "Overlay already showing; skipping warning for package=$blockedPackage")
            return
        }

        mainHandler.post {
            showOnMainThread(
                blockedPackage = blockedPackage,
                taskTitle = taskTitle,
                customQuote = null,
                messageOverride = warningMessage,
                warningOnly = true,
                warningLevel = warningLevel
            )
        }
    }

    private fun showOnMainThread(
        blockedPackage: String,
        taskTitle: String?,
        customQuote: String?,
        messageOverride: String?,
        warningOnly: Boolean,
        warningLevel: AdaptiveInterventionLevel? = null
    ) {
        if (isShowing) {
            return
        }

        try {
            val inflater = LayoutInflater.from(context)
            val view = inflater.inflate(R.layout.overlay_intervention, null)

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT
            )

            // Allow touch input on the overlay so the button works
            params.flags = params.flags and WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE.inv()
            params.flags = params.flags and WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE.inv()

            bindViews(
                view = view,
                blockedPackage = blockedPackage,
                taskTitle = taskTitle,
                customQuote = customQuote,
                messageOverride = messageOverride,
                warningOnly = warningOnly,
                warningLevel = warningLevel
            )

            windowManager.addView(view, params)
            overlayView = view
            isShowing = true

            Log.d(
                TAG,
                "Overlay shown: package=$blockedPackage task=$taskTitle warningOnly=$warningOnly"
            )
        } catch (error: Exception) {
            Log.e(TAG, "Failed to show overlay for package=$blockedPackage", error)
        }
    }

    private fun bindViews(
        view: View,
        blockedPackage: String,
        taskTitle: String?,
        customQuote: String?,
        messageOverride: String?,
        warningOnly: Boolean,
        warningLevel: AdaptiveInterventionLevel?
    ) {
        val overlayIcon = view.findViewById<ImageView>(R.id.overlayIcon)
        val statusTitleText = view.findViewById<TextView>(R.id.overlayStatusTitleText)
        val quoteText = view.findViewById<TextView>(R.id.overlayQuoteText)
        val quoteAuthor = view.findViewById<TextView>(R.id.overlayQuoteAuthor)
        val taskContainer = view.findViewById<LinearLayout>(R.id.overlayTaskContainer)
        val taskLabelText = view.findViewById<TextView>(R.id.overlayTaskLabelText)
        val taskTitleText = view.findViewById<TextView>(R.id.overlayTaskTitleText)
        val backToWorkButton = view.findViewById<TextView>(R.id.overlayBackToWorkButton)
        val continueButton = view.findViewById<TextView>(R.id.overlayContinueButton)
        val blockedAppText = view.findViewById<TextView>(R.id.overlayBlockedAppText)
        val appLabel = resolveAppLabel(blockedPackage)

        overlayIcon.setImageResource(
            if (warningOnly) android.R.drawable.ic_dialog_alert else android.R.drawable.ic_lock_lock
        )
        statusTitleText.text = buildStatusTitle(appLabel, warningOnly, warningLevel)

        if (!messageOverride.isNullOrBlank()) {
            Log.d(TAG, "Using overlay message override: $messageOverride")
            quoteText.text = messageOverride
            quoteAuthor.visibility = View.GONE
        } else if (!customQuote.isNullOrBlank()) {
            Log.d(TAG, "Using custom quote: $customQuote")
            quoteText.text = "\"$customQuote\""
            quoteAuthor.visibility = View.GONE
        } else {
            Log.d(TAG, "Using fallback random quote")
            val quote = QUOTES[(System.currentTimeMillis() % QUOTES.size).toInt()]
            quoteText.text = quote.first
            quoteAuthor.text = quote.second
            quoteAuthor.visibility = View.VISIBLE
        }

        if (!taskTitle.isNullOrBlank()) {
            taskContainer.visibility = View.VISIBLE
            taskLabelText.text = if (warningOnly) "Tugas sekarang:" else "Tugas mendesak saat ini:"
            taskTitleText.text = taskTitle
        } else {
            taskContainer.visibility = View.GONE
        }

        blockedAppText.text = buildFooterText(appLabel, warningOnly, warningLevel)
        backToWorkButton.text = if (warningOnly) "Kembali ke Tugas" else "Kembali Bekerja"
        continueButton.visibility = if (warningOnly) View.VISIBLE else View.GONE
        continueButton.text = buildContinueButtonText(warningLevel)

        backToWorkButton.setOnClickListener { btn ->
            btn.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
            if (warningOnly) {
                Log.d(TAG, "User chose to return from adaptive warning: package=$blockedPackage")
                onBackToWorkTapped(blockedPackage)
            } else {
                Log.d(TAG, "User tapped Kembali Bekerja: package=$blockedPackage")
                onBackToWorkTapped(blockedPackage)
            }
            dismiss()
        }

        continueButton.setOnClickListener { btn ->
            btn.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
            Log.d(
                TAG,
                "User continued after adaptive warning: package=$blockedPackage level=${warningLevel?.storageValue}"
            )
            dismiss()
        }

        Log.d(
            TAG,
            "Overlay views bound: package=$blockedPackage appLabel=$appLabel " +
                "task=$taskTitle customQuote=$customQuote warningOnly=$warningOnly " +
                "warningLevel=${warningLevel?.storageValue}"
        )
    }

    private fun buildStatusTitle(
        appLabel: String,
        warningOnly: Boolean,
        warningLevel: AdaptiveInterventionLevel?
    ): String {
        if (!warningOnly) {
            return "Akses $appLabel Ditahan"
        }

        return if (warningLevel == AdaptiveInterventionLevel.STRONG_WARNING) {
            "$appLabel Hampir Dibatasi"
        } else {
            "$appLabel Masuk Zona Distraksi"
        }
    }

    private fun buildFooterText(
        appLabel: String,
        warningOnly: Boolean,
        warningLevel: AdaptiveInterventionLevel?
    ): String {
        if (!warningOnly) {
            return "Akses ke $appLabel diblokir"
        }

        return if (warningLevel == AdaptiveInterventionLevel.STRONG_WARNING) {
            "Jika distraksi berlanjut, $appLabel bisa ditahan sementara."
        } else {
            "Akses ke $appLabel masih diizinkan, tapi sebaiknya dibatasi."
        }
    }

    private fun buildContinueButtonText(warningLevel: AdaptiveInterventionLevel?): String {
        return if (warningLevel == AdaptiveInterventionLevel.STRONG_WARNING) {
            "Lanjut maks. 5 menit"
        } else {
            "Lanjut 5 menit"
        }
    }

    fun dismiss() {
        mainHandler.post {
            dismissOnMainThread()
        }
    }

    private fun dismissOnMainThread() {
        val view = overlayView ?: return
        try {
            windowManager.removeView(view)
            Log.d(TAG, "Overlay dismissed")
        } catch (error: Exception) {
            Log.w(TAG, "Error while dismissing overlay", error)
        } finally {
            overlayView = null
            isShowing = false
        }
    }

    private fun resolveAppLabel(packageName: String): String {
        return try {
            val appInfo = context.packageManager.getApplicationInfo(packageName, 0)
            context.packageManager.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            packageName
        }
    }

    val isOverlayShowing: Boolean get() = isShowing
}
