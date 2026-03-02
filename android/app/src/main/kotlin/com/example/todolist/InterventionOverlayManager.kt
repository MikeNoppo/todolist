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
import android.widget.LinearLayout
import android.widget.TextView

class InterventionOverlayManager(private val context: Context) {

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

    fun show(blockedPackage: String, taskTitle: String?) {
        if (isShowing) {
            Log.d(TAG, "Overlay already showing; skipping duplicate for package=$blockedPackage")
            return
        }

        mainHandler.post {
            showOnMainThread(blockedPackage, taskTitle)
        }
    }

    private fun showOnMainThread(blockedPackage: String, taskTitle: String?) {
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

            bindViews(view, blockedPackage, taskTitle)

            windowManager.addView(view, params)
            overlayView = view
            isShowing = true

            Log.d(
                TAG,
                "Overlay shown: package=$blockedPackage task=$taskTitle"
            )
        } catch (error: Exception) {
            Log.e(TAG, "Failed to show overlay for package=$blockedPackage", error)
        }
    }

    private fun bindViews(view: View, blockedPackage: String, taskTitle: String?) {
        val quoteText = view.findViewById<TextView>(R.id.overlayQuoteText)
        val quoteAuthor = view.findViewById<TextView>(R.id.overlayQuoteAuthor)
        val taskContainer = view.findViewById<LinearLayout>(R.id.overlayTaskContainer)
        val taskTitleText = view.findViewById<TextView>(R.id.overlayTaskTitleText)
        val backToWorkButton = view.findViewById<TextView>(R.id.overlayBackToWorkButton)
        val blockedAppText = view.findViewById<TextView>(R.id.overlayBlockedAppText)

        val quote = QUOTES[(System.currentTimeMillis() % QUOTES.size).toInt()]
        quoteText.text = quote.first
        quoteAuthor.text = quote.second

        if (!taskTitle.isNullOrBlank()) {
            taskContainer.visibility = View.VISIBLE
            taskTitleText.text = taskTitle
        } else {
            taskContainer.visibility = View.GONE
        }

        val appLabel = resolveAppLabel(blockedPackage)
        blockedAppText.text = "Akses ke $appLabel diblokir"

        backToWorkButton.setOnClickListener { btn ->
            btn.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
            Log.d(TAG, "User tapped Kembali Bekerja: package=$blockedPackage")
            dismiss()
        }

        Log.d(TAG, "Overlay views bound: package=$blockedPackage appLabel=$appLabel task=$taskTitle")
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
