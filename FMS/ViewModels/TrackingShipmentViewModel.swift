//
//  TrackingShipmentViewModel.swift
//  FMS
//
//  Created by Anish on 12/03/26.
//

import Foundation
import Observation
import CoreLocation

@Observable
public class TrackingShipmentViewModel {
    // Your actual database models
    public var trip: Trip?
    public var driver: Driver?
    public var vehicle: Vehicle?
    public var latestGPSLog: TripGPSLog?
    
    public var isLoading = false
    
    // Extracted properties for the Map
    public var currentCoordinate: CLLocationCoordinate2D? {
        guard let lat = latestGPSLog?.lat, let lng = latestGPSLog?.lng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    public var destinationCoordinate: CLLocationCoordinate2D? {
        guard let lat = trip?.endLat, let lng = trip?.endLng else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    // Formatting helpers for the UI
    public var formattedEstimatedDate: String {
        guard let durationMin = trip?.estimatedDurationMinutes,
              let startTime = trip?.startTime else { return "Calculating..." }
        
        let estimatedEnd = startTime.addingTimeInterval(TimeInterval(durationMin * 60))
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: estimatedEnd)
    }
    
    // Initializer for live data
    public init(trip: Trip? = nil, vehicle: Vehicle? = nil, driver: Driver? = nil, latestGPSLog: TripGPSLog? = nil) {
        self.trip = trip
        self.vehicle = vehicle
        self.driver = driver
        self.latestGPSLog = latestGPSLog
        
        // If no GPS log provided, use trip's start coordinates as a fallback for the map
        if latestGPSLog == nil {
            if let lat = trip?.startLat, let lng = trip?.startLng {
                self.latestGPSLog = TripGPSLog(id: "fallback", tripId: trip?.id ?? "", lat: lat, lng: lng, speed: 0, recordedAt: Date())
            }
        }
    }
}
