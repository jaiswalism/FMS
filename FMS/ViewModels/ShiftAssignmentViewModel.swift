import Foundation
import Observation

// MARK: - ShiftAssignmentViewModel

/// ViewModel for the shift assignment screen.
/// Manages form state for assigning a shift to a driver.
@Observable
public final class ShiftAssignmentViewModel {

    // MARK: - Form State
    public var selectedDriverId: String = ""
    public var selectedVehicleId: String = ""
    public var shiftDate: Date = Date()
    public var shiftStartTime: Date = Date()
    public var shiftEndTime: Date = Date().addingTimeInterval(8 * 3600)

    // MARK: - Data (mock lists — replace with service calls)
    public var availableDrivers: [(id: String, name: String)] = [
        ("drv-8821", "Alex Thompson"),
        ("drv-9104", "Sarah Jenkins"),
        ("drv-7229", "Marcus Rodriguez"),
        ("drv-8829", "Marcus Thompson")
    ]

    public var availableVehicles: [(id: String, display: String)] = [
        ("v-001", "Freightliner M2 · FLD-829"),
        ("v-002", "Volvo VNL 860 · XYZ-9876"),
        ("v-003", "Kenworth T680 · KLC-4421"),
        ("v-004", "Volvo FH16 · TN11N3067")
    ]

    // MARK: - Validation

    public var isFormValid: Bool {
        !selectedDriverId.isEmpty && !selectedVehicleId.isEmpty
            && shiftEndTime > shiftStartTime
    }

    // MARK: - Actions

    public func assignShift() {
        // TODO: Submit to service/repository
    }
}
