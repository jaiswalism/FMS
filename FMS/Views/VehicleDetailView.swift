import SwiftUI

public struct VehicleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(BannerManager.self) private var bannerManager
    @State private var currentVehicle: Vehicle
    @State private var viewModel = VehicleDetailViewModel()
    private let onUpdate: (@MainActor (Vehicle) async throws -> Void)?
    private let onDelete: (@MainActor (String) async throws -> Void)?
    @State private var showingEditVehicle = false
    @State private var showingDeleteConfirm = false
    @State private var isDeleting = false
    
    public init(
        vehicle: Vehicle,
        onUpdate: (@MainActor (Vehicle) async throws -> Void)? = nil,
        onDelete: (@MainActor (String) async throws -> Void)? = nil
    ) {
        _currentVehicle = State(initialValue: vehicle)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }
    
    public var body: some View {
        ZStack {
            FMSTheme.backgroundPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    headerBlock
                    shiftStatusCard
                    currentTripSection
                    pastTripsSection
                    serviceSection
                    incidentsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(currentVehicle.plateNumber)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if onUpdate != nil || onDelete != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if onUpdate != nil {
                            Button("Edit Vehicle") {
                                showingEditVehicle = true
                            }
                        }
                        if onDelete != nil {
                            Button(role: .destructive) {
                                showingDeleteConfirm = true
                            } label: {
                                Text("Delete Vehicle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(FMSTheme.textSecondary)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActions
        }
        .task {
            await viewModel.fetch(vehicleId: currentVehicle.id)
        }
        .sheet(isPresented: $showingEditVehicle) {
            AddVehicleView(vehicle: currentVehicle) { updatedVehicle in
                guard let onUpdate else { return }
                try await onUpdate(updatedVehicle)
                await MainActor.run {
                    currentVehicle = updatedVehicle
                }
            }
        }
        .alert("Delete Vehicle?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await deleteVehicle() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove \(currentVehicle.plateNumber) and its related records.")
        }
    }
    
    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(vehicleName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(FMSTheme.textPrimary)
                    
                    Text(currentVehicle.plateNumber)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(FMSTheme.textSecondary)
                    
                    Text("VIN: \(currentVehicle.chassisNumber)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(FMSTheme.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(FMSTheme.statusColor(for: currentVehicle.status ?? ""))
                        .frame(width: 8, height: 8)
                    Text((currentVehicle.status ?? "Unknown").uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FMSTheme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(FMSTheme.backgroundPrimary)
                .cornerRadius(8)
            }
            
            Divider()
                .overlay(FMSTheme.borderLight)
            
            detailRow(title: "Make", value: currentVehicle.manufacturer ?? "Unknown")
            detailRow(title: "Model", value: currentVehicle.model ?? "Unknown")
            detailRow(title: "Fuel Type", value: currentVehicle.fuelType.capitalized)
            detailRow(title: "Fuel Tank", value: "\(Int(currentVehicle.fuelTankCapacity)) L")
            detailRow(title: "Carrying Capacity", value: capacityText)
            detailRow(title: "Odometer", value: odometerText)
        }
        .padding(16)
        .background(FMSTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: FMSTheme.shadowSmall, radius: 6, x: 0, y: 4)
    }
    
    private var shiftStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Shift Status")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FMSTheme.textPrimary)
                
                if let assignment = activeOrLatestAssignment {
                    Spacer()
                    Text(assignmentStatusText(assignment).capitalized)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FMSTheme.textSecondary)
                }
            }
            
            if viewModel.isLoadingAssignments {
                loadingCard(text: "Loading shift status...")
            } else if let error = viewModel.assignmentsErrorMessage {
                errorCard(text: "Unable to load shift status.\n\(error)")
            } else if let assignment = activeOrLatestAssignment {
                shiftTimeRow(assignment)
            } else {
                Text("No shift assignments found.")
                    .font(.system(size: 14))
                    .foregroundColor(FMSTheme.textTertiary)
            }
        }
        .padding(16)
        .background(FMSTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: FMSTheme.shadowSmall, radius: 6, x: 0, y: 4)
    }
    
    private var currentTripSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Current Trip", count: currentTrip == nil ? 0 : 1, isLoading: viewModel.isLoadingTrips)
            
            if viewModel.isLoadingTrips {
                loadingCard(text: "Loading current trip...")
            } else if let error = viewModel.tripsErrorMessage {
                errorCard(text: "Unable to load current trip.\n\(error)")
            } else if let trip = currentTrip {
                tripCard(trip)
            } else {
                emptyCard(text: "No active trip.")
            }
        }
    }
    
    private var pastTripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Past Trips", count: pastTrips.count, isLoading: viewModel.isLoadingTrips)
            
            if viewModel.isLoadingTrips {
                loadingCard(text: "Loading trips...")
            } else if let error = viewModel.tripsErrorMessage {
                errorCard(text: "Unable to load past trips.\n\(error)")
            } else if pastTrips.isEmpty {
                emptyCard(text: "No past trips found.")
            } else {
                VStack(spacing: 10) {
                    ForEach(pastTrips) { trip in
                        tripCard(trip)
                    }
                }
            }
        }
    }
    
    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Service History", count: viewModel.workOrders.count, isLoading: viewModel.isLoadingWorkOrders)
            
            if viewModel.isLoadingWorkOrders {
                loadingCard(text: "Loading service history...")
            } else if let error = viewModel.workOrdersErrorMessage {
                errorCard(text: "Unable to load service history.\n\(error)")
            } else if viewModel.workOrders.isEmpty {
                emptyCard(text: "No service history found.")
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.workOrders) { order in
                        serviceCard(order)
                    }
                }
            }
        }
    }
    
    private var incidentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Incidents", count: viewModel.incidents.count, isLoading: viewModel.isLoadingEvents)
            
            if viewModel.isLoadingEvents {
                loadingCard(text: "Loading incidents...")
            } else if let error = viewModel.incidentsErrorMessage {
                errorCard(text: "Unable to load incidents.\n\(error)")
            } else if viewModel.incidents.isEmpty {
                emptyCard(text: "No incidents reported.")
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.incidents) { incident in
                        incidentCard(incident)
                    }
                }
            }
        }
    }
    
    private func tripCard(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(tripTitleText(trip))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(FMSTheme.textPrimary)
                    .lineLimit(1)
            }

            tripRouteRow(trip)
            
            HStack(spacing: 14) {
                infoPill(icon: "calendar", text: tripDateText(trip))
                infoPill(icon: "map.fill", text: tripDistanceText(trip))
                infoPill(icon: "clock.fill", text: tripDurationText(trip))
            }
        }
        .padding(14)
        .background(FMSTheme.cardBackground)
        .cornerRadius(14)
        .shadow(color: FMSTheme.shadowSmall, radius: 4, x: 0, y: 3)
    }
    
    private func serviceCard(_ order: MaintenanceWorkOrder) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(order.description?.isEmpty == false ? order.description! : "Service Task")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(FMSTheme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Text((order.status ?? "Pending").uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FMSTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FMSTheme.backgroundPrimary)
                    .cornerRadius(6)
            }
            
            HStack(spacing: 14) {
                infoPill(icon: "calendar", text: workOrderDateText(order))
                infoPill(icon: "wrench.and.screwdriver.fill", text: order.priority?.capitalized ?? "Standard")
                infoPill(icon: "creditcard.fill", text: workOrderCostText(order))
            }
        }
        .padding(14)
        .background(FMSTheme.cardBackground)
        .cornerRadius(14)
        .shadow(color: FMSTheme.shadowSmall, radius: 4, x: 0, y: 3)
    }
    
    private func incidentCard(_ incident: Incident) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(incidentTitle(incident))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(FMSTheme.textPrimary)
                Spacer()
                Text(humanize(incident.severity ?? "Unknown").uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(FMSTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FMSTheme.backgroundPrimary)
                    .cornerRadius(6)
            }
            
            Text(incidentTimeText(incident))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(FMSTheme.textTertiary)
        }
        .padding(14)
        .background(FMSTheme.cardBackground)
        .cornerRadius(14)
        .shadow(color: FMSTheme.shadowSmall, radius: 4, x: 0, y: 3)
    }
    
    private func sectionHeader(title: String, count: Int, isLoading: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(FMSTheme.textPrimary)
            Spacer()
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: FMSTheme.textSecondary))
            } else {
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(FMSTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(FMSTheme.backgroundPrimary)
                    .cornerRadius(6)
            }
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(FMSTheme.textTertiary)
                .tracking(0.5)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(FMSTheme.textSecondary)
        }
    }
    
    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(FMSTheme.textTertiary)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(FMSTheme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(FMSTheme.backgroundPrimary)
        .cornerRadius(6)
    }
    
    private var bottomActions: some View {
        HStack(spacing: 12) {
            Button {
                // Track Live action
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .bold))
                        .rotationEffect(.degrees(45))
                        .offset(x: -2, y: 2)
                    Text("Track Live")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(FMSTheme.obsidian)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FMSTheme.amber)
                .cornerRadius(12)
            }
            
            Button {
                // Schedule Service action
            } label: {
                Text("Schedule Service")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(FMSTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(FMSTheme.borderLight, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(FMSTheme.backgroundPrimary)
    }
    
    private func loadingCard(text: String) -> some View {
        HStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FMSTheme.textSecondary))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(FMSTheme.textSecondary)
            Spacer()
        }
        .padding(14)
        .background(FMSTheme.cardBackground)
        .cornerRadius(14)
    }
    
    private func emptyCard(text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(FMSTheme.textTertiary)
            Spacer()
        }
        .padding(14)
        .background(FMSTheme.cardBackground)
        .cornerRadius(14)
    }
    
    private func errorCard(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(FMSTheme.alertOrange)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(FMSTheme.textSecondary)
            Spacer()
        }
        .padding(14)
        .background(FMSTheme.cardBackground)
        .cornerRadius(14)
    }
    
    private var vehicleName: String {
        let make = currentVehicle.manufacturer ?? ""
        let model = currentVehicle.model ?? ""
        let fullName = "\(make) \(model)".trimmingCharacters(in: .whitespaces)
        return fullName.isEmpty ? "Unknown Vehicle" : fullName
    }
    
    private var capacityText: String {
        guard let capacity = currentVehicle.carryingCapacity else { return "Unknown" }
        return "\(Int(capacity)) kg"
    }
    
    private var odometerText: String {
        guard let odometer = currentVehicle.odometer else { return "Unknown" }
        return "\(Int(odometer)) km"
    }
    
    private func tripTitleText(_ trip: Trip) -> String {
        let shipment = trip.shipmentDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !shipment.isEmpty { return shipment }
        return tripRoute(trip)
    }
    
    private func tripRoute(_ trip: Trip) -> String {
        let start = trip.startName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let end = trip.endName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !start.isEmpty || !end.isEmpty {
            let startText = start.isEmpty ? "Start" : start
            let endText = end.isEmpty ? "End" : end
            return "\(startText) to \(endText)"
        }
        return "Trip"
    }

    private func tripRouteRow(_ trip: Trip) -> some View {
        let start = trip.startName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let end = trip.endName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let startText = start.isEmpty ? "Start" : start
        let endText = end.isEmpty ? "End" : end

        return HStack(spacing: 8) {
            Text(startText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(FMSTheme.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)

            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(FMSTheme.textTertiary)

            Spacer(minLength: 8)

            Text(endText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(FMSTheme.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
    
    private func tripDateText(_ trip: Trip) -> String {
        let date = trip.startTime ?? trip.createdAt
        return formatDate(date) ?? "Unknown"
    }
    
    private func tripDistanceText(_ trip: Trip) -> String {
        guard let distance = trip.distanceKm else { return "-- km" }
        return String(format: "%.0f km", distance)
    }
    
    private func tripDurationText(_ trip: Trip) -> String {
        if let actual = trip.actualDurationMin {
            return "\(actual) min"
        }
        if let estimated = trip.estimatedDurationMin {
            return "\(estimated) min"
        }
        return "-- min"
    }
    
    private func tripTimeWindowText(_ trip: Trip) -> String {
        let start = formatTime(trip.startTime)
        let end = formatTime(trip.endTime)
        if let start, let end {
            return "\(start) - \(end)"
        }
        if let start {
            return "\(start) - In Progress"
        }
        return "Schedule unavailable"
    }
    
    private func tripStatusText(_ trip: Trip) -> String {
        (trip.status ?? "Unknown").uppercased()
    }

    private func assignmentStatusText(_ assignment: DriverVehicleAssignment) -> String {
        if let status = assignment.status?.trimmingCharacters(in: .whitespacesAndNewlines), !status.isEmpty {
            return status.uppercased()
        }
        if let start = assignment.shiftStart, let end = assignment.shiftEnd {
            let now = Date()
            return now >= start && now <= end ? "ACTIVE" : "SCHEDULED"
        }
        return "UNKNOWN"
    }

    private func shiftTimeRow(_ assignment: DriverVehicleAssignment) -> some View {
        let startText = formatTime(assignment.shiftStart) ?? "Start"
        let endText = formatTime(assignment.shiftEnd) ?? "End"
        let durationText = shiftDurationText(assignment)
        
        return HStack(spacing: 8) {
            Text(startText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(FMSTheme.textSecondary)
                .lineLimit(1)
            
            Spacer(minLength: 8)
            
            HStack(spacing: 6) {
                Text(durationText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(FMSTheme.textTertiary)
                Image(systemName: "arrow.right.long")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(FMSTheme.textTertiary)
            }
            
            Spacer(minLength: 8)
            
            Text(endText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(FMSTheme.textSecondary)
                .lineLimit(1)
        }
    }
    
    private func shiftDurationText(_ assignment: DriverVehicleAssignment) -> String {
        if let start = assignment.shiftStart, let end = assignment.shiftEnd {
            let duration = end.timeIntervalSince(start) / 60.0
            return "\(max(0, Int(duration))) min"
        }
        if let start = assignment.shiftStart {
            let elapsed = Date().timeIntervalSince(start) / 60.0
            return "\(max(0, Int(elapsed))) min"
        }
        return "-- min"
    }
    
    private func workOrderDateText(_ order: MaintenanceWorkOrder) -> String {
        let date = order.completedAt ?? order.createdAt
        return formatDate(date) ?? "Unknown"
    }
    
    private func workOrderCostText(_ order: MaintenanceWorkOrder) -> String {
        guard let cost = order.estimatedCost else { return "--" }
        return "INR \(Int(cost))"
    }
    
    private func incidentTitle(_ incident: Incident) -> String {
        let severity = incident.severity?.trimmingCharacters(in: .whitespacesAndNewlines)
        return humanize(severity?.isEmpty == false ? severity! : "Incident")
    }
    
    private func incidentTimeText(_ incident: Incident) -> String {
        formatDate(incident.createdAt) ?? "Unknown"
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    private func formatDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        return Self.dateFormatter.string(from: date)
    }
    
    private func formatTime(_ date: Date?) -> String? {
        guard let date else { return nil }
        return Self.timeFormatter.string(from: date)
    }
    
    private var currentTrip: Trip? {
        viewModel.trips.first { trip in
            if trip.endTime == nil { return true }
            let status = trip.status?.lowercased() ?? ""
            return status == "in_progress" || status == "ongoing" || status == "active"
        }
    }
    
    private var pastTrips: [Trip] {
        if let currentTrip {
            return viewModel.trips.filter { $0.id != currentTrip.id }
        }
        return viewModel.trips
    }
    
    private var activeOrLatestAssignment: DriverVehicleAssignment? {
        if let active = viewModel.assignments.first(where: { assignment in
            let status = assignment.status?.lowercased() ?? ""
            if status == "active" || status == "ongoing" || status == "in_progress" {
                return true
            }
            if let start = assignment.shiftStart, let end = assignment.shiftEnd {
                let now = Date()
                return now >= start && now <= end
            }
            if let start = assignment.shiftStart, assignment.shiftEnd == nil {
                return Date() >= start
            }
            return false
        }) {
            return active
        }
        return viewModel.assignments.first
    }
    
    private func shiftProgress(_ assignment: DriverVehicleAssignment) -> Double {
        guard let start = assignment.shiftStart, let end = assignment.shiftEnd else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        let progress = elapsed / total
        return max(0, min(progress, 1))
    }

    private func humanize(_ value: String) -> String {
        let cleaned = value
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        let parts = cleaned.split(separator: " ")
        if parts.isEmpty { return value }
        return parts.map { $0.capitalized }.joined(separator: " ")
    }

    @MainActor
    private func deleteVehicle() async {
        guard !isDeleting else { return }
        guard let onDelete else { return }
        isDeleting = true
        do {
            try await onDelete(currentVehicle.id)
            dismiss()
        } catch {
            bannerManager.show(type: .error, message: "Failed to delete vehicle. Please try again.")
        }
        isDeleting = false
    }
}

#Preview {
    let vehicle = Vehicle(
        id: "1",
        plateNumber: "MH02H0942",
        chassisNumber: "JH4TB2H26CC000000",
        manufacturer: "TATA",
        model: "PRIMA 5530.S",
        fuelType: "diesel",
        fuelTankCapacity: 400,
        carryingCapacity: 12000,
        purchaseDateString: "2025-09-10",
        odometer: 125000,
        status: "active",
        createdBy: nil,
        createdAt: nil
    )
    
    NavigationStack {
        VehicleDetailView(vehicle: vehicle)
    }
}
