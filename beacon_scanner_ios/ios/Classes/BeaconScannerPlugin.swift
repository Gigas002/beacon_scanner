import Flutter
import CoreBluetooth
import CoreLocation

class BeaconScannerPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralManagerDelegate {
    var flutterEventSinkRanging: FlutterEventSink?
    var flutterEventSinkMonitoring: FlutterEventSink?
    var flutterEventSinkBluetooth: FlutterEventSink?
    var flutterEventSinkAuthorization: FlutterEventSink?

    var defaultLocationAuthorizationType: CLAuthorizationStatus = .authorizedAlways
    var shouldStartAdvertise = false

    var locationManager: CLLocationManager?
    var bluetoothManager: CBCentralManager?
    var peripheralManager: CBPeripheralManager?
    var regionRanging: [Any] = []
    var regionMonitoring: [Any] = []
    var beaconPeripheralData: [String: Any]?

    var rangingHandler: BSRangingStreamHandler?
    var monitoringHandler: BSMonitoringStreamHandler?
    var bluetoothHandler: BSBluetoothStateHandler?
    var authorizationHandler: BSAuthorizationStatusHandler?

    var flutterResult: FlutterResult?
    var flutterBluetoothResult: FlutterResult?
    var flutterBroadcastResult: FlutterResult?

    // Registration of the plugin
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "plugins.lukangagames.com/beacon_scanner_android", binaryMessenger: registrar.messenger())
        let instance = BeaconScannerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        instance.rangingHandler = BSRangingStreamHandler(beaconScannerPlugin: instance)
        let streamChannelRanging = FlutterEventChannel(name: "beacon_scanner_event_ranging", binaryMessenger: registrar.messenger())
        streamChannelRanging.setStreamHandler(instance.rangingHandler)

        instance.monitoringHandler = BSMonitoringStreamHandler(beaconScannerPlugin: instance)
        let streamChannelMonitoring = FlutterEventChannel(name: "beacon_scanner_event_monitoring", binaryMessenger: registrar.messenger())
        streamChannelMonitoring.setStreamHandler(instance.monitoringHandler)

        instance.bluetoothHandler = BSBluetoothStateHandler(beaconScannerPlugin: instance)
        let streamChannelBluetooth = FlutterEventChannel(name: "beacon_scanner_bluetooth_state_changed", binaryMessenger: registrar.messenger())
        streamChannelBluetooth.setStreamHandler(instance.bluetoothHandler)

        instance.authorizationHandler = BSAuthorizationStatusHandler(beaconScannerPlugin: instance)
        let streamChannelAuthorization = FlutterEventChannel(name: "beacon_scanner_authorization_status_changed", binaryMessenger: registrar.messenger())
        streamChannelAuthorization.setStreamHandler(instance.authorizationHandler)
    }

    override init() {
        super.init()
        // Set the default location authorization type
        self.defaultLocationAuthorizationType = .authorizedAlways
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "initialize":
                initializeLocationManager()
                initializeCentralManager()
                result(true)

            case "initializeAndCheckScanning":
                initializeWithResult(result)

            case "setLocationAuthorizationTypeDefault":
                if let argumentAsString = call.arguments as? String {
                    if argumentAsString == "ALWAYS" {
                        self.defaultLocationAuthorizationType = .authorizedAlways
                        result(true)
                    } else if argumentAsString == "WHEN_IN_USE" {
                        self.defaultLocationAuthorizationType = .authorizedWhenInUse
                        result(true)
                    } else {
                        result(false)
                    }
                } else {
                    result(false)
                }

            case "authorizationStatus":
                initializeLocationManager()
                let status: String
                switch CLLocationManager.authorizationStatus() {
                case .notDetermined:
                    status = "NOT_DETERMINED"
                case .restricted:
                    status = "RESTRICTED"
                case .denied:
                    status = "DENIED"
                case .authorizedAlways:
                    status = "ALWAYS"
                case .authorizedWhenInUse:
                    status = "WHEN_IN_USE"
                @unknown default:
                    status = "UNKNOWN"
                }
                result(status)

            case "checkLocationServicesIfEnabled":
                result(CLLocationManager.locationServicesEnabled())

            case "bluetoothState":
                self.flutterBluetoothResult = result
                initializeCentralManager()

                // Delay 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if let bluetoothResult = self.flutterBluetoothResult {
                        let state: String
                        switch self.bluetoothManager?.state {
                        case .unknown:
                            state = "STATE_UNKNOWN"
                        case .resetting:
                            state = "STATE_RESETTING"
                        case .unsupported:
                            state = "STATE_UNSUPPORTED"
                        case .unauthorized:
                            state = "STATE_UNAUTHORIZED"
                        case .poweredOff:
                            state = "STATE_OFF"
                        case .poweredOn:
                            state = "STATE_ON"
                        case .none:
                            state = "STATE_UNKNOWN"
                        @unknown default:
                            state = "STATE_UNKNOWN"
                        }
                        bluetoothResult(state)
                        self.flutterBluetoothResult = nil
                    }
                }

            case "requestAuthorization":
                if let locationManager = self.locationManager {
                    self.flutterResult = result
                    requestDefaultLocationManagerAuthorization()
                } else {
                    result(true)
                }

            case "openBluetoothSettings":
                // Do nothing (private API usage comment retained)
                result(true)

            case "openLocationSettings":
                // Do nothing (private API usage comment retained)
                result(true)

            case "setScanPeriod", "setBetweenScanPeriod":
                // Do nothing
                result(true)

            case "openApplicationSettings":
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                result(true)

            case "close":
                stopRangingBeacon()
                stopMonitoringBeacon()
                result(true)

            case "startBroadcast":
                self.flutterBroadcastResult = result
                startBroadcast(call.arguments)

            case "stopBroadcast":
                if let peripheralManager = self.peripheralManager {
                    peripheralManager.stopAdvertising()
                }
                result(nil)

            case "isBroadcasting":
                if let peripheralManager = self.peripheralManager {
                    result(peripheralManager.isAdvertising)
                } else {
                    result(false)
                }

            case "isBroadcastSupported":
                result(true)

            default:
                result(FlutterMethodNotImplemented)
        }
    }

    func initializeCentralManager() {
        if bluetoothManager == nil {
            // Initialize central manager if it isn't already initialized
            bluetoothManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        }
    }

    func initializeLocationManager() {
        if locationManager == nil {
            // Initialize location manager if it isn't already initialized
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        }
    }

    func startBroadcast(_ arguments: Any?) {
        guard let dict = arguments as? [String: Any] else { return }
        var measuredPower: NSNumber? = nil
        
        if let txPower = dict["txPower"] as? NSNumber {
            measuredPower = txPower
        }
        
        if let region = BSUtils.region(fromDictionary: dict) {
            self.shouldStartAdvertise = true
            self.beaconPeripheralData = region.peripheralData(withMeasuredPower: measuredPower) as? [String: Any]
            self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        }
    }

    // MARK: - Flutter Beacon Ranging

    func startRangingBeacon(with arguments: Any?) {
        if let regionRanging = self.regionRanging {
            regionRanging.removeAllObjects()
        } else {
            self.regionRanging = NSMutableArray()
        }

        guard let array = arguments as? [[String: Any]] else { return }

        for dict in array {
            if let region = BSUtils.region(fromDictionary: dict) {
                self.regionRanging?.add(region)
            }
        }

        for case let region as CLBeaconRegion in self.regionRanging ?? [] {
            print("START: \(region)")
            locationManager?.startRangingBeacons(satisfying: region.beaconIdentityConstraint)
        }
    }

    func stopRangingBeacon() {
        for case let region as CLBeaconRegion in self.regionRanging ?? [] {
            locationManager?.stopRangingBeacons(satisfying: region.beaconIdentityConstraint)
        }
        self.flutterEventSinkRanging = nil
    }

    // MARK: - Flutter Beacon Monitoring

    func startMonitoringBeacon(with arguments: Any?) {
        if let regionMonitoring = self.regionMonitoring {
            regionMonitoring.removeAllObjects()
        } else {
            self.regionMonitoring = NSMutableArray()
        }

        guard let array = arguments as? [[String: Any]] else { return }

        for dict in array {
            if let region = BSUtils.region(fromDictionary: dict) {
                self.regionMonitoring?.add(region)
            }
        }

        for case let region as CLBeaconRegion in self.regionMonitoring ?? [] {
            print("START: \(region)")
            locationManager?.startMonitoring(for: region)
        }
    }

    func stopMonitoringBeacon() {
        for case let region as CLBeaconRegion in self.regionMonitoring ?? [] {
            locationManager?.stopMonitoring(for: region)
        }
        self.flutterEventSinkMonitoring = nil
    }

    // MARK: - Flutter Beacon Initialize

    func initialize(with result: @escaping FlutterResult) {
        self.flutterResult = result

        initializeLocationManager()
        initializeCentralManager()
    }

    // MARK: - Bluetooth Manager

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var message: String? = nil

        switch central.state {
        case .unknown:
            if let flutterBluetoothResult = self.flutterBluetoothResult {
                flutterBluetoothResult("STATE_UNKNOWN")
                self.flutterBluetoothResult = nil
                return
            }
            message = "CBManagerStateUnknown"
            self.flutterEventSinkBluetooth?("STATE_UNKNOWN")

        case .resetting:
            if let flutterBluetoothResult = self.flutterBluetoothResult {
                flutterBluetoothResult("STATE_RESETTING")
                self.flutterBluetoothResult = nil
                return
            }
            message = "CBManagerStateResetting"
            self.flutterEventSinkBluetooth?("STATE_RESETTING")

        case .unsupported:
            if let flutterBluetoothResult = self.flutterBluetoothResult {
                flutterBluetoothResult("STATE_UNSUPPORTED")
                self.flutterBluetoothResult = nil
                return
            }
            message = "CBManagerStateUnsupported"
            self.flutterEventSinkBluetooth?("STATE_UNSUPPORTED")

        case .unauthorized:
            if let flutterBluetoothResult = self.flutterBluetoothResult {
                flutterBluetoothResult("STATE_UNAUTHORIZED")
                self.flutterBluetoothResult = nil
                return
            }
            message = "CBManagerStateUnauthorized"
            self.flutterEventSinkBluetooth?("STATE_UNAUTHORIZED")

        case .poweredOff:
            if let flutterBluetoothResult = self.flutterBluetoothResult {
                flutterBluetoothResult("STATE_OFF")
                self.flutterBluetoothResult = nil
                return
            }
            message = "CBManagerStatePoweredOff"
            self.flutterEventSinkBluetooth?("STATE_OFF")

        case .poweredOn:
            if let flutterBluetoothResult = self.flutterBluetoothResult {
                flutterBluetoothResult("STATE_ON")
                self.flutterBluetoothResult = nil
                return
            }
            self.flutterEventSinkBluetooth?("STATE_ON")

            if CLLocationManager.locationServicesEnabled() {
                switch CLLocationManager.authorizationStatus() {
                case .notDetermined:
                    requestDefaultLocationManagerAuthorization()
                    return
                case .denied:
                    message = "CLAuthorizationStatusDenied"
                case .restricted:
                    message = "CLAuthorizationStatusRestricted"
                default:
                    // manage scanning
                    break
                }
            } else {
                message = "LocationServicesDisabled"
            }

        @unknown default:
            break
        }

        if let flutterResult = self.flutterResult {
            if let message = message {
                flutterResult(FlutterError(code: "Beacon", message: message, details: nil))
            } else {
                flutterResult(nil)
            }
        }
    }

    // MARK: - Location Manager

    func requestDefaultLocationManagerAuthorization() {
        switch self.defaultLocationAuthorizationType {
            case .authorizedWhenInUse:
                self.locationManager.requestWhenInUseAuthorization()
            case .authorizedAlways:
                fallthrough
            default:
                self.locationManager.requestAlwaysAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var message: String? = nil
        switch status {
            case .authorizedAlways:
                self.flutterEventSinkAuthorization?("ALWAYS")
                // manage scanning
            case .authorizedWhenInUse:
                self.flutterEventSinkAuthorization?("WHEN_IN_USE")
                // manage scanning
            case .denied:
                self.flutterEventSinkAuthorization?("DENIED")
                message = "CLAuthorizationStatusDenied"
            case .restricted:
                self.flutterEventSinkAuthorization?("RESTRICTED")
                message = "CLAuthorizationStatusRestricted"
            case .notDetermined:
                self.flutterEventSinkAuthorization?("NOT_DETERMINED")
                message = "CLAuthorizationStatusNotDetermined"
            @unknown default:
                break
        }

        if let flutterResult = self.flutterResult {
            if let message = message {
                flutterResult(FlutterError(code: "Beacon", message: message, details: nil))
            } else {
                flutterResult(nil)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
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

    // MARK: - Location Manager

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let flutterEventSinkMonitoring = self.flutterEventSinkMonitoring else { return }

        if let reg = self.regionMonitoring.first(where: { $0.identifier == region.identifier }) {
            let dictRegion = BSUtils.dictionary(from: reg)
            flutterEventSinkMonitoring([
                "event": "didEnterRegion",
                "region": dictRegion
            ])
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let flutterEventSinkMonitoring = self.flutterEventSinkMonitoring else { return }

        if let reg = self.regionMonitoring.first(where: { $0.identifier == region.identifier }) {
            let dictRegion = BSUtils.dictionary(from: reg)
            flutterEventSinkMonitoring([
                "event": "didExitRegion",
                "region": dictRegion
            ])
        }
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
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

    // MARK: - Peripheral Manager

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
            case .poweredOn:
                if self.shouldStartAdvertise {
                    peripheral.startAdvertising(self.beaconPeripheralData)
                    self.shouldStartAdvertise = false
                }
            default:
                break
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard let flutterBroadcastResult = self.flutterBroadcastResult else { return }

        if let error = error {
            flutterBroadcastResult(FlutterError(code: "Broadcast", message: error.localizedDescription, details: error))
        } else {
            flutterBroadcastResult(peripheral.isAdvertising as NSNumber)
        }
        self.flutterBroadcastResult = nil
    }
}
