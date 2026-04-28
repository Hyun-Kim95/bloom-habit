package com.khyun.bloom_habit

import android.content.Intent
import android.content.SharedPreferences
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import androidx.core.content.ContextCompat
import com.khyun.bloom_habit.BuildConfig
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// OAuth / embedded browsers need [FlutterFragmentActivity] (e.g. Naver Login SDK).
class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val TIMER_PREFS = "duration_timer_state"
        private const val KEY_RUNNING = "running"
        private const val KEY_START_MS = "start_ms"
        private const val KEY_HABIT_ID = "habit_id"
        private const val KEY_HABIT_NAME = "habit_name"
    }

    private var timerStartMs: Long? = null
    private val timerPrefs: SharedPreferences by lazy {
        getSharedPreferences(TIMER_PREFS, MODE_PRIVATE)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        volumeControlStream = AudioManager.STREAM_MUSIC
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "bloom_habit/native_config",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSocialKeys" -> {
                    result.success(
                        mapOf(
                            "kakaoNativeAppKey" to BuildConfig.KAKAO_NATIVE_APP_KEY,
                            "naverClientId" to BuildConfig.NAVER_CLIENT_ID,
                            "naverClientSecret" to BuildConfig.NAVER_CLIENT_SECRET,
                            "naverClientName" to BuildConfig.NAVER_CLIENT_NAME,
                        ),
                    )
                }
                "startDurationTimer" -> {
                    val habitName = call.argument<String>("habitName") ?: "Habit"
                    val habitId = call.argument<String>("habitId")
                    val now = System.currentTimeMillis()
                    timerStartMs = now
                    timerPrefs.edit()
                        .putBoolean(KEY_RUNNING, true)
                        .putLong(KEY_START_MS, now)
                        .putString(KEY_HABIT_ID, habitId)
                        .putString(KEY_HABIT_NAME, habitName)
                        .apply()
                    val intent = Intent(this, DurationTimerService::class.java).apply {
                        action = DurationTimerService.ACTION_START
                        putExtra(DurationTimerService.EXTRA_HABIT_NAME, habitName)
                        putExtra(DurationTimerService.EXTRA_START_MS, now)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        ContextCompat.startForegroundService(this, intent)
                    } else {
                        startService(intent)
                    }
                    result.success(now)
                }
                "stopDurationTimer" -> {
                    val startedAt = timerStartMs ?: timerPrefs.getLong(KEY_START_MS, System.currentTimeMillis())
                    val elapsedMs = (System.currentTimeMillis() - startedAt).coerceAtLeast(0L)
                    val intent = Intent(this, DurationTimerService::class.java).apply {
                        action = DurationTimerService.ACTION_STOP
                    }
                    startService(intent)
                    timerStartMs = null
                    timerPrefs.edit()
                        .putBoolean(KEY_RUNNING, false)
                        .remove(KEY_START_MS)
                        .remove(KEY_HABIT_ID)
                        .remove(KEY_HABIT_NAME)
                        .apply()
                    result.success(elapsedMs)
                }
                "getDurationTimerState" -> {
                    val running = timerPrefs.getBoolean(KEY_RUNNING, false)
                    val startedAt = timerPrefs.getLong(KEY_START_MS, 0L)
                    val elapsedMs =
                        if (running && startedAt > 0L) {
                            (System.currentTimeMillis() - startedAt).coerceAtLeast(0L)
                        } else {
                            0L
                        }
                    result.success(
                        mapOf(
                            "running" to running,
                            "habitId" to timerPrefs.getString(KEY_HABIT_ID, null),
                            "habitName" to timerPrefs.getString(KEY_HABIT_NAME, null),
                            "startedAtMs" to if (startedAt > 0L) startedAt else null,
                            "elapsedMs" to elapsedMs,
                        ),
                    )
                }
                else -> result.notImplemented()
            }
        }
    }
}
