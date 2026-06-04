package com.example.flutter_quran_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject

object AdhanAlarmScheduler {
    const val CHANNEL_NAME = "com.example.flutter_quran_app/adhan_alarm"

    private const val PREFS_NAME = "adhan_alarm_schedule"
    private const val KEY_PREFIX = "alarm_"
    private const val JSON_ID = "id"
    private const val JSON_TITLE = "title"
    private const val JSON_BODY = "body"
    private const val JSON_TRIGGER_AT = "triggerAtMillis"

    fun schedule(
        context: Context,
        id: Int,
        title: String,
        body: String,
        triggerAtMillis: Long
    ) {
        save(context, id, title, body, triggerAtMillis)
        scheduleAlarm(context, id, title, body, triggerAtMillis)
    }

    fun cancel(context: Context, id: Int) {
        remove(context, id)
        cancelAlarm(context, id)
    }

    fun rescheduleAll(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        prefs.all.forEach { (key, value) ->
            if (!key.startsWith(KEY_PREFIX) || value !is String) return@forEach

            runCatching {
                val json = JSONObject(value)
                val id = json.getInt(JSON_ID)
                val title = json.getString(JSON_TITLE)
                val body = json.getString(JSON_BODY)
                val triggerAtMillis = json.getLong(JSON_TRIGGER_AT)
                if (triggerAtMillis > now) {
                    scheduleAlarm(context, id, title, body, triggerAtMillis)
                } else {
                    remove(context, id)
                }
            }
        }
    }

    private fun scheduleAlarm(
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

    private fun cancelAlarm(context: Context, id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = pendingIntent(context, id, null, null)
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    private fun save(
        context: Context,
        id: Int,
        title: String,
        body: String,
        triggerAtMillis: Long
    ) {
        val json = JSONObject()
            .put(JSON_ID, id)
            .put(JSON_TITLE, title)
            .put(JSON_BODY, body)
            .put(JSON_TRIGGER_AT, triggerAtMillis)
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString("$KEY_PREFIX$id", json.toString())
            .apply()
    }

    private fun remove(context: Context, id: Int) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove("$KEY_PREFIX$id")
            .apply()
    }

    fun complete(context: Context, id: Int) {
        remove(context, id)
    }

    fun stopPlayback(context: Context, id: Int) {
        val intent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_STOP
            putExtra(AdhanPlaybackService.EXTRA_NOTIFICATION_ID, id)
        }
        context.startService(intent)
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
