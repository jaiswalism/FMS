import Foundation
import CoreLocation
import Combine

@MainActor
public final class LocationManager: NSObject, ObservableObject {
    @Published public private(set) var currentLocation: CLLocation?
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus
    @Published public private(set) var lastError: Error?

    private let manager: CLLocationManager

    public override init() {
        self.manager = CLLocationManager()
        self.authorizationStatus = manager.authorizationStatus
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 10
        manager.pausesLocationUpdatesAutomatically = false
        manager.activityType = .automotiveNavigation
        // Background updates disabled by default to prevent crash without Xcode background capability
        // manager.allowsBackgroundLocationUpdates = true
    }

    public var isAuthorizedForTrip: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    public var isPermissionDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    public func requestAlwaysPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    public func startUpdating() {
        guard isAuthorizedForTrip else {
            print("[LocationManager] ⚠️ startUpdating called but not authorized (status=\(authorizationStatus.rawValue))")
            return
        }
        print("[LocationManager] ▶️ startUpdatingLocation")
        manager.startUpdatingLocation()
    }

    public func stopUpdating() {
        print("[LocationManager] ⏹️ stopUpdatingLocation")
        manager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("[LocationManager] 🔑 Authorization changed to: \(authorizationStatus.rawValue) (\(authorizationDescription))")

        if authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }

        if isAuthorizedForTrip {
            print("[LocationManager] ✅ Authorized — auto-starting location updates")
            manager.startUpdatingLocation()
        } else if isPermissionDenied {
            print("[LocationManager] ❌ Permission denied — stopping location updates")
            manager.stopUpdatingLocation()
        }
    }

    private var authorizationDescription: String {
        switch authorizationStatus {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedWhenInUse: return "whenInUse"
        case .authorizedAlways: return "always"
        @unknown default: return "unknown"
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        print("[LocationManager] 📍 Location update: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = error
    }
}
