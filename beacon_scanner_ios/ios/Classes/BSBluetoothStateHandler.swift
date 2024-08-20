import Foundation
import Flutter
import CoreBluetooth

class BSBluetoothStateHandler: NSObject, FlutterStreamHandler {
    var instance: BeaconScannerPlugin

    init(beaconScannerPlugin instance: BeaconScannerPlugin) {
        self.instance = instance
        super.init()
    }

    // MARK: - FlutterStreamHandler Methods

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        instance.flutterEventSinkBluetooth = nil
        return nil
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // Initialize central manager if it isn't already initialized
        instance.initializeCentralManager()

        instance.flutterEventSinkBluetooth = events

        return nil
    }
}
