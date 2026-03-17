//
//  OrderCreatePayload.swift
//  FMS

import Foundation

public struct OrderCreatePayload: Encodable {
    public let customerName: String
    public let customerPhone: String?
    public let customerEmail: String?
    public let totalWeightKg: Double
    public let totalPackages: Int?
    public let cargoType: String
    public let priority: String
    public let originName: String
    public let originLat: Double?
    public let originLng: Double?
    public let destinationName: String
    public let destinationLat: Double?
    public let destinationLng: Double?
    public let waypoints: [Waypoint]?
    public let requestedPickupAt: Date?
    public let requestedDeliveryAt: Date?
    public let specialInstructions: String?

    enum CodingKeys: String, CodingKey {
        case customerName        = "customer_name"
        case customerPhone       = "customer_phone"
        case customerEmail       = "customer_email"
        case totalWeightKg       = "total_weight_kg"
        case totalPackages       = "total_packages"
        case cargoType           = "cargo_type"
        case priority
        case originName          = "origin_name"
        case originLat           = "origin_lat"
        case originLng           = "origin_lng"
        case destinationName     = "destination_name"
        case destinationLat      = "destination_lat"
        case destinationLng      = "destination_lng"
        case waypoints
        case requestedPickupAt   = "requested_pickup_at"
        case requestedDeliveryAt = "requested_delivery_at"
        case specialInstructions = "special_instructions"
    }
}
