import Foundation
import Observation
import Supabase

@Observable
@MainActor
public final class FuelCostReportViewModel {

    public struct Row: Identifiable {
        public let id: String
        public let plateNumber: String
        public let litersConsumed: Double
        public let costPerLiter: Double
        public let totalSpend: Double
        public let budgetAllocated: Double

        public var variance: Double { totalSpend - budgetAllocated }
    }

    public enum VehicleGroup: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case maintenance = "Maintenance"
        case inactive = "Inactive"

        public var id: String { rawValue }
    }

    private struct VehicleRow: Decodable {
        let id: String
        let plateNumber: String
        let status: String?

        enum CodingKeys: String, CodingKey {
            case id
            case plateNumber = "plate_number"
            case status
        }
    }

    private struct TripFuelRow: Decodable {
        let vehicleId: String?
        let fuelUsedLiters: Double?
        let startTime: Date?

        enum CodingKeys: String, CodingKey {
            case vehicleId = "vehicle_id"
            case fuelUsedLiters = "fuel_used_liters"
            case startTime = "start_time"
        }
    }

    private struct FuelPriceRow: Decodable {
        let amountPaid: Double?
        let fuelVolume: Double?

        enum CodingKeys: String, CodingKey {
            case amountPaid = "amount_paid"
            case fuelVolume = "fuel_volume"
        }
    }

    public var rows: [Row] = []
    public var isLoading = false
    public var errorMessage: String?

    public var startDate: Date
    public var endDate: Date
    public var selectedGroup: VehicleGroup = .all

    public init() {
        let now = Date()
        let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
        self.startDate = monthStart
        self.endDate = now
    }

    public var filteredRows: [Row] {
        rows.sorted { $0.totalSpend > $1.totalSpend }
    }

    public var totals: Row {
        let liters = filteredRows.reduce(0) { $0 + $1.litersConsumed }
        let spend = filteredRows.reduce(0) { $0 + $1.totalSpend }
        let budget = filteredRows.reduce(0) { $0 + $1.budgetAllocated }
        let costPerLiter = liters > 0 ? spend / liters : 0
        return Row(
            id: "totals",
            plateNumber: "Totals",
            litersConsumed: liters,
            costPerLiter: costPerLiter,
            totalSpend: spend,
            budgetAllocated: budget
        )
    }

    public func fetchReport() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let iso = ISO8601DateFormatter()
            let from = iso.string(from: startDate)
            let to = iso.string(from: endDate)

            var vehiclesQuery = SupabaseService.shared.client
                .from("vehicles")
                .select("id, plate_number, status")

            if selectedGroup != .all {
                vehiclesQuery = vehiclesQuery.eq("status", value: selectedGroup.rawValue.lowercased())
            }

            let vehicles: [VehicleRow] = try await vehiclesQuery.execute().value

            let trips: [TripFuelRow] = try await SupabaseService.shared.client
                .from("trips")
                .select("vehicle_id, fuel_used_liters, start_time")
                .gte("start_time", value: from)
                .lte("start_time", value: to)
                .execute().value

            let fuelRows: [FuelPriceRow] = try await SupabaseService.shared.client
                .from("fuel_logs")
                .select("amount_paid, fuel_volume")
                .gte("logged_at", value: from)
                .lte("logged_at", value: to)
                .execute().value

            let totalPaid = fuelRows.compactMap(\.amountPaid).reduce(0, +)
            let totalVolume = fuelRows.compactMap(\.fuelVolume).reduce(0, +)
            let avgCostPerLiter = totalVolume > 0 ? totalPaid / totalVolume : 0

            var litersByVehicle: [String: Double] = [:]
            for row in trips {
                guard let vehicleId = row.vehicleId else { continue }
                litersByVehicle[vehicleId, default: 0] += row.fuelUsedLiters ?? 0
            }

            // Budget approximation based on 90-day historical spend trend.
            let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: endDate) ?? startDate
            let historicalFrom = iso.string(from: ninetyDaysAgo)
            let historicalTrips: [TripFuelRow] = try await SupabaseService.shared.client
                .from("trips")
                .select("vehicle_id, fuel_used_liters, start_time")
                .gte("start_time", value: historicalFrom)
                .lte("start_time", value: to)
                .execute().value

            var historicalLitersByVehicle: [String: Double] = [:]
            for row in historicalTrips {
                guard let vehicleId = row.vehicleId else { continue }
                historicalLitersByVehicle[vehicleId, default: 0] += row.fuelUsedLiters ?? 0
            }

            rows = vehicles.map { vehicle in
                let liters = litersByVehicle[vehicle.id, default: 0]
                let spend = liters * avgCostPerLiter
                let historicalSpend = historicalLitersByVehicle[vehicle.id, default: 0] * avgCostPerLiter
                let monthlyHistorical = historicalSpend / 3.0
                let budget = max(0, monthlyHistorical * 1.10)

                return Row(
                    id: vehicle.id,
                    plateNumber: vehicle.plateNumber,
                    litersConsumed: liters,
                    costPerLiter: avgCostPerLiter,
                    totalSpend: spend,
                    budgetAllocated: budget
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
