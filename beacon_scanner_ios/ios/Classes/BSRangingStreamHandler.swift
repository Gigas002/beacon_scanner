import Foundation
import Flutter
import BeaconScannerPlugin

class BSRangingStreamHandler: NSObject, FlutterStreamHandler {
    private var instance: BeaconScannerPlugin?

    init(instance: BeaconScannerPlugin) {
        self.instance = instance
        super.init()
    }

    // MARK: - Flutter Stream Handler

    func onCancel(arguments: Any?) -> FlutterError? {
        instance?.stopRangingBeacon()
        return nil
    }

    func onListen(arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        instance?.flutterEventSinkRanging = eventSink
        instance?.startRangingBeacon(withCall: arguments)
        return nil
    }
}
