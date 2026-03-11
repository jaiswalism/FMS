//
//  LiveVehicleDashboardView.swift
//  FMS
//
//  Created by Anish on 11/03/26.
//

import Foundation
import SwiftUI

public struct LiveVehicleDashboardView: View {
    @State private var viewModel = LiveVehicleViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Theme colors
    private let background = Color(red: 250/255, green: 250/255, blue: 252/255)
    private let textPrimary = Color(red: 30/255, green: 30/255, blue: 35/255)
    private let textSecondary = Color(red: 110/255, green: 110/255, blue: 120/255)
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Header
                HStack(spacing: 16) {
                    // Back Button
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 48, height: 48)
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(textPrimary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Vehicles")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(textPrimary)
                        
                        Text("\(viewModel.filteredVehicles.isEmpty ? 14 : viewModel.filteredVehicles.count) Currently Active")
                            .font(.system(size: 14))
                            .foregroundColor(textSecondary)
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
