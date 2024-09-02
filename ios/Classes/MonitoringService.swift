import Foundation
import CoreLocation
import Flutter

class MonitoringService: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
    static let EVENT_CHANNEL = "beacon_scanner_event_monitoring"
    
    var locationManager = CLLocationManager()
    var regions: [CLBeaconRegion] = []
    var eventSink: FlutterEventSink?
    
    override init() {
        Utils.log("MonitoringService", "init", "started")

        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        Utils.log("MonitoringService", "init", "ended")
    }
    
    func startMonitoring(with arguments: Any?) {
        Utils.log("MonitoringService", "startMonitoring", "started")
        
        regions = (arguments as? [[String: Any]])?
            .compactMap(Utils.region(from:)) ?? []
        
        regions.forEach { region in
            Utils.log("MonitoringService", "startMonitoring", "monitoring region: \(region)")
            locationManager.startMonitoring(for: region)
        }
        
        Utils.log("MonitoringService", "startMonitoring", "ended")
    }
    
    func stopMonitoring() {
        Utils.log("MonitoringService", "stopMonitoring", "started")

        for case let region in regions {
            locationManager.stopMonitoring(for: region)
        }
        
        eventSink = nil
    
        Utils.log("MonitoringService", "stopMonitoring", "ended")
    }
    
    // MARK: - LocationManager
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Utils.log("MonitoringService", "locationManager didEnterRegion", "started")

        guard let eventSink = self.eventSink,
              let reg = regions.first(where: { $0.identifier == region.identifier })
        else {
            return
        }
        
        eventSink([
            "event": "didEnterRegion",
            "region": Utils.dictionary(from: reg),
        ])
        
        Utils.log("MonitoringService", "locationManager didEnterRegion", "ended")
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Utils.log("MonitoringService", "locationManager didExitRegion", "started")

        guard let eventSink = self.eventSink,
              let reg = regions.first(where: { $0.identifier == region.identifier })
        else {
            return
        }
        
        eventSink([
            "event": "didExitRegion",
            "region": Utils.dictionary(from: reg),
        ])
        
        Utils.log("MonitoringService", "locationManager didExitRegion", "ended")
    }
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        Utils.log("MonitoringService", "locationManager didDetermineState", "started")

        guard let eventSink = self.eventSink,
              let reg = regions.first(where: { $0.identifier == region.identifier })
        else {
            return
        }

        let stateString: String
        switch state {
            case .inside: stateString = "inside"
            case .outside: stateString = "outside"
            default: stateString = "unknown"
        }
        
        eventSink([
            "event": "didDetermineStateForRegion",
            "region": Utils.dictionary(from: reg),
            "state": stateString
        ])
        
        Utils.log("MonitoringService", "locationManager didDetermineState", "ended")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Utils.log("MonitoringService", "locationManager error", "Error: \(error.localizedDescription)")
    }

    // MARK: - FlutterStreamHandler Methods
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        Utils.log("MonitoringService", "onCancel", "triggered")

        stopMonitoring()
        
        return nil
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        Utils.log("MonitoringService", "onListen", "triggered")

        eventSink = events
        startMonitoring(with: arguments)

        return nil
    }
}
