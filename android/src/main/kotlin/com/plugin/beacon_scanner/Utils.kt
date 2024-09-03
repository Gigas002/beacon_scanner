package com.plugin.beacon_scanner

import android.Manifest
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import org.altbeacon.beacon.Beacon
import org.altbeacon.beacon.Identifier
import org.altbeacon.beacon.MonitorNotifier
import org.altbeacon.beacon.Region
import java.util.Locale

internal object Utils {
    private val TAG = Utils::class.java.simpleName

    fun parseState(state: Int): String = when (state) {
        MonitorNotifier.INSIDE -> "inside"
        MonitorNotifier.OUTSIDE -> "outside"
        else -> "unknown"
    }

    fun requestPermissions(activityPluginBinding: ActivityPluginBinding) {
        Log.d(TAG, "requestPermissions: started")

        ActivityCompat.requestPermissions(
            activityPluginBinding.activity, arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN,
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.FOREGROUND_SERVICE,
            ), 1234
        )

        Log.d(TAG, "requestPermissions: ended")
    }

    fun beaconsToArray(beacons: List<Beacon>?): List<Map<String, Any>> =
        beacons?.map { beaconToMap(it) } ?: emptyList()

    private fun beaconToMap(beacon: Beacon): Map<String, Any> =
        mapOf(
            "proximityUUID" to beacon.id1.toString().uppercase(Locale.getDefault()),
            "major" to beacon.id2.toInt(),
            "minor" to beacon.id3.toInt(),
            "rssi" to beacon.rssi,
            "txPower" to beacon.txPower,
            "accuracy" to beacon.distance,
            "macAddress" to beacon.bluetoothAddress,
            "proximity" to rssiToProximity(beacon.rssi)
        )

    private fun rssiToProximity(rssi: Int): String = when {
        rssi <= 55 -> "near"
        rssi <= 75 -> "immediate"
        rssi <= 100 -> "far"
        else -> "undefined"
    }

    fun regionToMap(region: Region): Map<String, Any> = buildMap {
        put("identifier", region.uniqueId)
        region.id1?.let { put("proximityUUID", it.toString()) }
        region.id2?.let { put("major", it.toInt()) }
        region.id3?.let { put("minor", it.toInt()) }
    }

    fun regionFromMap(map: Map<*, *>): Region? {
        Log.d(TAG, "regionFromMap: started")

        var region: Region? = null

        try {
            val identifier = (map["identifier"] as? String) ?: ""
            val identifiers = mutableListOf<Identifier>()

            (map["proximityUUID"] as? String)?.let {
                identifiers.add(Identifier.parse(it))
            }
            (map["major"] as? Int)?.let {
                identifiers.add(Identifier.fromInt(it))
            }
            (map["minor"] as? Int)?.let {
                identifiers.add(Identifier.fromInt(it))
            }

            region = Region(identifier, identifiers)
        }
        catch (e: IllegalArgumentException) {
            Log.e(TAG, "regionFromMap: error: ${e.message}", e)
        }

        Log.d(TAG, "regionFromMap: ended")

        return region
    }

    @Suppress("unused")
    fun beaconFromMap(map: Map<*, *>): Beacon {
        return Beacon.Builder().apply {
            (map["proximityUUID"] as? String)?.let { setId1(it) }
            (map["major"] as? Int)?.let { setId2(it.toString()) }
            (map["minor"] as? Int)?.let { setId3(it.toString()) }
            (map["txPower"] as? Int)?.let { setTxPower(it) } ?: setTxPower(-59)
            setDataFields(listOf(0L))
            setManufacturer(0x004c)
        }.build()
    }
}
