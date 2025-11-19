# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Flutter engine classes
-keep class io.flutter.embedding.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep audio player classes
-keep class xyz.luan.audioplayers.** { *; }

# Keep geolocator classes
-keep class com.baseflow.geolocator.** { *; }

# Keep shared preferences
-keep class androidx.preference.** { *; }

# Keep prayers_times
-keep class com.prayers_times.** { *; }

# Keep hijri calendar
-keep class com.hijri.** { *; }

# Keep flutter_sound_record
-keep class com.josephcrowell.flutter_sound_record.** { *; }

# Keep Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Keep GetX
-keep class com.get.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom application class
-keep class com.khushidua.app.khushidua.** { *; }
