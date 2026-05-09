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

# Gson (used by several OAuth stacks; helps ParameterizedType / TypeToken paths)
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
