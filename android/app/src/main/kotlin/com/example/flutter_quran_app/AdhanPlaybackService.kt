package com.example.flutter_quran_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AdhanPlaybackService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var notificationId: Int = DEFAULT_NOTIFICATION_ID

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopAdhan()
                return START_NOT_STICKY
            }

            ACTION_PLAY -> {
                val incomingNotificationId = intent.getIntExtra(
                    EXTRA_NOTIFICATION_ID,
                    DEFAULT_NOTIFICATION_ID
                )
                if (isActiveOrRecentlyCompleted(this, incomingNotificationId)) {
                    Log.d(TAG, "Ignoring duplicate adhan playback id=$incomingNotificationId")
                    return START_NOT_STICKY
                }

                notificationId = incomingNotificationId
                val title = intent.getStringExtra(EXTRA_TITLE) ?: "Waktu Sholat"
                val body = intent.getStringExtra(EXTRA_BODY) ?: "Telah masuk waktu sholat."
                startForeground(notificationId, buildNotification(title, body))
                playAdhan()
            }
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        releasePlayer()
        super.onDestroy()
    }

    private fun playAdhan() {
        releasePlayer()
        acquireWakeLock()

        val adhanFile = resources.openRawResourceFd(R.raw.adhan)
        mediaPlayer = MediaPlayer().apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
            }
            setDataSource(
                adhanFile.fileDescriptor,
                adhanFile.startOffset,
                adhanFile.length
            )
            adhanFile.close()
            setOnCompletionListener { stopAdhan() }
            setOnErrorListener { _, _, _ ->
                stopAdhan()
                true
            }
            prepare()
            start()
            markPlaying(this@AdhanPlaybackService, notificationId)
            Log.d(TAG, "Adhan playback started id=$notificationId")
        }
    }

    private fun stopAdhan() {
        val stoppedNotificationId = notificationId
        releasePlayer()
        markStopped(this, stoppedNotificationId)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun releasePlayer() {
        mediaPlayer?.run {
            if (isPlaying) stop()
            release()
        }
        mediaPlayer = null
        releaseWakeLock()
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return

        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "$packageName:AdhanPlayback"
        ).apply {
            setReferenceCounted(false)
            acquire(10 * 60 * 1000L)
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
    }

    private fun buildNotification(title: String, body: String) =
        NotificationCompat.Builder(this, PLAYBACK_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .addAction(0, "Stop Adzan", stopPendingIntent())
            .also { ensureChannel() }
            .build()

    private fun stopPendingIntent(): PendingIntent {
        val intent = Intent(this, AdhanPlaybackService::class.java).apply {
            action = ACTION_STOP
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        }
        return PendingIntent.getService(
            this,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            PLAYBACK_CHANNEL_ID,
            "Adzan Sholat Berjalan",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Kontrol pemutaran adzan"
            setSound(null, null)
            enableVibration(false)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val ACTION_PLAY = "com.example.flutter_quran_app.action.PLAY_ADHAN"
        const val ACTION_STOP = "com.example.flutter_quran_app.action.STOP_ADHAN"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"

        private const val TAG = "AdhanPlaybackService"
        private const val STATE_PREFS_NAME = "adhan_playback_state"
        private const val KEY_ACTIVE_ID = "active_id"
        private const val KEY_ACTIVE_SINCE = "active_since"
        private const val KEY_COMPLETED_ID = "completed_id"
        private const val KEY_COMPLETED_AT = "completed_at"
        private const val MAX_ACTIVE_MS = 10 * 60 * 1000L
        private const val COMPLETED_COOLDOWN_MS = 10 * 60 * 1000L

        const val DEFAULT_NOTIFICATION_ID = 7499
        private const val PLAYBACK_CHANNEL_ID = "adhan_playback_channel_v1"

        fun isActiveOrRecentlyCompleted(context: Context, id: Int): Boolean {
            val prefs = context.getSharedPreferences(STATE_PREFS_NAME, Context.MODE_PRIVATE)
            val now = System.currentTimeMillis()
            val activeId = prefs.getInt(KEY_ACTIVE_ID, -1)
            val activeSince = prefs.getLong(KEY_ACTIVE_SINCE, 0L)
            if (activeId == id && now - activeSince <= MAX_ACTIVE_MS) {
                return true
            }

            val completedId = prefs.getInt(KEY_COMPLETED_ID, -1)
            val completedAt = prefs.getLong(KEY_COMPLETED_AT, 0L)
            return completedId == id && now - completedAt <= COMPLETED_COOLDOWN_MS
        }

        private fun markPlaying(context: Context, id: Int) {
            context.getSharedPreferences(STATE_PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putInt(KEY_ACTIVE_ID, id)
                .putLong(KEY_ACTIVE_SINCE, System.currentTimeMillis())
                .remove(KEY_COMPLETED_ID)
                .remove(KEY_COMPLETED_AT)
                .apply()
        }

        private fun markStopped(context: Context, id: Int) {
            context.getSharedPreferences(STATE_PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .remove(KEY_ACTIVE_ID)
                .remove(KEY_ACTIVE_SINCE)
                .putInt(KEY_COMPLETED_ID, id)
                .putLong(KEY_COMPLETED_AT, System.currentTimeMillis())
                .apply()
        }
    }
}
