package com.plugin.beacon_scanner

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.RemoteException
import android.util.Log
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import org.altbeacon.beacon.BeaconManager
import org.altbeacon.beacon.MonitorNotifier
import org.altbeacon.beacon.Region

// eventSink calls require a dirty hack
// see: https://github.com/flutter/flutter/issues/34993#issuecomment-520203503

internal class MonitoringService : Service() {
    companion object {
        private val TAG = MonitoringService::class.java.simpleName
        const val EVENT_CHANNEL = "beacon_scanner_event_monitoring"
    }

    private val uiThreadHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventSink? = null
    private var regions = ArrayList<Region>()
    private lateinit var beaconManager: BeaconManager

    private val binder = LocalBinder()
    inner class LocalBinder : Binder() {
        fun getService(): MonitoringService = this@MonitoringService
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
        stopMonitoring()

        Log.d(TAG, "onDestroy: ended")
    }

    val streamHandler: StreamHandler = object : StreamHandler {
        override fun onListen(o: Any?, eventSink: EventSink) {
            Log.d(TAG, "onListen: started, start monitoring=$o")

            startMonitoring(o, eventSink)

            Log.d(TAG, "onListen: ended")
        }

        override fun onCancel(o: Any?) {
            Log.d(TAG, "onCancel: started, stop monitoring=$o")

            stopMonitoring()

            Log.d(TAG, "onCancel: ended")
        }
    }

    private fun startMonitoring(o: Any?, eventSink: EventSink) {
        Log.d(TAG, "startMonitoring /w args: started")

        this.eventSink = eventSink

        if (o is List<*> && o.all { it is Map<*, *> }) {
            regions.clear()

            o.mapNotNull { it as? Map<*, *> }
                .mapNotNull { Utils.regionFromMap(it) }
                .let { regions.addAll(it) }

            startMonitoring()
        }
        else {
            val message = "startMonitoring /w args: error: couldn't start monitoring"
            Log.e(TAG, message)
            uiThreadHandler.post {
                this.eventSink?.error(TAG, message, null)
            }
        }

        Log.d(TAG, "startMonitoring /w args: ended")
    }

    private fun startMonitoring() {
        Log.d(TAG, "startMonitoring: started")

        if (regions.isEmpty()) {
            val message = "startMonitoring: error: no regions for monitoring"
            Log.e(TAG, message)
            uiThreadHandler.post {
                this.eventSink?.error(TAG, message, null)
            }

            return
        }

        try {
            beaconManager.removeAllMonitorNotifiers()
            beaconManager.addMonitorNotifier(monitorNotifier)

            for (region in regions) {
                beaconManager.startMonitoring(region)
            }
        }
        catch (e: RemoteException) {
            Log.e(TAG, "startMonitoring: error: ${e.message}", e)
            uiThreadHandler.post {
                this.eventSink?.error(TAG, e.message, null)
            }
        }

        Log.d(TAG, "startMonitoring: ended")
    }

    fun stopMonitoring() {
        Log.d(TAG, "stopMonitoring: started")

        if (regions.isNotEmpty()) {
            try {
                for (region in regions) {
                    beaconManager.stopMonitoring(region)
                }

                beaconManager.removeMonitorNotifier(monitorNotifier)
            } catch (ignored: RemoteException) { }
        }

        this.eventSink = null

        Log.d(TAG, "stopMonitoring: ended")
    }

    private val monitorNotifier: MonitorNotifier = object : MonitorNotifier {
        override fun didEnterRegion(region: Region) {
            Log.d(TAG, "monitorNotifier: didEnterRegion: started")

            uiThreadHandler.post {
                eventSink?.success(
                    mapOf(
                        "event" to "didEnterRegion",
                        "region" to Utils.regionToMap(region),
                    )
                )
            }

            Log.d(TAG, "monitorNotifier: didEnterRegion: ended")
        }

        override fun didExitRegion(region: Region) {
            Log.d(TAG, "monitorNotifier: didExitRegion: started")

            uiThreadHandler.post {
                eventSink?.success(
                    mapOf(
                        "event" to "didExitRegion",
                        "region" to Utils.regionToMap(region),
                    )
                )
            }

            Log.d(TAG, "monitorNotifier: didExitRegion: ended")
        }

        override fun didDetermineStateForRegion(state: Int, region: Region) {
            Log.d(TAG, "monitorNotifier: didDetermineStateForRegion: started")

            uiThreadHandler.post {
                eventSink?.success(
                    mapOf(
                        "event" to "didDetermineStateForRegion",
                        "state" to Utils.parseState(state),
                        "region" to Utils.regionToMap(region)
                    )
                )
            }

            Log.d(TAG, "monitorNotifier: didDetermineStateForRegion: ended")
        }
    }
}
