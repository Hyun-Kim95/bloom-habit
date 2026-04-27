package com.example.bloom_habit

import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import androidx.core.content.ContextCompat
import com.example.bloom_habit.BuildConfig
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// OAuth / embedded browsers need [FlutterFragmentActivity] (e.g. Naver Login SDK).
class MainActivity : FlutterFragmentActivity() {
    private var timerStartMs: Long? = null

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
                    val now = System.currentTimeMillis()
                    timerStartMs = now
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
                    val startedAt = timerStartMs ?: System.currentTimeMillis()
                    val elapsedMs = (System.currentTimeMillis() - startedAt).coerceAtLeast(0L)
                    val intent = Intent(this, DurationTimerService::class.java).apply {
                        action = DurationTimerService.ACTION_STOP
                    }
                    startService(intent)
                    timerStartMs = null
                    result.success(elapsedMs)
                }
                else -> result.notImplemented()
            }
        }
    }
}
