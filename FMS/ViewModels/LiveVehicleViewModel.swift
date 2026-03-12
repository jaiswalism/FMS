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
                let plate = vehicle.plateNumber.lowercased()
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
            
            self.vehicles = [
                Vehicle(
                    id: UUID().uuidString,
                    plateNumber: "KA 09 MA 1234",
                    chassisNumber: "CH1234",
                    manufacturer: "Volvo",
                    model: "FH16",
                    fuelType: "Diesel",
                    fuelTankCapacity: 400.0,
                    carryingCapacity: 35000.0,
                    purchaseDateString: nil,
                    odometer: 12540.0,
                    status: "active",
                    createdBy: "admin",
                    createdAt: Date()
                ),
                
                Vehicle(
                    id: UUID().uuidString,
                    plateNumber: "KA 09 MA 5678",
                    chassisNumber: "CH5678",
                    manufacturer: "Tata",
                    model: "Prima",
                    fuelType: "Diesel",
                    fuelTankCapacity: 350.0,
                    carryingCapacity: 30000.0,
                    purchaseDateString: nil,
                    odometer: 25000.0,
                    status: "active",
                    createdBy: "admin",
                    createdAt: Date()
                ),
                
                Vehicle(
                    id: UUID().uuidString,
                    plateNumber: "KA 09 MA 9012",
                    chassisNumber: "CH9012",
                    manufacturer: "Ashok Leyland",
                    model: "Boss",
                    fuelType: "Electric",
                    fuelTankCapacity: 0.0,
                    carryingCapacity: 28000.0,
                    purchaseDateString: nil,
                    odometer: 3200.0,
                    status: "inactive",
                    createdBy: "admin",
                    createdAt: Date()
                ),
                
                Vehicle(
                    id: UUID().uuidString,
                    plateNumber: "KA 09 MA 3344",
                    chassisNumber: "CH3344",
                    manufacturer: "Eicher",
                    model: "Pro",
                    fuelType: "Diesel",
                    fuelTankCapacity: 350.0,
                    carryingCapacity: 32000.0,
                    purchaseDateString: nil,
                    odometer: 8400.0,
                    status: "maintenance",
                    createdBy: "admin",
                    createdAt: Date()
                )
            ]
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error fetching vehicles: \(error)")
        }
    }
}
