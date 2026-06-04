package com.example.flutter_quran_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AdhanRescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AdhanAlarmScheduler.rescheduleAll(context)
    }
}
