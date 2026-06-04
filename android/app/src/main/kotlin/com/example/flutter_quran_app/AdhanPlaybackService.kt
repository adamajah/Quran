package com.example.flutter_quran_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class AdhanPlaybackService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var notificationId: Int = DEFAULT_NOTIFICATION_ID

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopAdhan()
                return START_NOT_STICKY
            }

            ACTION_PLAY -> {
                notificationId = intent.getIntExtra(
                    EXTRA_NOTIFICATION_ID,
                    DEFAULT_NOTIFICATION_ID
                )
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
        }
    }

    private fun stopAdhan() {
        releasePlayer()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun releasePlayer() {
        mediaPlayer?.run {
            if (isPlaying) stop()
            release()
        }
        mediaPlayer = null
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

        const val DEFAULT_NOTIFICATION_ID = 7499
        private const val PLAYBACK_CHANNEL_ID = "adhan_playback_channel_v1"
    }
}
