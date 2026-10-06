# R8 shrinks and obfuscates the release build. Flutter's Gradle plugin adds
# the engine's own rules, and Firebase, Play services, AndroidX and Kotlin
# ship theirs inside their libraries, so this file only covers what those do
# not: code reached by reflection, or data stored under class or field names.
#
# Keep rules here sparingly: every package kept whole stays unobfuscated,
# which is what Play's "DEX code optimization" check measures.

# flutter_local_notifications saves scheduled notifications as Gson JSON and
# reads them back after a reboot or an app update. Renamed fields would
# break reading the ones saved by an earlier version.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# background_downloader persists queued tasks and hands them to WorkManager;
# downloads queued by one version must still run after an update.
-keep class com.bbflight.background_downloader.** { *; }

# Flutter's engine refers to Play Core for deferred components, which this
# app does not use.
-dontwarn com.google.android.play.core.**
