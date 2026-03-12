import SwiftUI

public struct FleetManagementView: View {
    @State private var viewModel = FleetViewModel()
    @State private var showingAddVehicle = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                FMSTheme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Search Bar
                    searchBarSection
                    
                    // Filters
                    filterSection
                    
                    // Vehicle List
                    if viewModel.isLoading && viewModel.vehicles.isEmpty {
                        Spacer()
                        ProgressView("Loading vehicles...")
                            .progressViewStyle(CircularProgressViewStyle(tint: FMSTheme.textSecondary))
                            .foregroundColor(FMSTheme.textSecondary)
                        Spacer()
                    } else if viewModel.vehicles.isEmpty {
                        Spacer()
                        Text("No vehicles found.")
                            .font(.system(size: 16))
                            .foregroundColor(FMSTheme.textTertiary)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredVehicles) { vehicle in
                                    VehicleListCard(vehicle: vehicle)
                                }
                            }
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.filteredVehicles)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .task {
                await viewModel.fetchVehicles()
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView { newVehicle in
                    return await viewModel.addVehicle(newVehicle)
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Fleet Management")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(FMSTheme.textPrimary)
                
                Text("\(viewModel.vehicles.count) Total Vehicles")
                    .font(.system(size: 14))
                    .foregroundColor(FMSTheme.textSecondary)
            }
            
            Spacer()
            
            Button {
                showingAddVehicle = true
            } label: {
                ZStack {
                    Circle()
                        .fill(FMSTheme.amber)
                        .frame(width: 44, height: 44)
                        .shadow(color: FMSTheme.amber.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(FMSTheme.obsidian)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private var searchBarSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(FMSTheme.textTertiary)
            
            TextField("Search plate, make, or model", text: $viewModel.searchText)
                .font(.system(size: 15))
                .foregroundColor(FMSTheme.textPrimary)
                .autocorrectionDisabled()
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.searchText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Group {
                if #available(iOS 26, *) {
                    FMSTheme.cardBackground.opacity(0.5)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                } else {
                    FMSTheme.cardBackground.opacity(0.5)
                        .background(.ultraThinMaterial)
                }
            }
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(FMSTheme.textPrimary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: FMSTheme.shadowSmall, radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.statusOptions, id: \.self) { status in
                    FilterPill(
                        title: status,
                        isSelected: viewModel.selectedStatus == status,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedStatus = status
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Subviews
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    // Status color mapping for filters
    private var statusColor: Color {
        let normalized = title.lowercased()
        switch normalized {
        case "active": return FMSTheme.alertGreen
        case "maintenance": return FMSTheme.alertAmber
        case "inactive": return FMSTheme.textTertiary
        case "all": return FMSTheme.amber
        default: return FMSTheme.textTertiary
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if title.lowercased() != "all" || isSelected {
                     Circle()
                         .fill(isSelected && title.lowercased() == "all" ? FMSTheme.obsidian : statusColor)
                         .frame(width: 8, height: 8)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? FMSTheme.obsidian : FMSTheme.textPrimary)
            .background(
                Group {
                    if isSelected {
                        FMSTheme.amber
                    } else {
                        if #available(iOS 26, *) {
                            FMSTheme.cardBackground.opacity(0.5)
                                .glassEffect(.regular.interactive(), in: .capsule)
                        } else {
                            // Liquid glass effect fallback
                            FMSTheme.cardBackground.opacity(0.5)
                                .background(.ultraThinMaterial)
                        }
                    }
                }
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? FMSTheme.amber : FMSTheme.textPrimary.opacity(0.1), lineWidth: 1) // Adaptive glass edge highlight
            )
            .shadow(color: isSelected ? FMSTheme.amber.opacity(0.2) : FMSTheme.shadowSmall, radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    FleetManagementView()
}
