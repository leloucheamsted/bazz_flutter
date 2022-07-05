package dev.jorgeho1995.gnss_status

import android.location.*
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import java.util.*

class GnssStatusHandlerImpl internal constructor(var locationManager: LocationManager?) : EventChannel.StreamHandler {
    var listener: GnssStatus.Callback? = null
    private val uiThreadHandler = Handler(Looper.getMainLooper())
    var locationListener: LocationListener = object : LocationListener {
        override fun onLocationChanged(location: Location) {}
        override fun onStatusChanged(s: String, i: Int, bundle: Bundle) {}
        override fun onProviderEnabled(s: String) {}
        override fun onProviderDisabled(s: String) {}
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    override fun onListen(arguments: Any?, events: EventSink) {
        listener = createSensorEventListener(events)
        locationManager!!.registerGnssStatusCallback(listener as GnssStatus.Callback)
        locationManager!!.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0, 0.0f, locationListener)
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    override fun onCancel(arguments: Any) {
        locationManager!!.unregisterGnssStatusCallback(listener as GnssStatus.Callback)
        locationManager!!.removeUpdates(locationListener)
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    fun createSensorEventListener(events: EventSink): GnssStatus.Callback {
        return object : GnssStatus.Callback() {
            override fun onSatelliteStatusChanged(event: GnssStatus) {
                super.onSatelliteStatusChanged(event)
                val resultMap = HashMap<String, Any>()
                resultMap["satelliteCount"] = event.satelliteCount
                val numSat = event.satelliteCount
                resultMap["hashCode"] = event.hashCode()
                val statusMapList = ArrayList<HashMap<String, Any>>()
                for (i in 0 until numSat) {
                    val map = HashMap<String, Any>()
                    map["azimuthDegrees"] = event.getAzimuthDegrees(i)
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        map["carrierFrequencyHz"] = event.getCarrierFrequencyHz(i)
                    }
                    map["cn0DbHz"] = event.getCn0DbHz(i)
                    map["constellationType"] = event.getConstellationType(i)
                    map["elevationDegrees"] = event.getElevationDegrees(i)
                    map["svid"] = event.getSvid(i)
                    map["hasAlmanacData"] = event.hasAlmanacData(i)
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        map["hasCarrierFrequencyHz"] = event.hasCarrierFrequencyHz(i)
                    }
                    map["hasEphemerisData"] = event.hasEphemerisData(i)
                    map["usedInFix"] = event.usedInFix(i)
                    statusMapList.add(map)
                }
                resultMap["status"] = statusMapList
                uiThreadHandler.post { events.success(resultMap) }
            }
        }
    }
}