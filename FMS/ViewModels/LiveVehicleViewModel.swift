//
//  LiveVehicleViewModel.swift
//  FMS
//
//  Created by Anish on 11/03/26.
//

import Foundation
import SwiftUI
import Observation
import Supabase

@Observable
final class LiveVehicleViewModel {
    struct ActiveTripInfo: Identifiable {
        let id: String
        let trip: Trip
        let vehicle: Vehicle
        
        var completionPercentage: Int {
            // Placeholder: Could be based on distance covered if available
            return 45 
        }
    }
    
    var activeTrips: [ActiveTripInfo] = []
    var vehicles: [Vehicle] = []
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    // Computed property to handle search
    var filteredTrips: [ActiveTripInfo] {
        if searchText.isEmpty {
            return activeTrips
        } else {
            let search = searchText.lowercased()
            return activeTrips.filter { info in
                let plate = info.vehicle.plateNumber.lowercased()
                let make = info.vehicle.manufacturer?.lowercased() ?? ""
                let model = info.vehicle.model?.lowercased() ?? ""
                let origin = info.trip.startName?.lowercased() ?? ""
                let dest = info.trip.endName?.lowercased() ?? ""
                return plate.contains(search) || make.contains(search) || model.contains(search) || origin.contains(search) || dest.contains(search)
            }
        }
    }
    
    @MainActor
    func fetchVehicles() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch active trips and join with vehicles
            // Supabase select with join: .select("*, vehicles(*)")
            let response = try await SupabaseService.shared.client
                .from("trips")
                .select("*, vehicles(*)")
                .eq("status", value: "active")
                .execute()
            
            // Define a temporary struct for decoding the joined response
            struct JoinedTrip: Decodable {
                let trip: Trip
                let vehicles: Vehicle // Supabase returns the singular object for a 1-to-1 join if configured correctly, or an array if not.
                
                enum CodingKeys: String, CodingKey {
                    case vehicles
                }
                
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.trip = try Trip(from: decoder)
                    // Handling both single object and array return from Supabase join
                    if let vehicleObj = try? container.decode(Vehicle.self, forKey: .vehicles) {
                        self.vehicles = vehicleObj
                    } else {
                        let vehicleArr = try container.decode([Vehicle].self, forKey: .vehicles)
                        guard let first = vehicleArr.first else {
                            throw DecodingError.dataCorruptedError(forKey: .vehicles, in: container, debugDescription: "No vehicle found in join")
                        }
                        self.vehicles = first
                    }
                }
            }
            
            let joinedResults = try JSONDecoder.supabase().decode([JoinedTrip].self, from: response.data)
            
            self.activeTrips = joinedResults.map { 
                ActiveTripInfo(id: $0.trip.id, trip: $0.trip, vehicle: $0.vehicles)
            }
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            print("🚨 LiveVehicleViewModel Error: \(error)")
        }
    }
}
