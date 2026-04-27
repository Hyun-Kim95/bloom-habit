package com.example.bloom_habit

import android.content.Intent
import android.media.AudioManager
import android.os.Bundle
import com.example.bloom_habit.BuildConfig
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// OAuth / embedded browsers need [FlutterFragmentActivity] (e.g. Naver Login SDK).
class MainActivity : FlutterFragmentActivity() {
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
                else -> result.notImplemented()
            }
        }
    }
}
