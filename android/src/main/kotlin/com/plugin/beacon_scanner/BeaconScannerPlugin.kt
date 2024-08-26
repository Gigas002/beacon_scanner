package com.plugin.beacon_scanner

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.os.RemoteException
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.altbeacon.beacon.BeaconManager
import org.altbeacon.beacon.BeaconParser

class BeaconScannerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    // region CONSTANTS

    companion object {
        const val IBEACON_LAYOUT = "m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24"
        const val METHOD_INITIALIZE = "initialize"
        const val METHOD_CLOSE = "close"
        const val METHOD_SET_SCAN_PERIOD = "setScanPeriod"
        const val METHOD_SET_BETWEEN_SCAN_PERIOD = "setBetweenScanPeriod"
        const val METHOD_CHANNEL = "beacon_scanner"
        private val TAG = BeaconScannerPlugin::class.java.simpleName
    }

    // region PROPERTIES

    private val beaconParser = BeaconParser().setBeaconLayout(IBEACON_LAYOUT)

    // plugin bindings
    private lateinit var flutterPluginBinding: FlutterPluginBinding
    private lateinit var activityPluginBinding: ActivityPluginBinding

    // services
    private var rangingService: RangingService? = null
    private var monitoringService: MonitoringService? = null
    private var isRangingServiceBound = false
    private var isMonitoringServiceBound = false
    private val rangingServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName?, service: IBinder?) {
            val binder = service as? RangingService.LocalBinder
            rangingService = binder?.getService()

            eventChannelRanging.setStreamHandler(rangingService?.rangingStreamHandler)
            isRangingServiceBound = true
        }

        override fun onServiceDisconnected(className: ComponentName?) {
            rangingService = null
            isRangingServiceBound = false
        }
    }
    private val monitoringServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName?, service: IBinder?) {
            val binder = service as? MonitoringService.LocalBinder
            monitoringService = binder?.getService()

            eventChannelMonitoring.setStreamHandler(monitoringService?.monitoringStreamHandler)
            isMonitoringServiceBound = true
        }

        override fun onServiceDisconnected(className: ComponentName?) {
            monitoringService = null
            isMonitoringServiceBound = false
        }
    }

    private lateinit var beaconManager: BeaconManager
    private lateinit var channel: MethodChannel
    private lateinit var eventChannelRanging: EventChannel
    private lateinit var eventChannelMonitoring: EventChannel

    // region Initialization

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        flutterPluginBinding = binding

        channel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        channel.setMethodCallHandler(this)

        eventChannelRanging = EventChannel(binding.binaryMessenger, RangingService.EVENT_CHANNEL)
        eventChannelMonitoring = EventChannel(binding.binaryMessenger, MonitoringService.EVENT_CHANNEL)

        beaconManager = BeaconManager.getInstanceForApplication(binding.applicationContext)
        if (!beaconManager.beaconParsers.contains(beaconParser)) {
            beaconManager.beaconParsers.clear()
            beaconManager.beaconParsers.add(beaconParser)
        }
        // for better background service run
        beaconManager.setEnableScheduledScanJobs(false)

        // required to run service on foreground
        //  setupForegroundService()

        val rangingIntent = Intent(binding.applicationContext, RangingService::class.java)
        flutterPluginBinding.applicationContext.bindService(rangingIntent, rangingServiceConnection, Context.BIND_AUTO_CREATE)
        rangingService?.startService(rangingIntent)
        // rangingService?.startForegroundService(rangingIntent)

        val monitoringIntent = Intent(binding.applicationContext, MonitoringService::class.java)
        flutterPluginBinding.applicationContext.bindService(monitoringIntent, monitoringServiceConnection, Context.BIND_AUTO_CREATE)
        monitoringService?.startService(monitoringIntent)
        // monitoringService?.startForegroundService(monitoringIntent)
    }

    private fun setupForegroundService() {
        Log.d(TAG, "Calling enableForegroundServiceScanning")
        beaconManager.enableForegroundServiceScanning(createNotification(), 456)
        Log.d(TAG, "Back from  enableForegroundServiceScanning")
    }

    private fun createNotification(): Notification {
        val notificationTitle = "Beacon Plugin Manager"
        val notificationContent = "Starting foreground service"
        val channelId = "beacon_service_channel"
        val notificationManager = flutterPluginBinding.applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channel = NotificationChannel(channelId, "Beacon Service", NotificationManager.IMPORTANCE_LOW)
        notificationManager.createNotificationChannel(channel)

        return NotificationCompat.Builder(flutterPluginBinding.applicationContext, channelId)
            .setContentTitle(notificationTitle)
            .setContentText(notificationContent)
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannelRanging.setStreamHandler(null)
        eventChannelMonitoring.setStreamHandler(null)

        binding.applicationContext.unbindService(rangingServiceConnection)
        binding.applicationContext.unbindService(monitoringServiceConnection)

        beaconManager.removeAllRangeNotifiers()
        beaconManager.removeAllMonitorNotifiers()
    }

    // region Handle flutter method calls

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            METHOD_INITIALIZE -> initialize(result)
            METHOD_CLOSE -> close(result)
            METHOD_SET_SCAN_PERIOD -> setScanPeriod(call.argument<Int>("scanPeriod")!!, result)
            METHOD_SET_BETWEEN_SCAN_PERIOD -> setBetweenScanPeriod(call.argument<Int>("betweenScanPeriod")!!, result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(result: Result) {
        Utils.requestPermissions(activityPluginBinding)

        if (isRangingServiceBound && isMonitoringServiceBound) {
            result.success(true)
        }
        else {
            result.error(TAG, "Ranging or monitoring service is not bound", null)
        }
    }

    private fun close(result: Result) {
        rangingService?.stopRanging()
        beaconManager.removeAllRangeNotifiers()
        monitoringService?.stopMonitoring()
        beaconManager.removeAllMonitorNotifiers()
        result.success(true)
    }

    private fun setScanPeriod(scanPeriod: Int, result: Result) {
        beaconManager.foregroundScanPeriod = scanPeriod.toLong()
        beaconManager.backgroundScanPeriod = scanPeriod.toLong()
        updateScanPeriods(beaconManager, result)
    }

    private fun setBetweenScanPeriod(betweenScanPeriod: Int, result: Result) {
        beaconManager.foregroundBetweenScanPeriod = betweenScanPeriod.toLong()
        beaconManager.backgroundBetweenScanPeriod = betweenScanPeriod.toLong()
        updateScanPeriods(beaconManager, result)
    }

    private fun updateScanPeriods(manager: BeaconManager, result: Result) {
        try {
            manager.updateScanPeriods()
            result.success(true)
        }
        catch (e: RemoteException) {
            result.success(false)
        }
    }

    // region Activity stuff

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityPluginBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {}
}
