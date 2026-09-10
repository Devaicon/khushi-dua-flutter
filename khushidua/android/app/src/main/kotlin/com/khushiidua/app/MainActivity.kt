package com.khushiidua.app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val COMPASS_CHANNEL = "com.khushiidua.app/compass"
    }

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
