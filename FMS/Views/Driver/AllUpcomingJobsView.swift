import SwiftUI

struct AllUpcomingJobsView: View {
    @Bindable var viewModel: DriverDashboardViewModel
    @State private var selectedTrip: Trip?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.upcomingTrips.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.upcomingTrips) { trip in
                        UpcomingJobCard(trip: trip) {
                            selectedTrip = trip
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(FMSTheme.backgroundPrimary)
        .navigationTitle("Upcoming Jobs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $selectedTrip) { trip in
            NewTripAssignmentView(trip: trip, viewModel: viewModel)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundStyle(FMSTheme.amber.opacity(0.6))

            Text("No Upcoming Jobs")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(FMSTheme.textPrimary)

            Text("New trip assignments will appear here")
                .font(.system(size: 14))
                .foregroundStyle(FMSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
