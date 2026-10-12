package com.khushiidua.app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val COMPASS_CHANNEL = "com.khushiidua.app/compass"
        const val ALERT_PREVIEW_CHANNEL = "com.khushiidua.app/alertPreview"
        const val HEADING_CHANNEL = "com.khushiidua.app/heading"
    }

    /// Streams the heading while the Qibla screen is open.
    private var headingStream: HeadingStreamHandler? = null

    /// The sound currently previewing, so a new choice or leaving the screen
    /// can stop it.
    private var previewRingtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Which sensors this device physically has, which decides how good the
        // heading can possibly be. Dart cannot find that out by itself.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            COMPASS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCompassCapabilities" -> result.success(compassCapabilities())
                "haptic" -> result.success(compassHaptic(call.arguments as? String))
                else -> result.notImplemented()
            }
        }

        // The heading for the Qibla screen. See HeadingStreamHandler for why it
        // does not come from flutter_compass on Android.
        headingStream = HeadingStreamHandler(this).also {
            EventChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                HEADING_CHANNEL,
            ).setStreamHandler(it)
        }

        // Lets the Salah settings play an alert the moment it is chosen. A
        // preview posted as a notification was unreliable: Android's
        // notification cooldown mutes an app's alerts that arrive in quick
        // succession, which is exactly what trying several options does.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ALERT_PREVIEW_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "playSound" -> result.success(playSound(call.argument<String>("raw")))
                "vibrate" -> {
                    val pattern = call.argument<List<Number>>("pattern").orEmpty()
                    result.success(vibrate(LongArray(pattern.size) { pattern[it].toLong() }))
                }
                "stop" -> {
                    stopPreview()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        headingStream?.stop()
        stopPreview()
        super.onDestroy()
    }

    /// Plays the bundled raw sound named [raw], or the device's notification
    /// sound when it is null, on the notification stream a reminder uses.
    private fun playSound(raw: String?): Boolean {
        stopPreview()
        val uri = if (raw == null) {
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        } else {
            val id = resources.getIdentifier(raw, "raw", packageName)
            if (id == 0) return false
            Uri.parse("android.resource://$packageName/$id")
        } ?: return false

        val ringtone = RingtoneManager.getRingtone(this, uri) ?: return false
        ringtone.audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        ringtone.play()
        previewRingtone = ringtone
        return true
    }

    private fun vibrator(): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)
                ?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

    /// The Qibla compass's one cue, felt without watching the screen: a tap
    /// on reaching the Qibla.
    ///
    /// Played as a notification-type vibration. Flutter's HapticFeedback
    /// goes through touch feedback, which many people turn off, and Android
    /// treats any short vibration without a stated purpose as touch feedback
    /// too, so these cues were never felt.
    private fun compassHaptic(name: String?): Boolean {
        val vibrator = vibrator()?.takeIf { it.hasVibrator() } ?: return false
        if (name != "aligned") return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            vibrator.vibrate(60L)
            return true
        }
        val effect = VibrationEffect.createOneShot(60, VibrationEffect.DEFAULT_AMPLITUDE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            vibrator.vibrate(
                effect,
                VibrationAttributes.createForUsage(VibrationAttributes.USAGE_NOTIFICATION),
            )
        } else {
            vibrator.vibrate(
                effect,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build(),
            )
        }
        return true
    }

    private fun vibrate(pattern: LongArray): Boolean {
        stopPreview()
        val vibrator = vibrator()
        if (vibrator == null || !vibrator.hasVibrator() || pattern.isEmpty()) {
            return false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1)
        }
        return true
    }

    private fun stopPreview() {
        previewRingtone?.stop()
        previewRingtone = null
    }

    private fun compassCapabilities(): Map<String, Any?> {
        val sensorManager =
            getSystemService(Context.SENSOR_SERVICE) as? SensorManager

        fun sensor(type: Int): Sensor? = sensorManager?.getDefaultSensor(type)

        val rotationVector = sensor(Sensor.TYPE_ROTATION_VECTOR)

        return mapOf(
            "hasMagnetometer" to (sensor(Sensor.TYPE_MAGNETIC_FIELD) != null),
            "hasAccelerometer" to (sensor(Sensor.TYPE_ACCELEROMETER) != null),
            "hasRotationVector" to (rotationVector != null),
            "hasGeomagneticRotationVector" to
                (sensor(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR) != null),
            "hasGyroscope" to (sensor(Sensor.TYPE_GYROSCOPE) != null),
            "rotationVectorName" to rotationVector?.name,
        )
    }
}
