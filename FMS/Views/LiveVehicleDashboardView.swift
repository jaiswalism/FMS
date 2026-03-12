//
//  LiveVehicleDashboardView.swift
//  FMS
//

import Foundation
import SwiftUI

public struct LiveVehicleDashboardView: View {
    @State private var viewModel = LiveVehicleViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            FMSTheme.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Header
                HStack(spacing: 16) {
                    // Back Button
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(FMSTheme.cardBackground)
                                .frame(width: 48, height: 48)
                                .shadow(color: FMSTheme.symbolBackground, radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(FMSTheme.textPrimary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Vehicles")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(FMSTheme.textPrimary)
                        
                        Text("\(viewModel.filteredVehicles.isEmpty ? 14 : viewModel.filteredVehicles.count) Currently Active")
                            .font(.system(size: 14))
                            .foregroundColor(FMSTheme.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.top, 50)
                        } else {
                            // Using a mix of actual and mock data to show the layout precisely.
                            ForEach(0..<6) { _ in
                                NavigationLink {
                                    TrackingShipmentView()
                                } label: {
                                    LiveTripCard(
                                        plateNumber: "MH02H0942",
                                        origin: "MYS",
                                        destination: "BLR",
                                        completionPercentage: 48
                                    )
                                }
                                .buttonStyle(.plain) // Prevents the card from being highlighted blue
                            }
                        }
                    } // <-- LazyVStack cleanly closes here
                    .padding(.horizontal, 20) // Padding is now correctly applied to the LazyVStack
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            // Uncomment when hooked up to real backend
            // await viewModel.fetchVehicles()
        }
    }
}
