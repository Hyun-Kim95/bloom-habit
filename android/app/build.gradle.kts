import java.nio.charset.StandardCharsets
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// local.properties is not merged into Gradle project properties — read keys explicitly.
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
fun localProp(name: String): String =
    localProperties.getProperty(name)?.trim().orEmpty()

// Play 스토어 업로드용 릴리즈 서명: android/key.properties + storeFile 경로
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.khyun.bloom_habit"
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
        applicationId = "com.khyun.bloom_habit"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        val kakaoNativeAppKey =
            localProp("KAKAO_NATIVE_APP_KEY").ifBlank {
                (project.findProperty("KAKAO_NATIVE_APP_KEY") as String?)?.trim().orEmpty()
            }
        val naverClientId =
            localProp("NAVER_CLIENT_ID").ifBlank {
                (project.findProperty("NAVER_CLIENT_ID") as String?)?.trim().orEmpty()
            }
        val naverClientSecret =
            localProp("NAVER_CLIENT_SECRET").ifBlank {
                (project.findProperty("NAVER_CLIENT_SECRET") as String?)?.trim().orEmpty()
            }
        val naverClientName =
            localProp("NAVER_CLIENT_NAME").ifBlank {
                (project.findProperty("NAVER_CLIENT_NAME") as String?)?.trim().orEmpty()
            }
        manifestPlaceholders["KAKAO_SCHEME"] = if (kakaoNativeAppKey.isNotBlank()) "kakao$kakaoNativeAppKey" else "kakao"
        manifestPlaceholders["NAVER_CLIENT_ID"] = naverClientId
        manifestPlaceholders["NAVER_CLIENT_SECRET"] = naverClientSecret
        manifestPlaceholders["NAVER_CLIENT_NAME"] = naverClientName
        // AdMob 앱 ID: local.properties 의 ADMOB_APP_ID 없으면 Google 공식 테스트 앱 ID (출시 전 본인 ID로 교체)
        val admobAppId =
            localProp("ADMOB_APP_ID").ifBlank {
                (project.findProperty("ADMOB_APP_ID") as String?)?.trim().orEmpty()
            }.ifBlank { "ca-app-pub-3940256099942544~3347511713" }
        manifestPlaceholders["ADMOB_APPLICATION_ID"] = admobAppId

        fun q(s: String): String =
            "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
        buildConfigField("String", "KAKAO_NATIVE_APP_KEY", q(kakaoNativeAppKey))
        buildConfigField("String", "NAVER_CLIENT_ID", q(naverClientId))
        buildConfigField("String", "NAVER_CLIENT_SECRET", q(naverClientSecret))
        buildConfigField("String", "NAVER_CLIENT_NAME", q(naverClientName))
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (hasReleaseKeystore) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
            // 네이버 SDK 등은 R8 제거 시 NidOAuthLogin 쪽 ClassCastException이 날 수 있음 → 규칙 적용을 위해 명시.
            isMinifyEnabled = true
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

// android/local.properties → Flutter --dart-define (Base64, comma-separated).
fun encodeDartDefine(key: String, value: String): String =
    Base64.getEncoder().encodeToString(
        "$key=$value".toByteArray(StandardCharsets.UTF_8),
    )

fun mergeDartDefine(existing: String, key: String, value: String): String {
    if (value.isBlank()) return existing
    val encoded = encodeDartDefine(key, value)
    return if (existing.isEmpty()) encoded else "$existing,$encoded"
}

var dartDefinesFromLocal = findProperty("dart-defines")?.toString()?.trim().orEmpty()

// 실기기 테스트: PC와 같은 Wi-Fi에서 `ipconfig`로 본 IPv4로 설정 (에뮬레이터는 비워도 됨).
// android/local.properties 예: API_BASE_URL=http://192.168.0.12:3000
dartDefinesFromLocal = mergeDartDefine(dartDefinesFromLocal, "API_BASE_URL", localProp("API_BASE_URL"))

// PostHog: ANALYTICS_ENABLED=true + POSTHOG_API_KEY in local.properties (gitignored).
// Omit or set ANALYTICS_ENABLED=false for Play AAB with analytics OFF.
if (localProp("ANALYTICS_ENABLED").equals("true", ignoreCase = true)) {
    dartDefinesFromLocal = mergeDartDefine(dartDefinesFromLocal, "ANALYTICS_ENABLED", "true")
    dartDefinesFromLocal = mergeDartDefine(dartDefinesFromLocal, "POSTHOG_API_KEY", localProp("POSTHOG_API_KEY"))
    val posthogHost =
        localProp("POSTHOG_HOST").ifBlank { "https://us.i.posthog.com" }
    dartDefinesFromLocal = mergeDartDefine(dartDefinesFromLocal, "POSTHOG_HOST", posthogHost)
    val analyticsEnv =
        localProp("ANALYTICS_ENVIRONMENT").ifBlank { "prelaunch" }
    dartDefinesFromLocal = mergeDartDefine(dartDefinesFromLocal, "ANALYTICS_ENVIRONMENT", analyticsEnv)
}

if (dartDefinesFromLocal.isNotBlank()) {
    extra["dart-defines"] = dartDefinesFromLocal
}

// home_widget uses glance-appwidget:1.+ which resolves to 1.3.0-alpha01 (needs AGP 9.1 / compileSdk 37).
configurations.configureEach {
    resolutionStrategy {
        force("androidx.glance:glance:1.0.0")
        force("androidx.glance:glance-appwidget:1.0.0")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.glance:glance:1.0.0")
    implementation("androidx.glance:glance-appwidget:1.0.0")
}
