package dev.jorgeho1995.gnss_status

import android.content.Context
import android.location.LocationManager
import android.os.Build
import androidx.annotation.RequiresApi
import dev.jorgeho1995.gnss_status.GnssStatusHandlerImpl
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry

/** GnssStatusPlugin  */
class GnssStatusPlugin : FlutterPlugin {
  private var gnssStatusChannel: EventChannel? = null
  private var locationManager: LocationManager? = null
  private var context: Context? = null
  @RequiresApi(api = Build.VERSION_CODES.N)
  override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    setupEventChannels(context!!, flutterPluginBinding.binaryMessenger)
  }

  override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
    teardownEventChannels()
  }

  @RequiresApi(api = Build.VERSION_CODES.N)
  private fun setupEventChannels(context: Context, messenger: BinaryMessenger) {
    locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    gnssStatusChannel = EventChannel(messenger, GNSS_STATUS_CHANNEL_NAME)
    val gnssStatusStreamHandler = GnssStatusHandlerImpl(locationManager)
    gnssStatusChannel!!.setStreamHandler(gnssStatusStreamHandler)
  }

  private fun teardownEventChannels() {
    gnssStatusChannel!!.setStreamHandler(null)
  }

  companion object {
    private const val GNSS_STATUS_CHANNEL_NAME = "dev.jorgeho1995.gnss_status/gnss_status"

    @RequiresApi(api = Build.VERSION_CODES.N)
    fun registerWith(registrar: PluginRegistry.Registrar) {
      val plugin = GnssStatusPlugin()
      plugin.setupEventChannels(registrar.context(), registrar.messenger())
    }
  }
}
