import Foundation
import CoreLocation
import Combine

public func isInsideGeofence(current: CLLocation, target: CLLocation, radius: Double) -> Bool {
    current.distance(from: target) <= radius
}

@MainActor
public final class TripExecutionViewModel: ObservableObject {
    public let geofenceRadius: Double = 1000

    @Published public private(set) var currentPhase: TripPhase = .pickup
    @Published public private(set) var startTime: Date?
    @Published public private(set) var endTime: Date?
    @Published public private(set) var hasStartedTrip = false
    @Published public private(set) var hasEndedTrip = false
    @Published public private(set) var isBreakActive = false
    @Published public private(set) var samplesReadyForSync: [TripLocationSample] = []

    @Published public private(set) var pickupDistanceMeters: Double?
    @Published public private(set) var destinationDistanceMeters: Double?
    @Published public private(set) var insidePickupGeofence = false
    @Published public private(set) var insideDestinationGeofence = false

    private let tripId: String
    private let pickupLocation: CLLocation
    private let destinationLocation: CLLocation

    private weak var locationManager: LocationManager?
    private var locationSubscription: AnyCancellable?
    private var samplingTimer: Timer?

    // Hysteresis counters to avoid rapid toggling on GPS drift.
    private var pickupInsideHits = 0
    private var pickupOutsideHits = 0
    private var destinationInsideHits = 0
    private var destinationOutsideHits = 0
    private let requiredStableHits = 2

    public init(
        tripId: String,
        pickupCoordinate: CLLocationCoordinate2D,
        destinationCoordinate: CLLocationCoordinate2D
    ) {
        self.tripId = tripId
        self.pickupLocation = CLLocation(latitude: pickupCoordinate.latitude, longitude: pickupCoordinate.longitude)
        self.destinationLocation = CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)
    }

    public func attachLocationManager(_ manager: LocationManager) {
        locationManager = manager
        print("[TripExecution] Attached LocationManager for trip \(tripId)")
        locationSubscription = manager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.consume(location: location)
            }
    }

    public var hasLocationPermission: Bool {
        locationManager?.isAuthorizedForTrip == true
    }

    public var canStartTrip: Bool {
        hasLocationPermission && !hasStartedTrip && insidePickupGeofence
    }

    public var canEndTrip: Bool {
        hasLocationPermission && hasStartedTrip && !hasEndedTrip && insideDestinationGeofence
    }

    public func requestPermissionsAndTracking() {
        locationManager?.requestAlwaysPermission()
        locationManager?.startUpdating()
    }

    public func configureInitialState(status: String?, startTime: Date?, endTime: Date?) {
        let normalized = status?.lowercased()
        if normalized == "active" {
            hasStartedTrip = true
            hasEndedTrip = false
            currentPhase = isBreakActive ? .inBreak : .inTransit
            self.startTime = startTime ?? self.startTime
            beginSamplingIfNeeded()
            print("[TripExecution] Configured as active trip \(tripId)")
            return
        }

        if normalized == "completed" || normalized == "delivered" {
            hasStartedTrip = true
            hasEndedTrip = true
            currentPhase = .delivery
            self.startTime = startTime ?? self.startTime
            self.endTime = endTime ?? self.endTime
            stopTracking()
        }
    }

    public func stopTracking() {
        samplingTimer?.invalidate()
        samplingTimer = nil
        locationManager?.stopUpdating()
        print("[TripExecution] Stopped location tracking for trip \(tripId)")
    }

    public func startTrip() {
        guard canStartTrip else {
            print("[TripExecution] Cannot start trip \(tripId) — canStartTrip=false (perm=\(hasLocationPermission), started=\(hasStartedTrip), inGeofence=\(insidePickupGeofence))")
            return
        }
        hasStartedTrip = true
        currentPhase = .inTransit
        startTime = Date()
        isBreakActive = false
        beginSamplingIfNeeded()
        print("[TripExecution] Trip \(tripId) started")
    }

    public func endTrip() {
        guard canEndTrip else { return }
        hasEndedTrip = true
        currentPhase = .delivery
        endTime = Date()
        isBreakActive = false
        captureImmediateSample()
        print("[TripExecution] Trip \(tripId) ended")
        stopTracking()
    }

    public func takeBreak() {
        guard hasStartedTrip, !hasEndedTrip, !isBreakActive else { return }
        isBreakActive = true
        currentPhase = .inBreak
    }

    public func resumeTrip() {
        guard hasStartedTrip, !hasEndedTrip, isBreakActive else { return }
        isBreakActive = false
        currentPhase = .inTransit
    }

    private func beginSamplingIfNeeded() {
        guard samplingTimer == nil else { return }

        samplingTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.captureImmediateSample()
            }
        }
        RunLoop.main.add(samplingTimer!, forMode: .common)
        captureImmediateSample()
    }

    private func captureImmediateSample() {
        guard hasStartedTrip, !hasEndedTrip, let location = locationManager?.currentLocation else { return }
        let sample = TripLocationSample(
            tripId: tripId,
            phase: currentPhase,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: Date()
        )
        samplesReadyForSync.append(sample)
    }

    private func consume(location: CLLocation) {
        let pickupDistance = location.distance(from: pickupLocation)
        let destinationDistance = location.distance(from: destinationLocation)

        pickupDistanceMeters = pickupDistance
        destinationDistanceMeters = destinationDistance

        updateSmoothedGeofence(
            distance: pickupDistance,
            insideCount: &pickupInsideHits,
            outsideCount: &pickupOutsideHits,
            output: &insidePickupGeofence
        )

        updateSmoothedGeofence(
            distance: destinationDistance,
            insideCount: &destinationInsideHits,
            outsideCount: &destinationOutsideHits,
            output: &insideDestinationGeofence
        )
    }

    private func updateSmoothedGeofence(
        distance: Double,
        insideCount: inout Int,
        outsideCount: inout Int,
        output: inout Bool
    ) {
        let hysteresis: Double = 35

        if distance <= geofenceRadius {
            insideCount += 1
            outsideCount = 0
        } else if distance > geofenceRadius + hysteresis {
            outsideCount += 1
            insideCount = 0
        }

        if insideCount >= requiredStableHits {
            output = true
        }

        if outsideCount >= requiredStableHits {
            output = false
        }
    }
}
