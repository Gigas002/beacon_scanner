import Flutter
import CoreBluetooth
import CoreLocation

@objc public class BeaconScannerPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    static let METHOD_CHANNEL = "beacon_scanner"
    static let METHOD_INITIALIZE = "initialize"
    static let METHOD_CLOSE = "close"
    static let METHOD_SET_SCAN_PERIOD = "setScanPeriod"
    static let METHOD_SET_BETWEEN_SCAN_PERIOD = "setBetweenScanPeriod"
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    var flutterEventSinkRanging: FlutterEventSink?
    var flutterEventSinkMonitoring: FlutterEventSink?
    var regionRanging: [CLBeaconRegion] = []
    var regionMonitoring: [CLBeaconRegion] = []
    var rangingHandler: BSRangingStreamHandler?
    var monitoringHandler: BSMonitoringStreamHandler?

    // Registration of the plugin
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: METHOD_CHANNEL, binaryMessenger: registrar.messenger())
        let instance = BeaconScannerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        instance.rangingHandler = BSRangingStreamHandler(beaconScannerPlugin: instance)
        let streamChannelRanging = FlutterEventChannel(name: BSRangingStreamHandler.EVENT_CHANNEL, binaryMessenger: registrar.messenger())
        streamChannelRanging.setStreamHandler(instance.rangingHandler)

        instance.monitoringHandler = BSMonitoringStreamHandler(beaconScannerPlugin: instance)
        let streamChannelMonitoring = FlutterEventChannel(name: BSMonitoringStreamHandler.EVENT_CHANNEL, binaryMessenger: registrar.messenger())
        streamChannelMonitoring.setStreamHandler(instance.monitoringHandler)
    }

    override init() {
        super.init()
        locationManager.delegate = self
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case BeaconScannerPlugin.METHOD_INITIALIZE:
                initialize(with: result)
            case BeaconScannerPlugin.METHOD_SET_SCAN_PERIOD, BeaconScannerPlugin.METHOD_SET_BETWEEN_SCAN_PERIOD:
                result(true)
            case BeaconScannerPlugin.METHOD_CLOSE:
                close(with: result)
            default:
                result(FlutterMethodNotImplemented)
        }
    }
    
    func initialize(with result: @escaping FlutterResult) {
        locationManager.requestAlwaysAuthorization()
        
        result(true)
    }
    
    func close(with result: @escaping FlutterResult) {
        stopRangingBeacon()
        stopMonitoringBeacon()
        
        result(true)
    }

   // MARK: - Flutter Beacon Ranging

    func startRangingBeacon(with arguments: Any?) {
        regionRanging.removeAll()

        guard let array = arguments as? [[String: Any]] else { return }

        for dict in array {
            if let region = BSUtils.region(from: dict) {
                self.regionRanging.append(region)
            }
        }

        for case let region in self.regionRanging {
            print("START: \(region)")
            locationManager.startRangingBeacons(satisfying: region.beaconIdentityConstraint)
        }
    }

    func stopRangingBeacon() {
        for case let region in self.regionRanging {
            locationManager.stopRangingBeacons(satisfying: region.beaconIdentityConstraint)
        }
        self.flutterEventSinkRanging = nil
    }

    // MARK: - Flutter Beacon Monitoring

    func startMonitoringBeacon(with arguments: Any?) {
        regionMonitoring.removeAll()

        guard let array = arguments as? [[String: Any]] else { return }

        for dict in array {
            if let region = BSUtils.region(from: dict) {
                self.regionMonitoring.append(region)
            }
        }

        for case let region in self.regionMonitoring {
            print("START: \(region)")
            locationManager.startMonitoring(for: region)
        }
    }

    func stopMonitoringBeacon() {
        for case let region in self.regionMonitoring {
            locationManager.stopMonitoring(for: region)
        }
        self.flutterEventSinkMonitoring = nil
    }

    // MARK: - Location Manager

    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if let flutterEventSinkRanging = self.flutterEventSinkRanging {
            let dictRegion = BSUtils.dictionary(from: region)

            var array: [[String: Any]] = []
            for beacon in beacons {
                let dictBeacon = BSUtils.dictionary(from: beacon)
                array.append(dictBeacon)
            }

            flutterEventSinkRanging([
                "region": dictRegion,
                "beacons": array
            ])
        }
    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let flutterEventSinkMonitoring = self.flutterEventSinkMonitoring else { return }

        if let reg = self.regionMonitoring.first(where: { $0.identifier == region.identifier }) {
            let dictRegion = BSUtils.dictionary(from: reg)
            flutterEventSinkMonitoring([
                "event": "didEnterRegion",
                "region": dictRegion
            ])
        }
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let flutterEventSinkMonitoring = self.flutterEventSinkMonitoring else { return }

        if let reg = self.regionMonitoring.first(where: { $0.identifier == region.identifier }) {
            let dictRegion = BSUtils.dictionary(from: reg)
            flutterEventSinkMonitoring([
                "event": "didExitRegion",
                "region": dictRegion
            ])
        }
    }

    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let flutterEventSinkMonitoring = self.flutterEventSinkMonitoring else { return }

        if let reg = self.regionMonitoring.first(where: { $0.identifier == region.identifier }) {
            let dictRegion = BSUtils.dictionary(from: reg)
            let stt: String
            switch state {
                case .inside:
                    stt = "INSIDE"
                case .outside:
                    stt = "OUTSIDE"
                default:
                    stt = "UNKNOWN"
            }
            flutterEventSinkMonitoring([
                "event": "didDetermineStateForRegion",
                "region": dictRegion,
                "state": stt
            ])
        }
    }
}
