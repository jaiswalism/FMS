import Supabase
import SwiftUI
import CoreLocation

public struct FleetManagerDashboardView: View {
  public init() {}

  public var body: some View {
    FMSTabShell {

      // Home Tab
      FMSTabItem(id: "home", title: "Home", icon: "house.fill") {
        FleetManagerHomeTab()
      }

      // Fleet Tab
      FMSTabItem(id: "fleet", title: "Fleet", icon: "truck.box.fill") {
        FleetManagementView()
      }

      // Drivers Tab
      FMSTabItem(id: "drivers", title: "Drivers", icon: "person.2.fill") {
        DriversView()
      }
      // Maintenance Tab
      FMSTabItem(id: "maintenance", title: "Maintenance", icon: "wrench.and.screwdriver.fill") {
        MaintenanceManagerView()
      }

      // Reports Tab
      FMSTabItem(id: "reports", title: "Reports", icon: "chart.bar.xaxis") {
        ReportsHubView()
      }
    }
  }
}

// MARK: - Home Tab Content
struct FleetManagerHomeTab: View {
  @State private var viewModel = FleetManagerHomeViewModel()
  @State private var navigateToLiveFleet = false
  @State private var navigateToProfile = false
  @State private var navigateToOrders = false
  @State private var sosExpanded: Bool = false

  private let alerts: [(title: String, subtitle: String, timeAgo: String, type: AlertType)] = [
    (
      "Tyre pressure warning", "Truck #402 reported low pressure in rear-left tyre.", "12m ago",
      .warning
    ),
    (
      "Driver break scheduled", "Driver David R. is reaching mandatory rest limit in 15 mins.",
      "45m ago", .info
    ),
    (
      "Geofence deviation", "Truck #109 exited the designated route area in North District.",
      "1h ago", .critical
    ),
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Header
          headerSection

          // Fleet Status Card
          FleetStatusCard(
            activeCount: viewModel.activeVehicleCount,
            subtitle: "Vehicles in transit",
            onViewMap: {
              navigateToLiveFleet = true
            }
          )

          // Quick Actions
          QuickActionCard(
            icon: "shippingbox.fill",
            title: "Orders",
            subtitle:
              viewModel.pendingOrderCount > 0
              ? "\(viewModel.pendingOrderCount) pending orders"
              : "Manage fleet orders and dispatch",
            action: {
              navigateToOrders = true
            }
          )

          // Active SOS Alerts — repositioned below Orders
          if !viewModel.activeSOSAlerts.isEmpty {
            sosAlertsSection
          }

          // Recent Alerts Section
          alertsSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
      }
      .background(FMSTheme.backgroundPrimary)
      .navigationDestination(isPresented: $navigateToLiveFleet) {
        LiveVehicleDashboardView()
      }
      .navigationDestination(isPresented: $navigateToProfile) {
        ManagerProfileView()
      }
      .navigationDestination(isPresented: $navigateToOrders) {
        OrdersListView()
      }
      .onAppear {
        viewModel.startSOSPolling()
        Task {
          await viewModel.loadDashboardData()
        }
      }
      .onDisappear {
        viewModel.stopSOSPolling()
      }
    }
  }

  // MARK: - SOS Alerts Section
  private var sosAlertsSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Counter row — always visible
      Button {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
          sosExpanded.toggle()
        }
      } label: {
        HStack(spacing: 10) {
          Image(systemName: "sos")
            .font(.system(size: 14, weight: .black))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(FMSTheme.alertRed)
            .cornerRadius(8)

          Text("\(viewModel.activeSOSAlerts.count) Active SOS Alert\(viewModel.activeSOSAlerts.count == 1 ? "" : "s")")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(FMSTheme.alertRed)

          Spacer()

          if viewModel.activeSOSAlerts.count > 1 {
            Image(systemName: sosExpanded ? "chevron.up" : "chevron.down")
              .font(.system(size: 12, weight: .bold))
              .foregroundStyle(FMSTheme.alertRed)
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(FMSTheme.alertRed.opacity(0.08))
        .cornerRadius(12)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(FMSTheme.alertRed.opacity(0.3), lineWidth: 1)
        )
      }
      .buttonStyle(.plain)

      // Alert cards
      VStack(spacing: 10) {
        if sosExpanded {
          ForEach(Array(viewModel.activeSOSAlerts.enumerated()), id: \.element.id) { index, alert in
            SOSAlertCard(
              viewModel: viewModel,
              alert: alert,
              isLatest: index == 0
            )
          }
        } else if let latest = viewModel.activeSOSAlerts.first {
          SOSAlertCard(
            viewModel: viewModel,
            alert: latest,
            isLatest: true
          )
        }
      }
      .padding(.top, 10)
    }
  }

  // MARK: - Header Section
  private var headerSection: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Welcome, \(viewModel.managerName)")
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(FMSTheme.textPrimary)

        Text(formattedDate)
          .font(.system(size: 14))
          .foregroundStyle(FMSTheme.textSecondary)
      }

      Spacer()

      Button {
        navigateToProfile = true
      } label: {
        ZStack {
          Circle()
            .fill(FMSTheme.borderLight)
            .frame(width: 48, height: 48)
          Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 44))
            .foregroundStyle(FMSTheme.amber)
        }
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Alerts Section
  private var alertsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Recent Alerts")
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(FMSTheme.textPrimary)

      ForEach(alerts.indices, id: \.self) { index in
        let alert = alerts[index]
        AlertRow(
          title: alert.title,
          subtitle: alert.subtitle,
          timeAgo: alert.timeAgo,
          type: alert.type
        )
      }
    }
  }

  private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d"
    return formatter.string(from: Date())
  }
}

// MARK: - SOS Alert Card

private struct SOSAlertCard: View {
  let viewModel: FleetManagerHomeViewModel
  let alert: SOSAlert
  var isLatest: Bool = false
  @Environment(\.openURL) private var openURL
  @State private var locationAddress: String = "Fetching location..."
  @State private var isResolving = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(statusColor)

        Text(statusLabel)
          .font(.system(size: 14, weight: .black))
          .foregroundStyle(statusColor)

        if isLatest && alert.status == .active {
          Text("LATEST")
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(FMSTheme.obsidian)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(FMSTheme.amber)
            .cornerRadius(4)
        }

        Spacer()

        Text(timeAgoText)
          .font(.system(size: isLatest ? 13 : 12, weight: isLatest ? .bold : .medium))
          .foregroundStyle(isLatest ? FMSTheme.amber : FMSTheme.textTertiary)
      }

      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Driver: \(viewModel.driverNames[alert.driverId] ?? alert.driverId)")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(FMSTheme.textPrimary)
          
          HStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
              .font(.system(size: 10))
            Text(locationAddress)
              .font(.system(size: 11))
          }
          .foregroundStyle(FMSTheme.textSecondary)
          .padding(.top, 2)
        }

        Spacer()

        if let speed = alert.speed, speed > 0 {
          VStack(alignment: .trailing, spacing: 2) {
            Text("\(Int(speed))")
              .font(.system(size: 18, weight: .black))
              .foregroundStyle(FMSTheme.amber)
            Text("km/h")
              .font(.system(size: 10, weight: .bold))
              .foregroundStyle(FMSTheme.textTertiary)
          }
        }
      }

      // Actions
      HStack(spacing: 12) {
        // Call driver
        Button {
          if let phone = viewModel.driverPhones[alert.driverId], !phone.isEmpty {
            let cleanedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            if let url = URL(string: "tel:\(cleanedPhone)") {
              openURL(url)
            }
          }
        } label: {
          HStack(spacing: 6) {
            Image(systemName: "phone.fill")
              .font(.system(size: 13, weight: .semibold))
            Text("Call Driver")
              .font(.system(size: 13, weight: .bold))
          }
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 10)
          .background(FMSTheme.alertGreen)
          .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(
          viewModel.driverPhones[alert.driverId] == nil
            || viewModel.driverPhones[alert.driverId]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              ?? true
        )
        .opacity(
          (viewModel.driverPhones[alert.driverId] == nil
            || viewModel.driverPhones[alert.driverId]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              ?? true)
            ? 0.5 : 1.0)

        // Resolve Button
        Button {
          isResolving = true
          Task {
            await viewModel.resolveSOSAlert(id: alert.id)
            isResolving = false
          }
        } label: {
          if isResolving {
            ProgressView()
              .tint(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 10)
          } else {
            Text("Resolve SOS")
              .font(.system(size: 13, weight: .bold))
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 10)
          }
        }
        .background(FMSTheme.textTertiary)
        .cornerRadius(10)
        .buttonStyle(.plain)
      }
    }
    .padding(14)
    .background(statusColor.opacity(0.06))
    .cornerRadius(14)
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(statusColor.opacity(0.4), lineWidth: 1.5)
    )
    .task {
      await reverseGeocode()
    }
  }

  private func reverseGeocode() async {
    let geocoder = CLGeocoder()
    let location = CLLocation(latitude: alert.latitude, longitude: alert.longitude)
    
    do {
      let placemarks = try await geocoder.reverseGeocodeLocation(location)
      if let placemark = placemarks.first {
        let street = placemark.thoroughfare ?? ""
        let subLocality = placemark.subLocality ?? ""
        let locality = placemark.locality ?? ""
        
        var address = ""
        if !street.isEmpty { address += street }
        if !subLocality.isEmpty { 
          address += (address.isEmpty ? "" : ", ") + subLocality 
        }
        if !locality.isEmpty {
          address += (address.isEmpty ? "" : ", ") + locality
        }
        
        if address.isEmpty {
          self.locationAddress = "Unknown location"
        } else {
          self.locationAddress = address
        }
      }
    } catch {
      self.locationAddress = "Location unavailable"
    }
  }

  private var statusColor: Color {
    switch alert.status {
    case .active: return FMSTheme.alertRed
    case .acknowledged: return FMSTheme.alertOrange
    case .resolved: return FMSTheme.alertGreen
    case .cancelled: return FMSTheme.textTertiary
    }
  }

  private var statusLabel: String {
    switch alert.status {
    case .active: return "EMERGENCY SOS"
    case .acknowledged: return "SOS — ACKNOWLEDGED"
    case .resolved: return "SOS — RESOLVED"
    case .cancelled: return "SOS — CANCELLED"
    }
  }

  private var timeAgoText: String {
    let seconds = Int(Date().timeIntervalSince(alert.timestamp))
    if seconds < 60 { return "Just now" }
    if seconds < 3600 { return "\(seconds / 60)m ago" }
    return "\(seconds / 3600)h ago"
  }
}
