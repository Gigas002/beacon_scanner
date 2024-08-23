import Foundation
import Flutter

class BSRangingStreamHandler: NSObject, FlutterStreamHandler {
    static let EVENT_CHANNEL = "beacon_scanner_event_ranging"

    var instance: BeaconScannerPlugin

    init(beaconScannerPlugin instance: BeaconScannerPlugin) {
        self.instance = instance
        super.init()
    }

    // MARK: - FlutterStreamHandler Methods

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        instance.stopRangingBeacon()
        return nil
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        instance.flutterEventSinkRanging = events
        instance.startRangingBeacon(with: arguments)
        return nil
    }
}
