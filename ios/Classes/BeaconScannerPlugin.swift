import Flutter
import CoreBluetooth
import CoreLocation

@objc public class BeaconScannerPlugin: NSObject, FlutterPlugin {
    static let METHOD_CHANNEL = "beacon_scanner"
    static let METHOD_INITIALIZE = "initialize"
    static let METHOD_CLOSE = "close"
    static let METHOD_SET_SCAN_PERIOD = "setScanPeriod"
    static let METHOD_SET_BETWEEN_SCAN_PERIOD = "setBetweenScanPeriod"
    
    var rangingService = RangingService()
    var monitoringService = MonitoringService()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        Utils.log("BeaconScannerPlugin", "register", "started")

        let channel = FlutterMethodChannel(name: METHOD_CHANNEL, binaryMessenger: registrar.messenger())
        let beaconScanner = BeaconScannerPlugin()
        registrar.addMethodCallDelegate(beaconScanner, channel: channel)
        
        let streamChannelRanging = FlutterEventChannel(name: RangingService.EVENT_CHANNEL, binaryMessenger: registrar.messenger())
        streamChannelRanging.setStreamHandler(beaconScanner.rangingService)
        
        let streamChannelMonitoring = FlutterEventChannel(name: MonitoringService.EVENT_CHANNEL, binaryMessenger: registrar.messenger())
        streamChannelMonitoring.setStreamHandler(beaconScanner.monitoringService)

        Utils.log("BeaconScannerPlugin", "register", "ended")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Utils.log("BeaconScannerPlugin", "handle", "started")

        switch call.method {
            case BeaconScannerPlugin.METHOD_INITIALIZE:
                result(true)
            case BeaconScannerPlugin.METHOD_SET_SCAN_PERIOD, BeaconScannerPlugin.METHOD_SET_BETWEEN_SCAN_PERIOD:
                result(true)
            case BeaconScannerPlugin.METHOD_CLOSE:
                close(with: result)
            default:
                result(FlutterMethodNotImplemented)
        }
        
        Utils.log("BeaconScannerPlugin", "handle", "ended")
    }
    
    func close(with result: @escaping FlutterResult) {
        Utils.log("BeaconScannerPlugin", "close", "started")

        rangingService.stopRanging()
        monitoringService.stopMonitoring()
        
        result(true)
        
        Utils.log("BeaconScannerPlugin", "close", "ended")
    }
}
