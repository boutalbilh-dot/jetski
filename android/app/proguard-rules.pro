# Keep Flutter framework classes (engine relies on reflection).
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# sqflite — uses reflection for transactions.
-keep class com.tekartik.sqflite.** { *; }

# geolocator — Android location services + permission handling.
-keep class com.baseflow.geolocator.** { *; }

# audioplayers — native MediaPlayer / ExoPlayer bridges.
-keep class xyz.luan.audioplayers.** { *; }
-keep class androidx.media3.** { *; }

# vibration — platform channel registration.
-keep class com.benjaminabel.vibration.** { *; }

# flutter_bluetooth_serial — uses reflection for connection state.
-keep class io.github.edufolly.flutterbluetoothserial.** { *; }

# flutter_blue_plus — BLE platform channels.
-keep class com.lib.flutter_blue_plus.** { *; }

# Annotations + generic signatures used by reflection.
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Suppress R8 noise on unused Play Core (not bundled).
-dontwarn com.google.android.play.core.**
