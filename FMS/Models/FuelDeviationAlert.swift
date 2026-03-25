import Foundation

public enum FuelDeviationAlertStatus: String, Codable, CaseIterable {
    case active
    case acknowledged
    case resolved
}

public struct FuelDeviationAlert: Identifiable, Codable {
    public let id: String
    public let vehicleId: String
    public let vehicleLabel: String
    public let currentRate: Double
    public let baselineRate: Double
    public let deviationPercent: Double
    public let timestamp: Date
    public var status: FuelDeviationAlertStatus

    public init(
        id: String,
        vehicleId: String,
        vehicleLabel: String,
        currentRate: Double,
        baselineRate: Double,
        deviationPercent: Double,
        timestamp: Date,
        status: FuelDeviationAlertStatus = .active
    ) {
        self.id = id
        self.vehicleId = vehicleId
        self.vehicleLabel = vehicleLabel
        self.currentRate = currentRate
        self.baselineRate = baselineRate
        self.deviationPercent = deviationPercent
        self.timestamp = timestamp
        self.status = status
    }
}
