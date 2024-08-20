import Foundation
import Flutter
import BeaconScannerPlugin

class BSMonitoringStreamHandler: NSObject, FlutterStreamHandler {
    private var instance: BeaconScannerPlugin?

    init(instance: BeaconScannerPlugin) {
        self.instance = instance
    }

    ///------------------------------------------------------------
    /// Flutter Stream Handler
    ///------------------------------------------------------------

    func onCancel(arguments: Any?) -> FlutterError? {
        if let instance = instance {
            instance.stopMonitoringBeacon()
        }
        return nil
    }

    func onListen(arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        if let instance = instance {
            instance.flutterEventSinkMonitoring = eventSink
            instance.startMonitoringBeacon(withCall: arguments)
        }
        return nil
    }
}
