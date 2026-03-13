import SwiftUI

public struct ServiceHistoryListView: View {
    let workOrders: [MaintenanceWorkOrder]
    let isLoading: Bool
    let errorMessage: String?
    
    public init(workOrders: [MaintenanceWorkOrder], isLoading: Bool, errorMessage: String?) {
        self.workOrders = workOrders
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }
    
    public var body: some View {
        ZStack {
            FMSTheme.backgroundPrimary.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if isLoading {
                        loadingRow(text: "Loading service history...")
                    } else if let error = errorMessage {
                        errorRow(text: "Unable to load service history.\n\(error)")
                    } else if workOrders.isEmpty {
                        emptyRow(text: "No service history found.")
                    } else {
                        VStack(spacing: 10) {
                            ForEach(workOrders) { order in
                                serviceCardView(order)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Service History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
    
    private func serviceCardView(_ order: MaintenanceWorkOrder) -> some View {
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
    
    private func workOrderDateText(_ order: MaintenanceWorkOrder) -> String {
        let date = order.completedAt ?? order.createdAt
        return formatDate(date) ?? "Unknown"
    }
    
    private func workOrderCostText(_ order: MaintenanceWorkOrder) -> String {
        guard let cost = order.estimatedCost else { return "--" }
        return "INR \(Int(cost))"
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
    
    private func loadingRow(text: String) -> some View {
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
    
    private func emptyRow(text: String) -> some View {
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
    
    private func errorRow(text: String) -> some View {
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
    
    private func formatDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        return Self.dateFormatter.string(from: date)
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()
}
