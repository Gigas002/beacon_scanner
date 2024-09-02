import Foundation
import CoreLocation

class Utils : NSObject {
    static func dictionary(from beacon: CLBeacon) -> [String: Any] {
        log("Utils", "dictionary from beacon", "triggered")
        
        let proximityMapping: [CLProximity: String] = [
            .unknown: "unknown",
            .immediate: "immediate",
            .near: "near",
            .far: "far"
        ]
                
        return [
            "proximityUUID": beacon.uuid.uuidString,
            "major": beacon.major,
            "minor": beacon.minor,
            "rssi": NSNumber(value: beacon.rssi),
            "accuracy": NSNumber(value: beacon.accuracy),
            "proximity": proximityMapping[beacon.proximity] ?? "unknown"
        ]
    }
    
    static func dictionary(from region: CLBeaconRegion) -> [String: Any] {
        log("Utils", "dictionary from region", "triggered")

        return [
            "identifier": region.identifier,
            "proximityUUID": region.uuid.uuidString,
            "major": region.major ?? NSNull(),
            "minor": region.minor ?? NSNull()
        ]
    }
    
    static func region(from dict: [String: Any]) -> CLBeaconRegion? {
        log("Utils", "region", "triggered")

        guard
            let identifier = dict["identifier"] as? String,
            let proximityUUIDString = dict["proximityUUID"] as? String,
            let proximityUUID = UUID(uuidString: proximityUUIDString)
        else {
            return nil
        }
        
        let major = (dict["major"] as? NSNumber)?.uint16Value
        let minor = (dict["minor"] as? NSNumber)?.uint16Value
        
        return major != nil && minor != nil
            ? CLBeaconRegion(uuid: proximityUUID, major: major!, minor: minor!, identifier: identifier)
            : major != nil
            ? CLBeaconRegion(uuid: proximityUUID, major: major!, identifier: identifier)
            : CLBeaconRegion(uuid: proximityUUID, identifier: identifier)
    }
    
    static func log(_ className: String, _ methodName: String, _ message: String) {
        #if DEBUG
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .long)
        print("DEBUG: \(timestamp): \(className): \(methodName): \(message)")
        #endif
    }
}
