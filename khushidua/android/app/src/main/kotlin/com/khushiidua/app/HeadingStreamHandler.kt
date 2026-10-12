package com.khushiidua.app

import android.content.Context
import android.content.pm.ApplicationInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.hardware.display.DisplayManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Display
import android.view.Surface
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.location.DeviceOrientation
import com.google.android.gms.location.DeviceOrientationListener
import com.google.android.gms.location.DeviceOrientationRequest
import com.google.android.gms.location.FusedOrientationProviderClient
import com.google.android.gms.location.LocationServices
import io.flutter.plugin.common.EventChannel
import java.util.Locale
import java.util.concurrent.Executor
import kotlin.math.atan2
import kotlin.math.sqrt

/**
 * Streams which way the top of the screen points, for the Qibla screen.
 *
 * Sources, best first:
 *
 * 1. Google Play services' Fused Orientation Provider. It runs Google's own
 *    magnetometer calibration and gyro-bias estimation instead of relying on
 *    each manufacturer's, reports its heading error in degrees, and applies the
 *    local magnetic declination itself, so the heading is referenced to true
 *    north. It does that whenever it knows the device's location; the Qibla
 *    screen only opens once location is on, permitted and fixed.
 * 2. The platform rotation vector, referenced to magnetic north, with the
 *    heading error the sensor HAL reports in `values[4]` where it has one.
 * 3. Accelerometer plus magnetometer, magnetic north, for devices with no
 *    rotation vector at all.
 *
 * Each event also carries the magnetometer's calibration status and the
 * strength of the field it measures, so the screen can tell a compass that
 * needs calibrating from one sitting next to a magnet, and gravity in screen
 * axes, which tilts the dial and drives its level.
 *
 * Debuggable builds log the raw sensors next to the heading once a second.
 * Any build does after `adb shell setprop log.tag.QiblaHeading DEBUG`, read
 * when the screen opens; events then carry `verbose` so Dart logs too.
 */
class HeadingStreamHandler(context: Context) : EventChannel.StreamHandler {
    private companion object {
        const val TAG = "QiblaHeading"

        /** Platform sensor rate hint: 50 Hz, the fused provider's default. */
        const val SENSOR_PERIOD_US = 20_000

        /** At most ~30 events a second to Flutter; the screen smooths them. */
        const val EMIT_INTERVAL_MS = 33L

        /** How long the fused provider has to deliver a first reading before
         *  the platform sensors take over. */
        const val FUSED_FIRST_READING_TIMEOUT_MS = 2_500L

        /** Share of each new sample blended into a low-passed value. */
        const val FIELD_SMOOTHING = 0.1
        const val ACCEL_MAG_SMOOTHING = 0.25f

        const val DIAGNOSTIC_INTERVAL_MS = 1_000L
    }

    private val appContext = context.applicationContext
    private val sensorManager =
        appContext.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
    private val displayManager =
        appContext.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
    private val handler = Handler(Looper.getMainLooper())
    private val mainExecutor = Executor { handler.post(it) }
    private val debuggable =
        (appContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    /** Whether to log diagnostics; decided each time the stream starts. */
    private var verbose = false

    private var sink: EventChannel.EventSink? = null

    /** Bumped on every start and stop, so a stopped source's late callbacks
     *  are ignored. */
    private var session = 0

    private var fusedClient: FusedOrientationProviderClient? = null
    private var fusedListener: DeviceOrientationListener? = null
    private var fusedSeen = false
    private var headingListener: SensorEventListener? = null
    private var magnetometerListener: SensorEventListener? = null
    private var gravityListener: SensorEventListener? = null
    private var diagnosticsListener: SensorEventListener? = null

    private var magnetometerStatus: Int? = null
    private var fieldMicroTesla: Double? = null
    private var screenGravity: List<Double>? = null
    private var lastEmitMs = 0L

    private val rotationMatrix = FloatArray(9)
    private var gravity: FloatArray? = null
    private var geomagnetic: FloatArray? = null

    // Debuggable builds only.
    private val latest = HashMap<Int, FloatArray>()
    private var lastFused: DeviceOrientation? = null
    private var lastDiagnosticMs = 0L

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        stop()
        sink = events
        val manager = sensorManager
        if (manager == null) {
            events.error("NO_SENSORS", "Sensor service unavailable.", null)
            return
        }
        verbose = debuggable || Log.isLoggable(TAG, Log.DEBUG)
        startMagnetometer(manager)
        startGravity(manager)
        if (verbose) startDiagnostics(manager)
        if (!startFused()) startPlatformSensors(manager)
    }

    override fun onCancel(arguments: Any?) = stop()

    /** Releases every sensor and the fused provider. Safe to call twice. */
    fun stop() {
        session++
        handler.removeCallbacksAndMessages(null)
        stopFused()
        sensorManager?.let { manager ->
            listOfNotNull(
                headingListener,
                magnetometerListener,
                gravityListener,
                diagnosticsListener,
            )
                .forEach(manager::unregisterListener)
        }
        headingListener = null
        magnetometerListener = null
        gravityListener = null
        diagnosticsListener = null
        sink = null
        magnetometerStatus = null
        fieldMicroTesla = null
        screenGravity = null
        gravity = null
        geomagnetic = null
        lastEmitMs = 0L
        latest.clear()
        lastFused = null
    }

    private fun startFused(): Boolean {
        val availability =
            GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(appContext)
        if (availability != ConnectionResult.SUCCESS) {
            Log.i(TAG, "Play services unavailable ($availability); using platform sensors")
            return false
        }

        fusedClient = LocationServices.getFusedOrientationProviderClient(appContext)
        requestFused()
        val current = session
        handler.postDelayed({
            if (current == session && !fusedSeen) {
                Log.w(TAG, "Fused orientation sent no reading; using platform sensors")
                fallBackFromFused()
            }
        }, FUSED_FIRST_READING_TIMEOUT_MS)
        return true
    }

    /** Registers with the fused provider, replacing any registration this
     *  handler already has. */
    private fun requestFused() {
        val client = fusedClient ?: return
        fusedListener?.let(client::removeOrientationUpdates)

        val current = session
        val listener = object : DeviceOrientationListener {
            override fun onDeviceOrientationChanged(orientation: DeviceOrientation) {
                // Only the live registration: a replaced one can still have a
                // reading in flight.
                if (current == session && fusedListener === this) onFused(orientation)
            }
        }
        fusedListener = listener

        // The longest preset period: Google asks for the slowest rate that
        // serves the purpose, and 50 Hz is ample for a hand-held compass.
        val request =
            DeviceOrientationRequest.Builder(DeviceOrientationRequest.OUTPUT_PERIOD_DEFAULT)
                .build()
        client.requestOrientationUpdates(request, mainExecutor, listener)
            .addOnFailureListener(mainExecutor) { e ->
                if (current != session || fusedListener !== listener) {
                    return@addOnFailureListener
                }
                // Older Play services, or a device without a gyroscope.
                Log.w(TAG, "Fused orientation unavailable: ${e.message}")
                fallBackFromFused()
            }
    }

    private fun stopFused() {
        val listener = fusedListener ?: return
        fusedClient?.removeOrientationUpdates(listener)
        fusedListener = null
        fusedClient = null
        fusedSeen = false
    }

    private fun fallBackFromFused() {
        // The failure and the timeout can both fire; fall back only once.
        if (fusedListener == null) return
        stopFused()
        sensorManager?.let(::startPlatformSensors)
    }

    private fun onFused(orientation: DeviceOrientation) {
        fusedSeen = true
        if (verbose) lastFused = orientation
        // The provider's heading is for the top of the device; the screen's
        // up is a quarter turn clockwise of it per quarter of display rotation.
        emit(
            heading = orientation.headingDegrees + displayRotation() * 90.0,
            reference = "true",
            source = "fused",
            errorDegrees = orientation.headingErrorDegrees.toDouble(),
        )
    }

    private fun startPlatformSensors(manager: SensorManager) {
        val rotationVector = manager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        val accelerometer = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        val magnetometer = manager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

        val current = session
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (current == session) onPlatformSensor(event)
            }

            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) = Unit
        }

        when {
            rotationVector != null ->
                manager.registerListener(listener, rotationVector, SENSOR_PERIOD_US)
            accelerometer != null && magnetometer != null -> {
                manager.registerListener(listener, accelerometer, SENSOR_PERIOD_US)
                manager.registerListener(listener, magnetometer, SENSOR_PERIOD_US)
            }
            else -> {
                sink?.error("NO_SENSORS", "This device has no compass sensors.", null)
                return
            }
        }
        headingListener = listener
        Log.i(
            TAG,
            "Heading from ${if (rotationVector != null) "rotation vector" else "accelerometer + magnetometer"}",
        )
    }

    private fun onPlatformSensor(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR -> {
                SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
                // values[4] is the HAL's estimated heading error in radians, -1
                // when it has none; some HALs leave it at 0, which means none too.
                val error = event.values.getOrNull(4)
                    ?.takeIf { it > 0f }
                    ?.let { Math.toDegrees(it.toDouble()) }
                emit(screenHeading(rotationMatrix), "magnetic", "rotationVector", error)
            }
            Sensor.TYPE_ACCELEROMETER -> {
                gravity = lowPass(event.values, gravity)
                emitAccelMag()
            }
            Sensor.TYPE_MAGNETIC_FIELD -> {
                geomagnetic = lowPass(event.values, geomagnetic)
                emitAccelMag()
            }
        }
    }

    private fun emitAccelMag() {
        val g = gravity ?: return
        val m = geomagnetic ?: return
        // False in free fall or when the field is parallel to gravity.
        if (!SensorManager.getRotationMatrix(rotationMatrix, null, g, m)) return
        emit(screenHeading(rotationMatrix), "magnetic", "accelMag", null)
    }

    private fun lowPass(input: FloatArray, previous: FloatArray?): FloatArray {
        if (previous == null) return input.copyOf(3)
        for (i in 0 until 3) previous[i] += ACCEL_MAG_SMOOTHING * (input[i] - previous[i])
        return previous
    }

    /**
     * Heading of the screen's up, in degrees clockwise from the matrix's north.
     *
     * Uses screen-up minus out-of-screen, so it holds however the phone is
     * tilted: held flat that is the screen's up; held upright facing the user
     * it is out of the back of the phone, the way the user faces; in between
     * the two agree. Null when the phone is placed so neither is horizontal.
     */
    private fun screenHeading(r: FloatArray): Double? {
        // The columns of R are the device axes in (east, north, up).
        val (upEast, upNorth) = when (displayRotation()) {
            Surface.ROTATION_90 -> r[0] to r[3] // device +X
            Surface.ROTATION_180 -> -r[1] to -r[4] // device -Y
            Surface.ROTATION_270 -> -r[0] to -r[3] // device -X
            else -> r[1] to r[4] // device +Y
        }
        val east = (upEast - r[2]).toDouble()
        val north = (upNorth - r[5]).toDouble()
        if (east * east + north * north < 1e-4) return null
        return Math.toDegrees(atan2(east, north))
    }

    private fun displayRotation(): Int =
        displayManager?.getDisplay(Display.DEFAULT_DISPLAY)?.rotation ?: Surface.ROTATION_0

    private fun startMagnetometer(manager: SensorManager) {
        val magnetometer = manager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) ?: return
        val current = session
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (current != session) return
                magnetometerStatus = event.accuracy
                val v = event.values
                val magnitude =
                    sqrt((v[0] * v[0] + v[1] * v[1] + v[2] * v[2]).toDouble())
                fieldMicroTesla =
                    fieldMicroTesla?.let { it + FIELD_SMOOTHING * (magnitude - it) } ?: magnitude
            }

            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
                if (current == session) magnetometerStatus = accuracy
            }
        }
        manager.registerListener(listener, magnetometer, SensorManager.SENSOR_DELAY_UI)
        magnetometerListener = listener
    }

    /** Gravity, fused with the gyroscope where the device has a gravity
     *  sensor, turned into screen axes: x right, y up, z out of the screen. */
    private fun startGravity(manager: SensorManager) {
        val sensor = manager.getDefaultSensor(Sensor.TYPE_GRAVITY)
            ?: manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            ?: return
        val smoothing = if (sensor.type == Sensor.TYPE_GRAVITY) 1f else ACCEL_MAG_SMOOTHING
        var filtered: FloatArray? = null
        val current = session
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (current != session) return
                val g = filtered?.also { f ->
                    for (i in 0 until 3) f[i] += smoothing * (event.values[i] - f[i])
                } ?: event.values.copyOf(3)
                filtered = g
                val (x, y) = when (displayRotation()) {
                    Surface.ROTATION_90 -> -g[1] to g[0]
                    Surface.ROTATION_180 -> -g[0] to -g[1]
                    Surface.ROTATION_270 -> g[1] to -g[0]
                    else -> g[0] to g[1]
                }
                screenGravity = listOf(x.toDouble(), y.toDouble(), g[2].toDouble())
            }

            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) = Unit
        }
        manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_GAME)
        gravityListener = listener
    }

    private fun emit(
        heading: Double?,
        reference: String,
        source: String,
        errorDegrees: Double?,
    ) {
        val events = sink ?: return
        if (heading == null || !heading.isFinite()) return
        val now = SystemClock.elapsedRealtime()
        if (now - lastEmitMs < EMIT_INTERVAL_MS) return
        lastEmitMs = now

        val normalized = ((heading % 360.0) + 360.0) % 360.0
        events.success(
            mapOf(
                "heading" to normalized,
                "reference" to reference,
                "source" to source,
                "errorDegrees" to errorDegrees,
                "magnetometerStatus" to magnetometerStatus,
                "fieldMicroTesla" to fieldMicroTesla,
                "verbose" to verbose,
                "gravity" to screenGravity,
            ),
        )

        if (verbose && now - lastDiagnosticMs >= DIAGNOSTIC_INTERVAL_MS) {
            lastDiagnosticMs = now
            logDiagnostics(normalized, source, errorDegrees)
        }
    }

    private fun startDiagnostics(manager: SensorManager) {
        val current = session
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                // The platform may reuse the values array.
                if (current == session) latest[event.sensor.type] = event.values.clone()
            }

            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) = Unit
        }
        listOf(
            Sensor.TYPE_MAGNETIC_FIELD,
            Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED,
            Sensor.TYPE_ACCELEROMETER,
            Sensor.TYPE_GYROSCOPE,
            Sensor.TYPE_ROTATION_VECTOR,
        ).mapNotNull(manager::getDefaultSensor).forEach {
            manager.registerListener(listener, it, SensorManager.SENSOR_DELAY_UI)
        }
        diagnosticsListener = listener
    }

    /** Puts every stage side by side, so a wrong heading can be traced to
     *  the sensor, the fusion, or the app. */
    private fun logDiagnostics(heading: Double, source: String, errorDegrees: Double?) {
        fun f(v: Number?) = v?.let { String.format(Locale.US, "%.1f", it.toDouble()) } ?: "-"
        fun vec(v: FloatArray?) = v?.joinToString(",", "(", ")") { f(it) } ?: "-"

        // The raw rotation vector's azimuth, magnetic north, before any of
        // the app's handling.
        val rv = latest[Sensor.TYPE_ROTATION_VECTOR]
        val rvAzimuth = rv?.let {
            val m = FloatArray(9)
            SensorManager.getRotationMatrixFromVector(m, it)
            val o = FloatArray(3)
            SensorManager.getOrientation(m, o)
            (Math.toDegrees(o[0].toDouble()) + 360.0) % 360.0
        }
        val fused = lastFused
        Log.d(
            TAG,
            "out=${f(heading)}° [$source ±${f(errorDegrees)}] " +
                "fused=${f(fused?.headingDegrees)}±${f(fused?.headingErrorDegrees)} " +
                "cons=${if (fused?.hasConservativeHeadingErrorDegrees() == true) f(fused.conservativeHeadingErrorDegrees) else "-"} " +
                "rvAzimuthMag=${f(rvAzimuth)} display=${displayRotation() * 90} | " +
                "mag=${vec(latest[Sensor.TYPE_MAGNETIC_FIELD])} |B|=${f(fieldMicroTesla)}uT " +
                "status=$magnetometerStatus " +
                "uncal+bias=${vec(latest[Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED])} | acc=${vec(latest[Sensor.TYPE_ACCELEROMETER])} " +
                "gyro=${vec(latest[Sensor.TYPE_GYROSCOPE])} rv=${vec(rv)}",
        )
    }
}
