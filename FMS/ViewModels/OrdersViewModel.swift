//
//  OrdersViewModel.swift
//  FMS
//
//  Created by user@50 on 16/03/26.
//


import Foundation
import Observation
import Supabase

public struct LiveDriverResource: Decodable, Identifiable {
    public let id: String
    public let name: String
}

public struct LiveVehicleResource: Decodable, Identifiable {
    public let id: String
    public let plateNumber: String
    public let manufacturer: String?
    public let model: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case plateNumber = "plate_number"
        case manufacturer
        case model
    }
}

@Observable
public final class OrdersViewModel {
    public var allOrders: [Order] = []
    
    // Live Resources for the Picker Sheets
    public var availableDrivers: [LiveDriverResource] = []
    public var availableVehicles: [LiveVehicleResource] = []
    
    public var isLoading: Bool = false
    public var isCreating: Bool = false
    public var errorMessage: String? = nil
    
    public var pendingOrders: [Order] { allOrders.filter { $0.isPending }.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) } }
    public var ongoingOrders: [Order] { allOrders.filter { $0.isOngoing }.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) } }
    public var completedOrders: [Order] { allOrders.filter { $0.isCompleted }.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) } }
    
    public init() {}
    
    @MainActor
    public func fetchAvailableResources() async {
        do {
            let drivers: [LiveDriverResource] = try await SupabaseService.shared.client
                .from("users")
                .select("id, name")
                .eq("role", value: "driver")
                .execute()
                .value
            self.availableDrivers = drivers
            
            let vehicles: [LiveVehicleResource] = try await SupabaseService.shared.client
                .from("vehicles")
                .select("id, plate_number, manufacturer, model")
                .eq("status", value: "active")
                .execute()
                .value
            self.availableVehicles = vehicles
        } catch {
            print("Failed to fetch live resources: \(error)")
        }
    }
    
    @MainActor
    public func fetchOrders() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: [Order] = try await SupabaseService.shared.client
                .from("orders")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            self.allOrders = response
        } catch {
            self.errorMessage = "Failed to load orders: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    @MainActor
    public func createOrder(payload: OrderCreatePayload, driverId: String? = nil, vehicleId: String? = nil) async -> Bool {
        isCreating = true
        errorMessage = nil
        do {
            // 1. Create the Order securely
            let createdOrder: Order = try await SupabaseService.shared.client
                .from("orders")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            
            // 2. If 'Assign Now' was used, immediately generate the Trip
            if let dId = driverId, let vId = vehicleId {
                try await assignTrip(orderId: createdOrder.id, driverId: dId, vehicleId: vId)
            }
            
            await fetchOrders()
            isCreating = false
            return true
        } catch {
            self.errorMessage = "Failed to create order: \(error.localizedDescription)"
            isCreating = false
            return false
        }
    }
    
    @MainActor
    public func assignTrip(orderId: String, driverId: String, vehicleId: String) async throws {
        // Creates a Trip linking the order, driver, and vehicle together!
        struct TripCreatePayload: Encodable {
            let order_id: String
            let driver_id: String
            let vehicle_id: String
            let status: String
        }
        
        let newTrip = TripCreatePayload(order_id: orderId, driver_id: driverId, vehicle_id: vehicleId, status: "scheduled")
        try await SupabaseService.shared.client.from("trips").insert(newTrip).execute()
        
        // Update the order status to confirmed
        struct OrderUpdate: Encodable { let status: String }
        try await SupabaseService.shared.client.from("orders").update(OrderUpdate(status: "confirmed")).eq("id", value: orderId).execute()
        
        await fetchOrders()
    }
}
