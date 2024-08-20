import Foundation
import Flutter
import CoreBluetooth

class BSAuthorizationStatusHandler: NSObject, FlutterStreamHandler {
    var instance: BeaconScannerPlugin

    init(beaconScannerPlugin instance: BeaconScannerPlugin) {
        self.instance = instance
        super.init()
    }

    // MARK: - FlutterStreamHandler Methods

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        instance.flutterEventSinkAuthorization = nil
        return nil
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // Initialize location manager if it isn't already initialized
        instance.initializeLocationManager()

        instance.flutterEventSinkAuthorization = events

        return nil
    }
}
