//
//  OrderDetailView.swift
//  FMS
//
//  Created by Anish on 17/03/26.
//

import Foundation
import SwiftUI
import MapKit

public struct OrderDetailView: View {
    public let order: Order
    
    @State private var routeSegments: [MKRoute] = []
    @State private var isMapExpanded: Bool = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    // Alphabet array for easy A, B, C markers
    private let markerLabels = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
    
    public init(order: Order) {
        self.order = order
    }
    
    // Helper to get all coordinates in order (Origin -> Waypoints -> Destination)
    private var allCoordinates: [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        if let oLat = order.originLat, let oLng = order.originLng {
            coords.append(CLLocationCoordinate2D(latitude: oLat, longitude: oLng))
        }
        if let waypoints = order.waypoints {
            coords.append(contentsOf: waypoints.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) })
        }
        if let dLat = order.destinationLat, let dLng = order.destinationLng {
            coords.append(CLLocationCoordinate2D(latitude: dLat, longitude: dLng))
        }
        return coords
    }
    
    // MARK: - Computed Estimates
    private var totalDistanceKm: Double {
        let totalMeters = routeSegments.reduce(0) { $0 + $1.distance }
        return totalMeters / 1000.0
    }
    
    private var totalTravelTime: String {
        let totalSeconds = routeSegments.reduce(0) { $0 + $1.expectedTravelTime }
        if totalSeconds == 0 { return "--" }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: totalSeconds) ?? "--"
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // MARK: - Map Preview (Tappable)
                if allCoordinates.count >= 2 {
                    Button(action: { isMapExpanded = true }) {
                        mapContent
                            .frame(height: 220)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                            .overlay(
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(8)
                                            .background(Color.white.opacity(0.9))
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.15), radius: 4)
                                            .padding(24)
                                    }
                                }
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                
                // MARK: - Estimated Time & Distance
                HStack(spacing: 16) {
                    // Distance Block
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up.fill")
                                .font(.system(size: 12))
                                .foregroundColor(FMSTheme.amber)
                            Text("Est. Distance")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(FMSTheme.textSecondary)
                        }
                        
                        if routeSegments.isEmpty {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text(String(format: "%.1f km", totalDistanceKm))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(FMSTheme.textPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(FMSTheme.cardBackground)
                    .cornerRadius(16)
                    
                    // Time Block
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(FMSTheme.amber)
                            Text("Est. Duration")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(FMSTheme.textSecondary)
                        }
                        
                        if routeSegments.isEmpty {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text(totalTravelTime)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(FMSTheme.textPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(FMSTheme.cardBackground)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 16)
                
                // MARK: - Route Details
                VStack(spacing: 0) {
                    HStack {
                        Text("Route Timeline")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(FMSTheme.textPrimary)
                        Spacer()
                    }
                    .padding(16)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Origin (A)
                        routeStopRow(label: "A", color: .blue, title: "Pickup Location", address: order.originName)
                        
                        // Waypoints (B, C, etc.)
                        if let waypoints = order.waypoints {
                            ForEach(Array(waypoints.enumerated()), id: \.offset) { index, waypoint in
                                routeStopRow(
                                    label: markerLabels[min(index + 1, markerLabels.count - 1)],
                                    color: FMSTheme.amber,
                                    title: "Stop \(index + 1)",
                                    address: waypoint.name
                                )
                            }
                        }
                        
                        // Destination (Last letter)
                        routeStopRow(
                            label: markerLabels[min((order.waypoints?.count ?? 0) + 1, markerLabels.count - 1)],
                            color: .green,
                            title: "Delivery Location",
                            address: order.destinationName
                        )
                    }
                    .padding(16)
                }
                .background(FMSTheme.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                // MARK: - Assignment Details
                VStack(spacing: 0) {
                    HStack {
                        Text("Assignment Details")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(FMSTheme.textPrimary)
                        Spacer()
                        
                        // Status Badge
                        if order.isPending {
                            Text("Unassigned")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(FMSTheme.alertOrange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(FMSTheme.alertOrange.opacity(0.15))
                                .clipShape(Capsule())
                        } else {
                            Text("Assigned")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(16)
                    
                    Divider()
                    
                    if order.isPending {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(FMSTheme.alertOrange)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Action Required")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(FMSTheme.textPrimary)
                                Text("This order requires a driver and a vehicle to be dispatched.")
                                    .font(.system(size: 13))
                                    .foregroundColor(FMSTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(16)
                    } else {
                        // Future Placeholder: When driver/vehicle info is passed, it goes here
                        detailRow(title: "Driver", value: "Assigned Driver Name", icon: "steeringwheel")
                        Divider().padding(.leading, 48)
                        detailRow(title: "Vehicle", value: "Vehicle Plate", icon: "truck.box.fill")
                    }
                }
                .background(FMSTheme.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                // MARK: - Customer & Cargo Info
                VStack(spacing: 0) {
                    detailRow(title: "Customer", value: order.customerName, icon: "person.fill")
                    Divider().padding(.leading, 48)
                    if let phone = order.customerPhone {
                        detailRow(title: "Phone", value: phone, icon: "phone.fill")
                        Divider().padding(.leading, 48)
                    }
                    detailRow(title: "Cargo Type", value: order.cargoType?.capitalized ?? "General", icon: "shippingbox.fill")
                    Divider().padding(.leading, 48)
                    detailRow(title: "Total Weight", value: "\(String(format: "%.0f", order.totalWeightKg)) kg", icon: "scalemass.fill")
                }
                .background(FMSTheme.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                // MARK: - Assignment Action Button
                if order.isPending {
                    Button(action: {
                        // TODO: Phase 2 - Open Driver/Vehicle Assignment Sheet
                        print("Trigger Assignment Flow for Order: \(order.id)")
                    }) {
                        Text("Assign Trip to Driver")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(FMSTheme.backgroundPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(FMSTheme.amber)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .padding(.vertical, 20)
        }
        .background(FMSTheme.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(order.orderNumber ?? "Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await fetchRoutes()
        }
        // MARK: - Fullscreen Map Modal
        .sheet(isPresented: $isMapExpanded) {
            NavigationStack {
                mapContent
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle("Route Overview")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { isMapExpanded = false }
                        }
                    }
            }
        }
    }
    
    // Shared map content
    private var mapContent: some View {
        Map(position: $cameraPosition) {
            ForEach(Array(routeSegments.enumerated()), id: \.offset) { index, route in
                MapPolyline(route)
                    .stroke(FMSTheme.amber, lineWidth: 5)
            }
            
            ForEach(Array(allCoordinates.enumerated()), id: \.offset) { index, coordinate in
                Annotation("", coordinate: coordinate) {
                    Text(markerLabels[min(index, markerLabels.count - 1)])
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            index == 0 ? Color.blue :
                            (index == allCoordinates.count - 1 ? Color.green : FMSTheme.amber)
                        )
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 3)
                }
            }
        }
        .allowsHitTesting(isMapExpanded)
    }
    
    @ViewBuilder
    private func routeStopRow(label: String, color: Color, title: String, address: String?) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(color)
                .clipShape(Circle())
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FMSTheme.textSecondary)
                Text(address ?? "Unknown")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(FMSTheme.textPrimary)
            }
        }
    }
    
    @ViewBuilder
    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon).foregroundColor(FMSTheme.textTertiary).frame(width: 20)
            Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(FMSTheme.textSecondary)
            Spacer()
            Text(value).font(.system(size: 15, weight: .semibold)).foregroundColor(FMSTheme.textPrimary)
        }
        .padding(16)
    }
    
    private func fetchRoutes() async {
        let coords = allCoordinates
        guard coords.count >= 2 else { return }
        
        var segments: [MKRoute] = []
        
        for i in 0..<(coords.count - 1) {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: coords[i]))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coords[i+1]))
            request.transportType = .automobile
            
            do {
                let response = try await MKDirections(request: request).calculate()
                if let route = response.routes.first {
                    segments.append(route)
                }
            } catch {
                print("Failed to calculate route segment: \(error)")
            }
        }
        
        await MainActor.run {
            self.routeSegments = segments
        }
    }
}
