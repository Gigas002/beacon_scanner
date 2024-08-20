import Foundation
import Flutter

class BSMonitoringStreamHandler: NSObject, FlutterStreamHandler {
    var instance: BeaconScannerPlugin

    init(beaconScannerPlugin instance: BeaconScannerPlugin) {
        self.instance = instance
        super.init()
    }

    // MARK: - FlutterStreamHandler Methods

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        instance.stopMonitoringBeacon()
        return nil
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        instance.flutterEventSinkMonitoring = events
        instance.startMonitoringBeacon(withCall: arguments)
        return nil
    }
}
