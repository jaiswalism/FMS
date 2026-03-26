import Foundation
import Observation
import Supabase

@Observable
@MainActor
public final class FleetManagerHomeViewModel {
  private struct IDRow: Decodable {
    let id: String
  }

  public var managerName: String = "Manager"
  public var activeVehicleCount: Int = 0
  public var pendingOrderCount: Int = 0
  public var errorMessage: String?

  // SOS specific state
  public var activeSOSAlerts: [SOSAlert] = []
  public var driverNames: [String: String] = [:] // ID to Name
  public var driverPhones: [String: String] = [:] // ID to Phone
  public var isFetchingSOS = false
  private var sosPollingTimer: Timer?

  public init() {}

  public func loadDashboardData() async {
    errorMessage = nil

    do {
      async let activeVehiclesTask: [IDRow] = SupabaseService.shared.client
        .from("trips")
        .select("id")
        .eq("status", value: "active")
        .execute()
        .value

      async let pendingOrdersTask: [IDRow] = SupabaseService.shared.client
        .from("orders")
        .select("id")
        .in("status", values: ["pending", "confirmed", "dispatched"])
        .execute()
        .value

      let (activeVehicles, pendingOrders) = try await (activeVehiclesTask, pendingOrdersTask)
      self.activeVehicleCount = activeVehicles.count
      self.pendingOrderCount = pendingOrders.count

      if let userId = try? await SupabaseService.shared.client.auth.session.user.id.uuidString {
        struct UserNameRow: Decodable {
          let name: String
        }

        if let profile: UserNameRow = try? await SupabaseService.shared.client
          .from("users")
          .select("name")
          .eq("id", value: userId)
          .limit(1)
          .single()
          .execute()
          .value
        {
          self.managerName = profile.name
        }
      }
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  // MARK: - SOS Management

  public func startSOSPolling() {
    Task { await fetchSOSAlerts() }
    sosPollingTimer?.invalidate()
    sosPollingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
      Task { @MainActor in
        await self.fetchSOSAlerts()
      }
    }
  }

  public func stopSOSPolling() {
    sosPollingTimer?.invalidate()
    sosPollingTimer = nil
  }

  public func fetchSOSAlerts() async {
    guard !isFetchingSOS else { return }
    isFetchingSOS = true
    defer { isFetchingSOS = false }

    do {
      let response = try await SupabaseService.shared.client
        .from("sos_alerts")
        .select()
        .eq("status", value: SOSAlertStatus.active.rawValue)
        .order("timestamp", ascending: false)
        .limit(10)
        .execute()

      let alerts = try JSONDecoder.supabase().decode([SOSAlert].self, from: response.data)
      self.activeSOSAlerts = alerts
      
      // Resolve metadata for new alerts
      for alert in alerts {
        await resolveMetadata(for: alert)
      }
    } catch {
      print("[FMS] fetchSOSAlerts failed: \(error)")
    }
  }

  public func resolveSOSAlert(id: String) async {
    do {
      try await SupabaseService.shared.client
        .from("sos_alerts")
        .update(["status": SOSAlertStatus.resolved.rawValue])
        .eq("id", value: id)
        .execute()
      
      // Refresh list
      await fetchSOSAlerts()
    } catch {
      print("[FMS] resolveSOSAlert failed: \(error)")
    }
  }

  private func resolveMetadata(for alert: SOSAlert) async {
    // Resolve Driver Name & Phone
    if driverNames[alert.driverId] == nil || driverPhones[alert.driverId] == nil {
      struct UserRow: Decodable { 
        let name: String
        let phone: String?
      }
      if let row: UserRow = try? await SupabaseService.shared.client
        .from("users")
        .select("name, phone")
        .eq("id", value: alert.driverId)
        .single()
        .execute()
        .value {
        driverNames[alert.driverId] = row.name
        if let phone = row.phone {
          driverPhones[alert.driverId] = phone
        }
      }
  }
}
}