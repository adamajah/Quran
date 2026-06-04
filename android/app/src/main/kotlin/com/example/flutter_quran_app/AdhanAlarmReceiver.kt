package com.example.flutter_quran_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(
            AdhanPlaybackService.EXTRA_NOTIFICATION_ID,
            AdhanPlaybackService.DEFAULT_NOTIFICATION_ID
        )
        Log.d(TAG, "Adhan alarm received id=$id")
        AdhanAlarmScheduler.complete(context, id)

        val serviceIntent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtras(intent)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

    companion object {
        private const val TAG = "AdhanAlarmReceiver"
    }
}
