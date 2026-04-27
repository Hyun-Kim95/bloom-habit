package com.example.bloom_habit

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.util.Locale
import java.util.Timer
import java.util.TimerTask

class DurationTimerService : Service() {
    companion object {
        const val CHANNEL_ID = "duration_timer_channel"
        const val NOTIFICATION_ID = 19021
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        const val EXTRA_HABIT_NAME = "EXTRA_HABIT_NAME"
        const val EXTRA_START_MS = "EXTRA_START_MS"
    }

    private var timer: Timer? = null
    private var habitName: String = "Habit"
    private var startMs: Long = 0L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                habitName = intent.getStringExtra(EXTRA_HABIT_NAME) ?: "Habit"
                startMs = intent.getLongExtra(EXTRA_START_MS, System.currentTimeMillis())
                createNotificationChannel()
                startForeground(NOTIFICATION_ID, buildNotification())
                startTicker()
            }
            ACTION_STOP -> {
                stopTicker()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopTicker()
        super.onDestroy()
    }

    private fun startTicker() {
        stopTicker()
        timer = Timer().apply {
            scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    manager.notify(NOTIFICATION_ID, buildNotification())
                }
            }, 1000L, 1000L)
        }
    }

    private fun stopTicker() {
        timer?.cancel()
        timer = null
    }

    private fun buildNotification(): Notification {
        val elapsed = (System.currentTimeMillis() - startMs).coerceAtLeast(0L)
        val sec = elapsed / 1000L
        val h = sec / 3600L
        val m = (sec % 3600L) / 60L
        val s = sec % 60L
        val elapsedText =
            if (h > 0) String.format(Locale.getDefault(), "%02d:%02d:%02d", h, m, s)
            else String.format(Locale.getDefault(), "%02d:%02d", m, s)
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingFlags =
            PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        val openAppPendingIntent = PendingIntent.getActivity(this, 0, openAppIntent, pendingFlags)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("$habitName 타이머 진행 중")
            .setContentText("경과 시간 $elapsedText")
            .setContentIntent(openAppPendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Habit Duration Timer",
            NotificationManager.IMPORTANCE_LOW,
        )
        manager.createNotificationChannel(channel)
    }
}

