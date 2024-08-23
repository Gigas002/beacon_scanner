package com.plugin.beacon_scanner

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.os.RemoteException
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import org.altbeacon.beacon.BeaconManager
import org.altbeacon.beacon.RangeNotifier
import org.altbeacon.beacon.Region

internal class RangingService : Service() {
    companion object {
        private val TAG = RangingService::class.java.simpleName
        const val EVENT_CHANNEL = "beacon_scanner_event_ranging"
    }

    private var eventSinkRanging: MainThreadEventSink? = null
    private var regionRanging: MutableList<Region>? = null
    private lateinit var beaconManager: BeaconManager

    private val binder = LocalBinder()
    inner class LocalBinder : Binder() {
        fun getService(): RangingService = this@RangingService
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun onCreate() {
        super.onCreate()
        beaconManager = BeaconManager.getInstanceForApplication(this)
    }

    override fun onDestroy() {
        super.onDestroy()
        // comment this if you want to continue scan when your app is terminated
        stopRanging()
    }

    val rangingStreamHandler: EventChannel.StreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(o: Any?, eventSink: EventSink) {
            Log.d(TAG, "START RANGING=$o")
            startRanging(o, eventSink)
        }

        override fun onCancel(o: Any?) {
            Log.d(TAG, "STOP RANGING=$o")
            stopRanging()
        }
    }

    private fun startRanging(o: Any?, eventSink: EventSink) {
        if (o is List<*>) {
            if (regionRanging == null) {
                regionRanging = ArrayList()
            }
            else {
                regionRanging!!.clear()
            }

            for (`object` in o) {
                if (`object` is Map<*, *>) {
                    val region = Utils.regionFromMap(`object`)
                    if (region != null) {
                        regionRanging!!.add(region)
                    }
                }
            }
        }
        else {
            eventSink.error(TAG, "invalid region for ranging", null)

            return
        }

        eventSinkRanging = MainThreadEventSink(eventSink)

        startRanging()
    }

    private fun startRanging() {
        if (regionRanging == null || regionRanging!!.isEmpty()) {
            Log.e(TAG, "Region ranging is null or empty. Ranging not started.")

            return
        }

        try {
            beaconManager.removeAllRangeNotifiers()
            beaconManager.addRangeNotifier(rangeNotifier)

            for (region in regionRanging!!) {
                beaconManager.startRangingBeacons(region)
            }
        }
        catch (e: RemoteException) {
            eventSinkRanging?.error(TAG, e.localizedMessage, null)
        }
    }

    fun stopRanging() {
        if (regionRanging != null && regionRanging!!.isNotEmpty()) {
            try {
                for (region in regionRanging!!) {
                    beaconManager.stopRangingBeacons(region)
                }

                beaconManager.removeRangeNotifier(rangeNotifier)
            }
            catch (ignored: RemoteException) { }
        }

        eventSinkRanging = null
    }

    private val rangeNotifier = RangeNotifier { collection, region ->
        eventSinkRanging?.let {
            val map: MutableMap<String, Any?> = HashMap()
            map["region"] = Utils.regionToMap(region)
            map["beacons"] = Utils.beaconsToArray(ArrayList(collection))
            it.success(map)
        }
    }
}