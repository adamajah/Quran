package com.example.flutter_quran_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AdhanRescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Rescheduling native adhan alarms after ${intent.action}")
        AdhanAlarmScheduler.rescheduleAll(context)
    }

    companion object {
        private const val TAG = "AdhanRescheduleReceiver"
    }
}
