package com.khushiidua.app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
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
        const val COMPASS_ACCURACY_CHANNEL = "com.khushiidua.app/compassAccuracy"
    }

    /// Listens to the magnetometer only for its calibration status while the
    /// Qibla screen is open.
    private var accuracyListener: SensorEventListener? = null

    /// The sound currently previewing, so a new choice or leaving the screen
    /// can stop it.
    private var previewRingtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // The Qibla screen applies the World Magnetic Model itself, so it does not
        // need anything from the platform to correct magnetic north to true north.
        // What it cannot determine from Dart is which sensors this device
        // physically has, which decides how good the heading can possibly be.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            COMPASS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCompassCapabilities" -> result.success(compassCapabilities())
                else -> result.notImplemented()
            }
        }

        // The magnetometer's calibration status (SensorManager.SENSOR_STATUS_*)
        // for the Qibla screen. flutter_compass reports "unreliable" as -1 and
        // mixes in the accelerometer's status, so its accuracy cannot tell the
        // screen when to ask for the figure-8 calibration.
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            COMPASS_ACCURACY_CHANNEL,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                stopAccuracyUpdates()
                val sensorManager =
                    getSystemService(Context.SENSOR_SERVICE) as? SensorManager ?: return
                val magnetometer =
                    sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) ?: return
                var last = Int.MIN_VALUE
                fun report(status: Int) {
                    if (status == last) return
                    last = status
                    events.success(status)
                }
                val listener = object : SensorEventListener {
                    override fun onSensorChanged(event: SensorEvent) = report(event.accuracy)
                    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) =
                        report(accuracy)
                }
                accuracyListener = listener
                sensorManager.registerListener(
                    listener,
                    magnetometer,
                    SensorManager.SENSOR_DELAY_UI,
                )
            }

            override fun onCancel(arguments: Any?) = stopAccuracyUpdates()
        })

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

    private fun stopAccuracyUpdates() {
        val listener = accuracyListener ?: return
        (getSystemService(Context.SENSOR_SERVICE) as? SensorManager)
            ?.unregisterListener(listener)
        accuracyListener = null
    }

    override fun onDestroy() {
        stopAccuracyUpdates()
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

    private fun vibrate(pattern: LongArray): Boolean {
        stopPreview()
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)
                ?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
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
