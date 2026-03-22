import Foundation
import CoreLocation
import Observation
import Supabase

// MARK: - Break Type

public enum BreakType: String, CaseIterable, Identifiable, Codable {
    case rest  = "rest"
    case meal  = "meal"
    case fuel  = "fuel"
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .rest:  return "Rest"
        case .meal:  return "Meal"
        case .fuel:  return "Fuel Stop"
        case .other: return "Other"
        }
    }

    public var icon: String {
        switch self {
        case .rest:  return "bed.double.fill"
        case .meal:  return "fork.knife"
        case .fuel:  return "fuelpump.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

@MainActor
@Observable
public final class BreakLogViewModel: NSObject, CLLocationManagerDelegate {

    // MARK: - State

    public var isOnBreak: Bool = false
    public var selectedBreakType: BreakType = .rest
    public var notes: String = ""
    public var currentBreakStartTime: Date?
    public var currentBreakElapsedSeconds: TimeInterval = 0
    public var breakLogs: [BreakLog] = []
    public var showMinDurationWarning: Bool = false
    public var errorMessage: String? = nil

    // MARK: - Private

    private let driverId: String
    private let tripId: String
    private let vehicleId: String
    private var timer: Timer?
    private var locationManager: CLLocationManager?
    private var startLocation: CLLocation?
    private var currentLocation: CLLocation?

    private let minimumBreakSeconds: TimeInterval = 5 * 60

    // MARK: - Init

    public init(driverId: String, tripId: String, vehicleId: String) {
        self.driverId = driverId
        self.tripId = tripId
        self.vehicleId = vehicleId
        super.init()
        setupLocationManager()
    }

    // Default init for compatibility with standard declarations where values are not yet known
    public override init() {
        self.driverId = ""
        self.tripId = ""
        self.vehicleId = ""
        super.init()
        setupLocationManager()
    }

    // MARK: - Formatted

    public var formattedElapsed: String {
        let total = Int(currentBreakElapsedSeconds)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Public API

    public func startBreak(driverId: String? = nil, tripId: String? = nil, lat: Double? = nil, lng: Double? = nil) {
        guard !isOnBreak else { return }
        isOnBreak = true
        currentBreakStartTime = Date()
        currentBreakElapsedSeconds = 0
        showMinDurationWarning = false
        locationManager?.requestLocation()
        startLocation = currentLocation ?? locationManager?.location

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.currentBreakStartTime else { return }
                self.currentBreakElapsedSeconds = Date().timeIntervalSince(start)
            }
        }
    }

    public func endBreak(lat: Double? = nil, lng: Double? = nil) {
        guard isOnBreak, let startTime = currentBreakStartTime else { return }
        timer?.invalidate()
        timer = nil
        isOnBreak = false

        locationManager?.requestLocation()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let durationMinutes = Int(duration / 60)
        let endLocation = currentLocation ?? locationManager?.location

        if duration < minimumBreakSeconds {
            showMinDurationWarning = true
        }

        let log = BreakLog(
            id: UUID().uuidString,
            tripId: self.tripId.isEmpty ? nil : self.tripId,
            driverId: self.driverId.isEmpty ? nil : self.driverId,
            breakType: selectedBreakType.rawValue,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: max(1, durationMinutes),
            lat: startLocation?.coordinate.latitude,
            lng: startLocation?.coordinate.longitude,
            endLat: endLocation?.coordinate.latitude,
            endLng: endLocation?.coordinate.longitude,
            notes: notes.isEmpty ? nil : notes
        )

        breakLogs.insert(log, at: 0)
        currentBreakStartTime = nil
        currentBreakElapsedSeconds = 0
        notes = ""

        Task {
            await saveBreakLog(log)
        }
    }

    // MARK: - Fetch History

    public func fetchBreakHistory() {
        Task {
            do {
                guard !tripId.isEmpty else { return }
                let response = try await SupabaseService.shared.client
                    .from("break_logs")
                    .select()
                    .eq("trip_id", value: tripId)
                    .order("start_time", ascending: false)
                    .limit(50)
                    .execute()

                let fetched = try JSONDecoder.supabase().decode([BreakLog].self, from: response.data)

                // Merge: keep locally-logged breaks, add any from DB not already present
                let localIds = Set(breakLogs.map(\.id))
                let newFromDB = fetched.filter { !localIds.contains($0.id) }
                breakLogs = (breakLogs + newFromDB).sorted {
                    ($0.startTime ?? .distantPast) > ($1.startTime ?? .distantPast)
                }
            } catch {
                print("⚠️ [BreakLogViewModel] Failed to load breaks (silent fallback): \(error)")
                self.errorMessage = "Failed to fetch break history: \(error.localizedDescription)"
            }
        }
    }
    
    /// Loads breaks by driver across trips (Crash Recovery endpoint)
    public func loadBreaks(driverId: String) async {
        do {
            let response = try await SupabaseService.shared.client
                .from("break_logs")
                .select()
                .eq("driver_id", value: driverId)
                .order("start_time", ascending: false)
                .limit(50)
                .execute()

            let breaks = try JSONDecoder.supabase().decode([BreakLog].self, from: response.data)
            self.breakLogs = breaks.filter { !$0.isOngoing }
            
            if let openBreak = breaks.first(where: { $0.isOngoing }) {
                self.isOnBreak = true
                self.currentBreakStartTime = openBreak.startTime
                self.selectedBreakType = BreakType(rawValue: openBreak.breakType ?? "rest") ?? .rest
                
                // Resume elapsed counting via standard start dispatch
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard let self, let start = self.currentBreakStartTime else { return }
                        self.currentBreakElapsedSeconds = Date().timeIntervalSince(start)
                    }
                }
            }
        } catch {
            print("⚠️ [BreakLogViewModel] Failed to load driver breaks: \(error)")
            self.errorMessage = "Failed to load breaks: \(error.localizedDescription)"
        }
    }

    // MARK: - Persistence

    private func saveBreakLog(_ log: BreakLog) async {
        let insert = BreakLogInsert(
            id: log.id,
            tripId: log.tripId,
            driverId: log.driverId,
            breakType: log.breakType,
            startTime: log.startTime,
            endTime: log.endTime,
            durationMinutes: log.durationMinutes,
            lat: log.lat,
            lng: log.lng,
            endLat: log.endLat,
            endLng: log.endLng,
            notes: log.notes
        )

        _ = await OfflineQueueService.shared.insertOrQueue(
            table: "break_logs",
            payload: insert,
            payloadType: .breakLog
        )
    }

    // MARK: - Location

    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
    }

    /// Stop location updates and clean up resources.
    public func stopLocationUpdates() {
        locationManager?.stopUpdatingLocation()
        locationManager?.delegate = nil
        locationManager = nil
    }

    // CLLocationManagerDelegate
    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Best-effort location — break log will use nil coordinates
    }
}
