package com.example.flutter_quran_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object AdhanAlarmScheduler {
    const val CHANNEL_NAME = "com.example.flutter_quran_app/adhan_alarm"

    fun schedule(
        context: Context,
        id: Int,
        title: String,
        body: String,
        triggerAtMillis: Long
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = pendingIntent(context, id, title, body)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            !alarmManager.canScheduleExactAlarms()
        ) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent
            )
            return
        }

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerAtMillis,
            pendingIntent
        )
    }

    fun cancel(context: Context, id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = pendingIntent(context, id, null, null)
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()

        val stopIntent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_STOP
            putExtra(AdhanPlaybackService.EXTRA_NOTIFICATION_ID, id)
        }
        context.startService(stopIntent)
    }

    private fun pendingIntent(
        context: Context,
        id: Int,
        title: String?,
        body: String?
    ): PendingIntent {
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            putExtra(AdhanPlaybackService.EXTRA_NOTIFICATION_ID, id)
            putExtra(AdhanPlaybackService.EXTRA_TITLE, title)
            putExtra(AdhanPlaybackService.EXTRA_BODY, body)
        }
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
