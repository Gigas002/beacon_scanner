package com.plugin.beacon_scanner

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
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
            Log.d(TAG, "rangingServiceConnection.onServiceConnected: started")

            val binder = service as? RangingService.LocalBinder
            rangingService = binder?.getService()

            eventChannelRanging.setStreamHandler(rangingService?.streamHandler)
            isRangingServiceBound = true

            Log.d(TAG, "rangingServiceConnection.onServiceConnected: ended")
        }

        override fun onServiceDisconnected(className: ComponentName?) {
            Log.d(TAG, "rangingServiceConnection.onServiceDisconnected: started")

            rangingService = null
            isRangingServiceBound = false

            Log.d(TAG, "rangingServiceConnection.onServiceDisconnected: ended")
        }
    }
    private val monitoringServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName?, service: IBinder?) {
            Log.d(TAG, "monitoringServiceConnection.onServiceConnected: started")

            val binder = service as? MonitoringService.LocalBinder
            monitoringService = binder?.getService()

            eventChannelMonitoring.setStreamHandler(monitoringService?.streamHandler)
            isMonitoringServiceBound = true

            Log.d(TAG, "monitoringServiceConnection.onServiceConnected: ended")
        }

        override fun onServiceDisconnected(className: ComponentName?) {
            Log.d(TAG, "monitoringServiceConnection.onServiceDisconnected: started")

            monitoringService = null
            isMonitoringServiceBound = false

            Log.d(TAG, "monitoringServiceConnection.onServiceDisconnected: ended")
        }
    }

    private lateinit var beaconManager: BeaconManager
    private lateinit var channel: MethodChannel
    private lateinit var eventChannelRanging: EventChannel
    private lateinit var eventChannelMonitoring: EventChannel

    // region Initialization

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        Log.d(TAG, "onAttachedToEngine: started")

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

        val rangingIntent = Intent(binding.applicationContext, RangingService::class.java)
        flutterPluginBinding.applicationContext.bindService(rangingIntent, rangingServiceConnection, Context.BIND_AUTO_CREATE)

        val monitoringIntent = Intent(binding.applicationContext, MonitoringService::class.java)
        flutterPluginBinding.applicationContext.bindService(monitoringIntent, monitoringServiceConnection, Context.BIND_AUTO_CREATE)

        // setup the services
        setupServices(rangingIntent, monitoringIntent)
        // setupForegroundServices(rangingIntent, monitoringIntent)

        Log.d(TAG, "onAttachedToEngine: ended")
    }

    private fun setupServices(rangingIntent: Intent, monitoringIntent: Intent) {
        Log.d(TAG, "setupServices: started")

        rangingService?.startService(rangingIntent)
        monitoringService?.startService(monitoringIntent)

        Log.d(TAG, "setupServices: ended")
    }

    @Suppress("unused")
    private fun setupForegroundServices(rangingIntent: Intent, monitoringIntent: Intent) {
        Log.d(TAG, "setupForegroundServices: started")

        beaconManager.enableForegroundServiceScanning(createNotification(), 456)
        rangingService?.startForegroundService(rangingIntent)
        monitoringService?.startForegroundService(monitoringIntent)

        Log.d(TAG, "setupForegroundServices: ended")
    }

    private fun createNotification(): Notification {
        Log.d(TAG, "createNotification: started")

        val notificationTitle = "Beacon Service"
        val notificationContent = "Starting foreground services"
        val channelId = "beacon_service_notification_channel"
        val notificationManager = flutterPluginBinding.applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channel = NotificationChannel(channelId, "Beacon Service", NotificationManager.IMPORTANCE_DEFAULT)
        notificationManager.createNotificationChannel(channel)

        val notification = NotificationCompat.Builder(flutterPluginBinding.applicationContext, channelId)
            .setContentTitle(notificationTitle)
            .setContentText(notificationContent)
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        Log.d(TAG, "createNotification: ended")

        return notification
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        Log.d(TAG, "onDetachedFromEngine: started")

        channel.setMethodCallHandler(null)
        eventChannelRanging.setStreamHandler(null)
        eventChannelMonitoring.setStreamHandler(null)

        binding.applicationContext.unbindService(rangingServiceConnection)
        binding.applicationContext.unbindService(monitoringServiceConnection)

        beaconManager.removeAllRangeNotifiers()
        beaconManager.removeAllMonitorNotifiers()

        Log.d(TAG, "onDetachedFromEngine: ended")
    }

    // region Handle flutter method calls

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "onMethodCall: started")

        when (call.method) {
            METHOD_INITIALIZE -> initialize(result)
            METHOD_CLOSE -> close(result)
            METHOD_SET_SCAN_PERIOD -> setScanPeriod(call.argument<Long>("scanPeriod")!!, result)
            METHOD_SET_BETWEEN_SCAN_PERIOD -> setBetweenScanPeriod(call.argument<Long>("betweenScanPeriod")!!, result)
            else -> result.notImplemented()
        }

        Log.d(TAG, "onMethodCall: ended")
    }

    private fun initialize(result: Result) {
        Log.d(TAG, "initialize: started")

        var success = false

        if (isRangingServiceBound && isMonitoringServiceBound) {
            success = true
        }

        try {
            Utils.requestPermissions(activityPluginBinding)
        }
        catch (e: Exception) {
            success = false

            Log.e(TAG, "initialize: error: ${e.message}", e)
        }

        result.success(success)

        Log.d(TAG, "initialize: ended")
    }

    private fun close(result: Result) {
        Log.d(TAG, "close: started")

        var success = true

        try {
            rangingService?.stopRanging()
            beaconManager.removeAllRangeNotifiers()
            monitoringService?.stopMonitoring()
            beaconManager.removeAllMonitorNotifiers()
        }
        catch (e: Exception) {
            success = false

            Log.e(TAG, "close: error: ${e.message}", e)
        }

        result.success(success)

        Log.d(TAG, "close: ended")
    }

    private fun setScanPeriod(scanPeriod: Long, result: Result) {
        Log.d(TAG, "setScanPeriod: started")

        beaconManager.foregroundScanPeriod = scanPeriod
        beaconManager.backgroundScanPeriod = scanPeriod
        updateScanPeriods(beaconManager, result)

        Log.d(TAG, "setScanPeriod: ended")
    }

    private fun setBetweenScanPeriod(betweenScanPeriod: Long, result: Result) {
        Log.d(TAG, "setBetweenScanPeriod: started")

        beaconManager.foregroundBetweenScanPeriod = betweenScanPeriod
        beaconManager.backgroundBetweenScanPeriod = betweenScanPeriod
        updateScanPeriods(beaconManager, result)

        Log.d(TAG, "setBetweenScanPeriod: ended")
    }

    private fun updateScanPeriods(manager: BeaconManager, result: Result) {
        Log.d(TAG, "updateScanPeriods: started")

        var success = true

        try {
            manager.updateScanPeriods()
        }
        catch (e: Exception) {
            success = false

            Log.e(TAG, "updateScanPeriods: error: ${e.message}", e)
        }

        result.success(success)

        Log.d(TAG, "updateScanPeriods: ended")
    }

    // region Activity stuff

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "onAttachedToActivity: started")

        activityPluginBinding = binding

        Log.d(TAG, "onAttachedToActivity: ended")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "onDetachedFromActivityForConfigChanges: started")

        onDetachedFromActivity()

        Log.d(TAG, "onDetachedFromActivityForConfigChanges: ended")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(TAG, "onReattachedToActivityForConfigChanges: started")

        onAttachedToActivity(binding)

        Log.d(TAG, "onReattachedToActivityForConfigChanges: ended")
    }

    override fun onDetachedFromActivity() {
        Log.d(TAG, "onDetachedFromActivity: triggered")
    }
}
