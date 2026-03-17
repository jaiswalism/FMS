//
//  Order.swift
//  FMS
//
//  Created by user@50 on 16/03/26.
//

import Foundation

public struct Order: Codable, Identifiable {
    public var id: String
    public var orderNumber: String?
    public var customerName: String
    public var customerPhone: String?
    public var customerEmail: String?
    public var totalWeightKg: Double
    public var totalPackages: Int?
    public var cargoType: String?
    public var specialInstructions: String?
    public var originName: String?
    public var originLat: Double?
    public var originLng: Double?
    public var destinationName: String?
    public var destinationLat: Double?
    public var destinationLng: Double?
    public var requestedPickupAt: Date?
    public var requestedDeliveryAt: Date?
    public var status: String?
    public var priority: String?
    public var quotedPrice: Double?
    public var finalPrice: Double?
    public var createdBy: String?
    public var createdAt: Date?
    public var amountReceived: Double?
    public var paymentStatus: String?
    public var paymentMethod: String?
    public var invoiceNumber: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orderNumber = "order_number"
        case customerName = "customer_name"
        case customerPhone = "customer_phone"
        case customerEmail = "customer_email"
        case totalWeightKg = "total_weight_kg"
        case totalPackages = "total_packages"
        case cargoType = "cargo_type"
        case specialInstructions = "special_instructions"
        case originName = "origin_name"
        case originLat = "origin_lat"
        case originLng = "origin_lng"
        case destinationName = "destination_name"
        case destinationLat = "destination_lat"
        case destinationLng = "destination_lng"
        case requestedPickupAt = "requested_pickup_at"
        case requestedDeliveryAt = "requested_delivery_at"
        case status
        case priority
        case quotedPrice = "quoted_price"
        case finalPrice = "final_price"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case amountReceived = "amount_received"
        case paymentStatus = "payment_status"
        case paymentMethod = "payment_method"
        case invoiceNumber = "invoice_number"
    }

    public var statusLabel: String {
        switch status?.lowercased() {
        case "pending": return "Pending"
        case "confirmed": return "Confirmed"
        case "dispatched": return "Dispatched"
        case "in_transit": return "In Transit"
        case "delivered": return "Delivered"
        case "cancelled": return "Cancelled"
        default: return status?.capitalized ?? "Unknown"
        }
    }

    public var statusDisplay: String { statusLabel }

    public var isPending: Bool {
        let s = status?.lowercased()
        return s == "pending" || s == "confirmed"
    }

    public var isOngoing: Bool {
        let s = status?.lowercased()
        return s == "dispatched" || s == "in_transit"
    }

    public var isCompleted: Bool {
        let s = status?.lowercased()
        return s == "delivered" || s == "cancelled"
    }
}
