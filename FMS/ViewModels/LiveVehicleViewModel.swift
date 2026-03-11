//
//  LiveVehicleViewModel.swift
//  FMS
//
//  Created by Anish on 11/03/26.
//

import Foundation
import SwiftUI
import Observation

@Observable
final class LiveVehicleViewModel {
    var vehicles: [Vehicle] = []
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    private let supabaseService = SupabaseService.shared
    
    // Computed property to handle search and strictly filter for "live" statuses
    var filteredVehicles: [Vehicle] {
        let liveVehicles = vehicles.filter { $0.status?.lowercased() != "maintenance" }
        
        if searchText.isEmpty {
            return liveVehicles
        } else {
            let search = searchText.lowercased()
            return liveVehicles.filter { vehicle in
                let plate = vehicle.plateNumber?.lowercased() ?? ""
                let make = vehicle.manufacturer?.lowercased() ?? ""
                let model = vehicle.model?.lowercased() ?? ""
                return plate.contains(search) || make.contains(search) || model.contains(search)
            }
        }
    }
    
    func fetchVehicles() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Mock data strictly matching your standard
            self.vehicles = [
                Vehicle(id: UUID().uuidString, plateNumber: "KA 09 MA 1234", manufacturer: "Volvo", model: "FH16", status: "active"),
                Vehicle(id: UUID().uuidString, plateNumber: "KA 09 MA 5678", manufacturer: "Tata", model: "Prima", status: "active"),
                Vehicle(id: UUID().uuidString, plateNumber: "KA 09 MA 9012", manufacturer: "Ashok Leyland", model: "Boss", status: "inactive"),
                Vehicle(id: UUID().uuidString, plateNumber: "KA 09 MA 3344", manufacturer: "Eicher", model: "Pro", status: "maintenance") // This will be filtered out automatically
            ]
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error fetching vehicles: \(error)")
        }
    }
}
