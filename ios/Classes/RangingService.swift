import Foundation
import CoreLocation
import Flutter

class RangingService: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
    static let EVENT_CHANNEL = "beacon_scanner_event_ranging"
    
    var locationManager = CLLocationManager()
    var regions: [CLBeaconRegion] = []
    var eventSink: FlutterEventSink?
    
    override init() {
        Utils.log("RangingService", "init", "started")

        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        Utils.log("RangingService", "init", "ended")
    }
    
    func startRanging(with arguments: Any?) {
        Utils.log("RangingService", "startRanging", "started")
        
        regions = (arguments as? [[String: Any]])?
            .compactMap(Utils.region(from:)) ?? []
        
        regions.forEach { region in
            Utils.log("RangingService", "startRanging", "ranging region: \(region)")
            locationManager.startRangingBeacons(satisfying: region.beaconIdentityConstraint)
        }
        
        Utils.log("RangingService", "startRanging", "ended")
    }
    
    func stopRanging() {
        Utils.log("RangingService", "stopRanging", "started")

        for case let region in regions {
            locationManager.stopRangingBeacons(satisfying: region.beaconIdentityConstraint)
        }

        eventSink = nil

        Utils.log("RangingService", "stopRanging", "ended")
    }
    
    // MARK: - LocationManager
    
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        Utils.log("RangingService", "locationManager didRangeBeacons", "started")
        
        guard let eventSink = self.eventSink else { return }
                
        eventSink([
            "region": Utils.dictionary(from: region),
            "beacons": beacons.map(Utils.dictionary(from:))
        ])
        
        Utils.log("RangingService", "locationManager didRangeBeacons", "ended")
    }

    
    // MARK: - FlutterStreamHandler Methods
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        Utils.log("RangingService", "onCancel", "triggered")

        stopRanging()

        return nil
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        Utils.log("RangingService", "onListen", "triggered")

        eventSink = events
        startRanging(with: arguments)
        
        return nil
    }
}
