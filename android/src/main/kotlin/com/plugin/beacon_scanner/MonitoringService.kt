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
import org.altbeacon.beacon.MonitorNotifier
import org.altbeacon.beacon.Region

internal class MonitoringService : Service() {
    companion object {
        private val TAG = MonitoringService::class.java.simpleName
        const val EVENT_CHANNEL = "beacon_scanner_event_monitoring"
    }

    private var eventSinkMonitoring: MainThreadEventSink? = null
    private var regionMonitoring: MutableList<Region?>? = null
    private lateinit var beaconManager: BeaconManager

    private val binder = LocalBinder()
    inner class LocalBinder : Binder() {
        fun getService(): MonitoringService = this@MonitoringService
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
        stopMonitoring()
    }

    val monitoringStreamHandler: EventChannel.StreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(o: Any?, eventSink: EventSink) {
            Log.d(TAG, "START MONITORING=$o")
            startMonitoring(o, eventSink)
        }

        override fun onCancel(o: Any?) {
            Log.d(TAG, "STOP MONITORING=$o")
            stopMonitoring()
        }
    }

    private fun startMonitoring(o: Any?, eventSink: EventSink) {
        if (o is List<*>) {
            if (regionMonitoring == null) {
                regionMonitoring = ArrayList()
            }
            else {
                regionMonitoring!!.clear()
            }

            for (`object` in o) {
                if (`object` is Map<*, *>) {
                    val region = Utils.regionFromMap(`object`)
                    regionMonitoring!!.add(region)
                }
            }
        }
        else {
            eventSink.error(TAG, "invalid region for monitoring", null)

            return
        }

        eventSinkMonitoring = MainThreadEventSink(eventSink)

        startMonitoring()
    }

    private fun startMonitoring() {
        if (regionMonitoring == null || regionMonitoring!!.isEmpty()) {
            Log.e(TAG, "Region monitoring is null or empty. Monitoring not started.")

            return
        }

        try {
            beaconManager.removeAllMonitorNotifiers()
            beaconManager.addMonitorNotifier(monitorNotifier)

            for (region in regionMonitoring!!) {
                if(region != null) {
                    beaconManager.startMonitoring(region)
                }
            }
        }
        catch (e: RemoteException) {
            if (eventSinkMonitoring != null) {
                eventSinkMonitoring!!.error(TAG, e.localizedMessage, null)
            }
        }
    }

    fun stopMonitoring() {
        if (regionMonitoring != null && regionMonitoring!!.isNotEmpty()) {
            try {
                for (region in regionMonitoring!!) {
                    if(region != null) {
                        beaconManager.stopMonitoring(region)
                    }
                }

                beaconManager.removeMonitorNotifier(monitorNotifier)
            } catch (ignored: RemoteException) { }
        }

        eventSinkMonitoring = null
    }

    private val monitorNotifier: MonitorNotifier = object : MonitorNotifier {
        override fun didEnterRegion(region: Region) {
            if (eventSinkMonitoring != null) {
                val map: MutableMap<String, Any?> = HashMap()
                map["event"] = "didEnterRegion"
                map["region"] = Utils.regionToMap(region)
                eventSinkMonitoring!!.success(map)
            }
        }

        override fun didExitRegion(region: Region) {
            if (eventSinkMonitoring != null) {
                val map: MutableMap<String, Any?> = HashMap()
                map["event"] = "didExitRegion"
                map["region"] = Utils.regionToMap(region)
                eventSinkMonitoring!!.success(map)
            }
        }

        override fun didDetermineStateForRegion(state: Int, region: Region) {
            if (eventSinkMonitoring != null) {
                val map: MutableMap<String, Any?> = HashMap()
                map["event"] = "didDetermineStateForRegion"
                map["state"] = Utils.parseState(state)
                map["region"] = Utils.regionToMap(region)
                eventSinkMonitoring!!.success(map)
            }
        }
    }
}