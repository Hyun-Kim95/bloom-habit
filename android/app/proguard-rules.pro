# OkHttp optional TLS stacks (reflection); not on classpath in release.
-dontwarn org.conscrypt.Conscrypt$Version
-dontwarn org.conscrypt.Conscrypt
-dontwarn org.conscrypt.ConscryptHostnameVerifier
-dontwarn org.openjsse.javax.net.ssl.SSLParameters
-dontwarn org.openjsse.javax.net.ssl.SSLSocket
-dontwarn org.openjsse.net.ssl.OpenJSSE

# --- Naver Login SDK (R8 / release) ---
# Log: ClassCastException: java.lang.Class cannot be cast to java.lang.reflect.ParameterizedType
# in NaverIdLogin / NidOAuthLogin — keep generics + SDK entrypoints for Gson/reflection.
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations

-keep class com.navercorp.nid.** { *; }
-keep class com.navercorp.** { *; }
-dontwarn com.navercorp.**

# Gson (Naver OAuth, flutter_local_notifications scheduled storage, etc.)
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
# R8 3+ / AGP 8 full mode: anonymous TypeToken subclasses need generic signatures
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# --- PostHog Flutter SDK (release / R8) ---
-keep class com.posthog.** { *; }
-dontwarn com.posthog.**

# --- flutter_local_notifications (release: loadScheduledNotifications / cancelAll) ---
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class org.xmlpull.** { *; }
