import Foundation
import CoreLocation

class BSUtils : NSObject {
    
    static func dictionaryFromCLBeacon(_ beacon: CLBeacon) -> [String: Any] {
        var proximity: String
        switch beacon.proximity {
        case .unknown:
            proximity = "unknown"
        case .immediate:
            proximity = "immediate"
        case .near:
            proximity = "near"
        case .far:
            proximity = "far"
        @unknown default:
            proximity = "unknown"
        }
        
        let rssi = NSNumber(value: beacon.rssi)
        let accuracy = NSNumber(value: beacon.accuracy)
        return [
            "proximityUUID": beacon.uuid.uuidString,
            "major": beacon.major,
            "minor": beacon.minor,
            "rssi": rssi,
            "accuracy": accuracy,
            "proximity": proximity
        ]
    }
    
    static func dictionaryFromCLBeaconRegion(_ region: CLBeaconRegion) -> [String: Any] {
        let major: Any = region.major ?? NSNull()
        let minor: Any = region.minor ?? NSNull()
        
        return [
            "identifier": region.identifier,
            "proximityUUID": region.uuid.uuidString,
            "major": major,
            "minor": minor
        ]
    }
    
    static func regionFromDictionary(_ dict: [String: Any]) -> CLBeaconRegion? {
        guard let identifier = dict["identifier"] as? String,
              let proximityUUIDString = dict["proximityUUID"] as? String,
              let proximityUUID = UUID(uuidString: proximityUUIDString) else {
            return nil
        }
        
        let major = dict["major"] as? NSNumber
        let minor = dict["minor"] as? NSNumber
        
        if let major = major, let minor = minor {
            return CLBeaconRegion(uuid: proximityUUID, major: major.intValue, minor: minor.intValue, identifier: identifier)
        } else if let major = major {
            return CLBeaconRegion(uuid: proximityUUID, major: major.intValue, identifier: identifier)
        } else {
            return CLBeaconRegion(uuid: proximityUUID, identifier: identifier)
        }
    }
}
