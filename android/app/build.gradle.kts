plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.bloom_habit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.bloom_habit"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        val kakaoNativeAppKey = (project.findProperty("KAKAO_NATIVE_APP_KEY") as String?) ?: ""
        val naverClientId = (project.findProperty("NAVER_CLIENT_ID") as String?) ?: ""
        val naverClientSecret = (project.findProperty("NAVER_CLIENT_SECRET") as String?) ?: ""
        val naverClientName = (project.findProperty("NAVER_CLIENT_NAME") as String?) ?: ""
        manifestPlaceholders["KAKAO_SCHEME"] = if (kakaoNativeAppKey.isNotBlank()) "kakao$kakaoNativeAppKey" else "kakao"
        manifestPlaceholders["NAVER_CLIENT_ID"] = naverClientId
        manifestPlaceholders["NAVER_CLIENT_SECRET"] = naverClientSecret
        manifestPlaceholders["NAVER_CLIENT_NAME"] = naverClientName

        fun q(s: String): String =
            "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
        buildConfigField("String", "KAKAO_NATIVE_APP_KEY", q(kakaoNativeAppKey))
        buildConfigField("String", "NAVER_CLIENT_ID", q(naverClientId))
        buildConfigField("String", "NAVER_CLIENT_SECRET", q(naverClientSecret))
        buildConfigField("String", "NAVER_CLIENT_NAME", q(naverClientName))
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.glance:glance:1.0.0")
    implementation("androidx.glance:glance-appwidget:1.0.0")
}
