import SwiftUI

public struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: @MainActor (Vehicle) async -> Bool
    
    @State private var plateNumber = ""
    @State private var chassisNumber = ""
    @State private var manufacturer = ""
    @State private var model = ""
    @State private var fuelType = "Diesel"
    @State private var tankCapacity = ""
    @State private var carryingCapacity = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    
    private let fuelOptions = ["Diesel", "Petrol", "CNG", "Electric"]
    
    public init(onAdd: @escaping @MainActor (Vehicle) async -> Bool) {
        self.onAdd = onAdd
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                FMSTheme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Section: Basic Info
                            formSection(title: "Identification") {
                                FMSTextField(
                                    label: "Plate Number",
                                    placeholder: "MH02H0942",
                                    icon: "tag.fill",
                                    text: $plateNumber
                                )
                                
                                FMSTextField(
                                    label: "Chassis Number",
                                    placeholder: "VIN Number",
                                    icon: "number",
                                    text: $chassisNumber
                                )
                            }
                            
                            // Section: Vehicle Details
                            formSection(title: "Specifications") {
                                FMSTextField(
                                    label: "Manufacturer",
                                    placeholder: "Tata, Ashok Leyland",
                                    icon: "building.2.fill",
                                    text: $manufacturer
                                )
                                
                                FMSTextField(
                                    label: "Model",
                                    placeholder: "Prima 5530.S",
                                    icon: "truck.box.fill",
                                    text: $model
                                )
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("FUEL TYPE")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(FMSTheme.textSecondary)
                                        .tracking(0.5)
                                    
                                    HStack {
                                        ForEach(fuelOptions, id: \.self) { option in
                                            Button {
                                                fuelType = option
                                            } label: {
                                                Text(option)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 10)
                                                    .background(fuelType == option ? FMSTheme.amber : FMSTheme.pillBackground)
                                                    .foregroundColor(fuelType == option ? FMSTheme.obsidian : FMSTheme.textSecondary)
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Section: Capacities
                            formSection(title: "Capacities") {
                                HStack(spacing: 16) {
                                    FMSTextField(
                                        label: "Fuel Tank (L)",
                                        placeholder: "Liters",
                                        icon: "fuelpump.fill",
                                        text: $tankCapacity
                                    )
                                    .keyboardType(.decimalPad)
                                    
                                    FMSTextField(
                                        label: "Carrying (KG)",
                                        placeholder: "Kilograms",
                                        icon: "shippingbox.fill",
                                        text: $carryingCapacity
                                    )
                                    .keyboardType(.decimalPad)
                                }
                            }
                        }
                        .padding(20)
                    }
                    
                    // Action Button
                    VStack {
                        Button {
                            submitVehicle()
                        } label: {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: FMSTheme.obsidian))
                                } else {
                                    Text("Add Vehicle to Fleet")
                                        .font(.system(size: 17, weight: .bold))
                                }
                            }
                            .foregroundColor(FMSTheme.obsidian)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(FMSTheme.amber)
                            .cornerRadius(16)
                            .shadow(color: FMSTheme.amber.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isSubmitting)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                    .padding(.top, 10)
                    .background(FMSTheme.backgroundPrimary)
                }
            }
            .navigationTitle("New Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                    .foregroundColor(FMSTheme.textSecondary)
                }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Validation Error"),
                    message: Text(errorMessage ?? "Please check your inputs and try again."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func formSection<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(FMSTheme.textTertiary)
                .tracking(1)
            
            content()
        }
        .padding(20)
        .background(FMSTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: FMSTheme.shadowSmall, radius: 8, x: 0, y: 4)
    }
    
    @MainActor
    private func submitVehicle() {
        // Comprehensive validation
        let trimmedPlate = plateNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPlate.isEmpty {
            errorMessage = "Plate Number is required."
            showError = true
            return
        }
        
        let trimmedChassis = chassisNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedChassis.isEmpty {
            errorMessage = "Chassis Number is required."
            showError = true
            return
        }
        
        if manufacturer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Manufacturer is required."
            showError = true
            return
        }
        
        if model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Model is required."
            showError = true
            return
        }
        
        guard let validatedTankCapacity = Double(tankCapacity), validatedTankCapacity > 0 else {
            errorMessage = "Please enter a valid Fuel Tank Capacity greater than 0."
            showError = true
            return
        }
        
        guard let validatedCarryingCapacity = Double(carryingCapacity), validatedCarryingCapacity > 0 else {
            errorMessage = "Please enter a valid Carrying Capacity greater than 0."
            showError = true
            return
        }
        
        // Disable interactions
        isSubmitting = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        let vehicle = Vehicle(
            id: UUID().uuidString,
            plateNumber: trimmedPlate,
            chassisNumber: trimmedChassis,
            manufacturer: manufacturer.trimmingCharacters(in: .whitespacesAndNewlines),
            model: model.trimmingCharacters(in: .whitespacesAndNewlines),
            fuelType: fuelType.lowercased(),
            fuelTankCapacity: validatedTankCapacity,
            carryingCapacity: validatedCarryingCapacity,
            purchaseDateString: todayString,
            odometer: 0.0,
            status: "active",
            createdBy: nil, 
            createdAt: nil
        )
        
        Task {
            let success = await onAdd(vehicle)
            
            await MainActor.run {
                isSubmitting = false
                if success {
                    dismiss()
                } else {
                    errorMessage = "Failed to add vehicle. Please try again."
                    showError = true
                }
            }
        }
    }
}

#Preview {
    AddVehicleView { _ in return true }
}
