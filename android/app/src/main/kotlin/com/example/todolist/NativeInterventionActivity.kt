package com.example.todolist

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.HapticFeedbackConstants
import android.view.View
import android.widget.Button
import android.widget.TextView

class NativeInterventionActivity : Activity() {

    companion object {
        private const val TAG = "NativeIntervention"

        const val EXTRA_BLOCKED_PACKAGE = "blocked_package"
        const val EXTRA_BLOCKING_TASK_TITLE = "blocking_task_title"
        const val EXTRA_BLOCKING_PRIORITY = "blocking_priority"
        const val EXTRA_BLOCKING_REMAINING_MINUTES = "blocking_remaining_minutes"
        const val EXTRA_BLOCKING_WINDOW_HOURS = "blocking_window_hours"
    }

    private lateinit var taskContainer: View
    private lateinit var taskTitleText: TextView
    private lateinit var blockedAppText: TextView
    private lateinit var backToWorkButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_intervention)

        taskContainer = findViewById(R.id.taskContainer)
        taskTitleText = findViewById(R.id.taskTitleText)
        blockedAppText = findViewById(R.id.blockedAppText)
        backToWorkButton = findViewById(R.id.backToWorkButton)

        renderFromIntent(intent, source = "onCreate")

        backToWorkButton.setOnClickListener { view ->
            view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
            openMainApp("cta_back_to_work")
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        renderFromIntent(intent, source = "onNewIntent")
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "Native intervention resumed")
    }

    override fun onPause() {
        super.onPause()
        Log.d(TAG, "Native intervention paused")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Native intervention destroyed")
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        openMainApp("system_back")
    }

    private fun renderFromIntent(intent: Intent, source: String) {
        val blockedPackage = intent.getStringExtra(EXTRA_BLOCKED_PACKAGE)
        val taskTitle = intent.getStringExtra(EXTRA_BLOCKING_TASK_TITLE)
        val priority = intent.getStringExtra(EXTRA_BLOCKING_PRIORITY)
        val remainingMinutes = intent.getIntExtra(EXTRA_BLOCKING_REMAINING_MINUTES, Int.MIN_VALUE)
        val windowHours = intent.getIntExtra(EXTRA_BLOCKING_WINDOW_HOURS, Int.MIN_VALUE)

        val blockedAppName = resolveAppLabel(blockedPackage)

        if (taskTitle.isNullOrBlank()) {
            taskContainer.visibility = View.GONE
        } else {
            taskContainer.visibility = View.VISIBLE
            taskTitleText.text = taskTitle
        }

        blockedAppText.text = "Akses ke $blockedAppName diblokir"

        val acknowledged = MainActivity.acknowledgeQueuedBlockedPackage(blockedPackage)
        val remainingLog = if (remainingMinutes == Int.MIN_VALUE) "null" else remainingMinutes.toString()
        val windowLog = if (windowHours == Int.MIN_VALUE) "null" else windowHours.toString()

        Log.d(
            TAG,
            "Rendered native intervention source=$source package=$blockedPackage app=$blockedAppName " +
                "task=$taskTitle priority=$priority remainingMinutes=$remainingLog windowHours=$windowLog " +
                "queueAcknowledged=$acknowledged"
        )
    }

    private fun resolveAppLabel(blockedPackage: String?): String {
        if (blockedPackage.isNullOrBlank()) {
            return "Aplikasi"
        }

        return try {
            val appInfo = packageManager.getApplicationInfo(blockedPackage, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            blockedPackage
        }
    }

    private fun openMainApp(source: String) {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val mainIntent = launchIntent ?: Intent(this, MainActivity::class.java)

        mainIntent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        )

        Log.d(TAG, "Opening main app from native intervention: source=$source")
        startActivity(mainIntent)
        finish()
    }
}
