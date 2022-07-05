package dev.jorgeho1995.gnss_status

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink

internal class StreamHandlerImpl(private val sensorManager: SensorManager, sensorType: Int) : EventChannel.StreamHandler {
    private var sensorEventListener: SensorEventListener? = null
    private val sensor: Sensor
    override fun onListen(arguments: Any, events: EventSink) {
        sensorEventListener = createSensorEventListener(events)
        sensorManager.registerListener(sensorEventListener, sensor, SensorManager.SENSOR_DELAY_NORMAL)
    }

    override fun onCancel(arguments: Any) {
        sensorManager.unregisterListener(sensorEventListener)
    }

    fun createSensorEventListener(events: EventSink): SensorEventListener {
        return object : SensorEventListener {
            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
            override fun onSensorChanged(event: SensorEvent) {
                val sensorValues = DoubleArray(event.values.size)
                for (i in event.values.indices) {
                    sensorValues[i] = event.values[i].toDouble()
                }
                events.success(sensorValues)
            }
        }
    }

    init {
        sensor = sensorManager.getDefaultSensor(sensorType)
    }
}