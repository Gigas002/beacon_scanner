package com.plugin.beacon_scanner

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.RemoteException
import android.util.Log
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.EventChannel.EventSink
import org.altbeacon.beacon.BeaconManager
import org.altbeacon.beacon.RangeNotifier
import org.altbeacon.beacon.Region

// eventSink calls require a dirty hack
// see: https://github.com/flutter/flutter/issues/34993#issuecomment-520203503

internal class RangingService : Service() {
    companion object {
        private val TAG = RangingService::class.java.simpleName
        const val EVENT_CHANNEL = "beacon_scanner_event_ranging"
    }

    private val uiThreadHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventSink? = null
    private var regions = ArrayList<Region>()
    private lateinit var beaconManager: BeaconManager

    private val binder = LocalBinder()
    inner class LocalBinder : Binder() {
        fun getService(): RangingService = this@RangingService
    }

    override fun onBind(intent: Intent?): IBinder {
        Log.d(TAG, "onBind: triggered")

        return binder
    }

    override fun onCreate() {
        Log.d(TAG, "onCreate: started")

        super.onCreate()

        beaconManager = BeaconManager.getInstanceForApplication(this)

        Log.d(TAG, "onCreate: ended")
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy: started")

        super.onDestroy()

        // comment this if you want to continue scan when your app is terminated
        stopRanging()

        Log.d(TAG, "onDestroy: ended")
    }

    val streamHandler: StreamHandler = object : StreamHandler {
        override fun onListen(o: Any?, eventSink: EventSink) {
            Log.d(TAG, "onListen: started, start ranging=$o")

            startRanging(o, eventSink)

            Log.d(TAG, "onListen: ended")
        }

        override fun onCancel(o: Any?) {
            Log.d(TAG, "onCancel: started, stop ranging=$o")

            stopRanging()

            Log.d(TAG, "onCancel: ended")
        }
    }

    private fun startRanging(o: Any?, eventSink: EventSink) {
        Log.d(TAG, "startRanging /w args: started")

        this.eventSink = eventSink

        if (o is List<*> && o.all { it is Map<*, *> }) {
            regions.clear()

            o.mapNotNull { it as? Map<*, *> }
                .mapNotNull { Utils.regionFromMap(it) }
                .let { regions.addAll(it) }

            startRanging()
        }
        else {
            val message = "startRanging /w args: error: couldn't start ranging"
            Log.e(TAG, message)
            uiThreadHandler.post {
                this.eventSink?.error(TAG, message, null)
            }
        }

        Log.d(TAG, "startRanging /w args: ended")
    }

    private fun startRanging() {
        Log.d(TAG, "startRanging: started")

        if (regions.isEmpty()) {
            val message = "startRanging: error: no regions for ranging"
            Log.e(TAG, message)
            uiThreadHandler.post {
                this.eventSink?.error(TAG, message, null)
            }

            return
        }

        try {
            beaconManager.removeAllRangeNotifiers()
            beaconManager.addRangeNotifier(rangeNotifier)

            for (region in regions) {
                beaconManager.startRangingBeacons(region)
            }
        }
        catch (e: RemoteException) {
            Log.e(TAG, "startRanging: error: ${e.message}", e)
            uiThreadHandler.post {
                this.eventSink?.error(TAG, e.message, null)
            }
        }

        Log.d(TAG, "startRanging: ended")
    }

    fun stopRanging() {
        Log.d(TAG, "stopRanging: started")

        if (regions.isNotEmpty()) {
            try {
                for (region in regions) {
                    beaconManager.stopRangingBeacons(region)
                }

                beaconManager.removeRangeNotifier(rangeNotifier)
            }
            catch (ignored: RemoteException) { }
        }

        this.eventSink = null

        Log.d(TAG, "stopRanging: ended")
    }

    private val rangeNotifier = RangeNotifier { collection, region ->
        Log.d(TAG, "rangeNotifier: started")

        uiThreadHandler.post {
            eventSink?.success(
                mapOf(
                    "region" to Utils.regionToMap(region),
                    "beacons" to Utils.beaconsToArray(ArrayList(collection))
                )
            )
        }

        Log.d(TAG, "rangeNotifier: ended")
    }
}
