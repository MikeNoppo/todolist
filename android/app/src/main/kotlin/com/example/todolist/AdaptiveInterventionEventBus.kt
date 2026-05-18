package com.example.todolist

import android.os.Handler
import android.os.Looper
import java.util.concurrent.CopyOnWriteArrayList

object AdaptiveInterventionEventBus {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val listeners = CopyOnWriteArrayList<(Map<String, Any>) -> Unit>()

    @Volatile
    private var latestEvent: Map<String, Any>? = null

    fun publish(event: Map<String, Any>) {
        latestEvent = event
        mainHandler.post {
            listeners.forEach { listener -> listener(event) }
        }
    }

    fun addListener(listener: (Map<String, Any>) -> Unit): Map<String, Any>? {
        listeners.add(listener)
        return latestEvent
    }

    fun removeListener(listener: (Map<String, Any>) -> Unit) {
        listeners.remove(listener)
    }
}
