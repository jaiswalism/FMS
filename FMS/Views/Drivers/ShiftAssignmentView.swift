import SwiftUI

// MARK: - ShiftAssignmentView

/// Fleet manager screen to assign a new shift to a driver.
/// Uses native DatePicker and Picker controls.
struct ShiftAssignmentView: View {

    @State private var vm = ShiftAssignmentViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            // MARK: Driver Selection
            Section {
                Picker("Driver", selection: $vm.selectedDriverId) {
                    Text("Select Driver").tag("")
                    ForEach(vm.availableDrivers, id: \.id) { driver in
                        Text(driver.name).tag(driver.id)
                    }
                }
            } header: {
                Text("Driver")
            }

            // MARK: Vehicle Selection
            Section {
                Picker("Vehicle", selection: $vm.selectedVehicleId) {
                    Text("Select Vehicle").tag("")
                    ForEach(vm.availableVehicles, id: \.id) { vehicle in
                        Text(vehicle.display).tag(vehicle.id)
                    }
                }
            } header: {
                Text("Vehicle")
            }

            // MARK: Date & Time
            Section {
                DatePicker(
                    "Shift Date",
                    selection: $vm.shiftDate,
                    displayedComponents: .date
                )
                DatePicker(
                    "Start Time",
                    selection: $vm.shiftStartTime,
                    displayedComponents: .hourAndMinute
                )
                DatePicker(
                    "End Time",
                    selection: $vm.shiftEndTime,
                    displayedComponents: .hourAndMinute
                )
            } header: {
                Text("Schedule")
            }

            // MARK: Assign Button
            Section {
                Button {
                    vm.assignShift()
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("Assign Shift")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(FMSTheme.obsidian)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(
                    vm.isFormValid
                        ? FMSTheme.amber
                        : FMSTheme.amber.opacity(0.4)
                )
                .disabled(!vm.isFormValid)
            }
        }
        .navigationTitle("Assign Shift")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ShiftAssignmentView()
    }
}
