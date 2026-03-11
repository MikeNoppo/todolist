package com.example.todolist

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class InterventionRecoveryReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "InterventionRecovery"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action.orEmpty()
        Log.d(TAG, "Recovery receiver invoked: action=$action")
        InterventionPersistenceService.start(
            context,
            if (action.isBlank()) "broadcast_unknown" else "broadcast_$action"
        )
    }
}
