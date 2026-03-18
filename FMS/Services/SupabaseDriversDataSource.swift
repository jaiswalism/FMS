import Foundation
import Supabase

/// Real implementation of DriversDataSource using Supabase.
public final class SupabaseDriversDataSource: DriversDataSource {
    
    private let client = SupabaseService.shared.client
    
    public init() {}
    
    // Custom decoder to handle Supabase date formats
    private var supabaseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let date = dateFormatter.date(from: dateStr) { return date }
            
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let date = dateFormatter.date(from: dateStr) { return date }
            
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateStr) { return date }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateStr)")
        }
        return decoder
    }
    
    public func fetchDrivers() async throws -> [DriverDisplayItem] {
        let decoder = supabaseDecoder
        
        // Fetch users with driver role
        let driversResponse = try await client
            .from("users")
            .select()
            .eq("role", value: "driver")
            .eq("is_deleted", value: false)
            .execute()
        let drivers = try decoder.decode([User].self, from: driversResponse.data)
        
        // Fetch all active assignments
        let nowISO = ISO8601DateFormatter().string(from: Date())
        let assignmentsResponse = try await client
            .from("driver_vehicle_assignments")
            .select()
            .eq("status", value: "scheduled")
            .gte("shift_end", value: nowISO)
            .execute()
        let assignments = try decoder.decode([DriverVehicleAssignment].self, from: assignmentsResponse.data)
            
        // Fetch all vehicles
        let vehiclesResponse = try await client
            .from("vehicles")
            .select()
            .execute()
        let vehicles = try decoder.decode([Vehicle].self, from: vehiclesResponse.data)
            
        // Fetch driver-side trip activity and derive status dynamically from it.
        let tripsResponse = try await client
            .from("trips")
            .select()
            .in("status", values: ["active", "in_transit"])
            .execute()
        let trips = try decoder.decode([Trip].self, from: tripsResponse.data)
            
        return drivers.map { driver in
            let assignment = assignments.first { $0.driverId == driver.id }
            let activeTrip = trips.first { $0.driverId == driver.id }
            let assignmentVehicle = vehicles.first { $0.id == assignment?.vehicleId }
            let tripVehicle = vehicles.first { $0.id == activeTrip?.vehicleId }
            
            // Determine availability status
            var availability: DriverAvailabilityStatus = .offDuty
            if activeTrip != nil {
                availability = .onTrip
            } else if assignment != nil {
                availability = .available
            }

            // Only expose assigned vehicle for on-trip drivers.
            let visibleVehicle: Vehicle? = {
                guard availability == .onTrip else { return nil }
                return tripVehicle ?? assignmentVehicle
            }()
            
            return DriverDisplayItem(
                id: driver.id,
                name: driver.name,
                employeeID: driver.employeeId ?? "#DRV-XXXX",
                phone: driver.phone,
                vehicleId: visibleVehicle?.id,
                vehicleManufacturer: visibleVehicle?.manufacturer,
                vehicleModel: visibleVehicle?.model,
                plateNumber: visibleVehicle?.plateNumber,
                availabilityStatus: availability,
                shiftStart: activeTrip?.startTime ?? assignment?.shiftStart,
                shiftEnd: assignment?.shiftEnd,
                activeTripId: activeTrip?.id
            )
        }
    }
}
