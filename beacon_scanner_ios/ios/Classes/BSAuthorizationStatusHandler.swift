import CoreBluetooth
import Flutter
import Foundation

class BSAuthorizationStatusHandler: NSObject, FlutterStreamHandler {
    var instance: BeaconScannerPlugin?

    init(beaconScannerPlugin instance: BeaconScannerPlugin?) {
        super.init()
        self.instance = instance
    }

    ///------------------------------------------------------------
    // MARK: - Flutter Stream Handler
    ///------------------------------------------------------------

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if instance {
            instance.flutterEventSinkAuthorization = nil
        }
        return nil
    }

    func onListen(withArguments arguments: Any?, eventSink events: FlutterEventSink) -> FlutterError? {
        // initialize central manager if it itsn't
        instance.initializeLocationManager()

        if instance {
            instance.flutterEventSinkAuthorization = events
        }

        return nil
    }
}