import SwiftUI

public struct RoleSelectionView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    @State private var pendingSelection: Role? = nil
    
    private let labelColor = Color(red: 110/255, green: 110/255, blue: 120/255)
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    // Logo
                    HStack(spacing: 10) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(FMSTheme.amber)
                        
                        Text("FleetPro")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 30/255, green: 30/255, blue: 35/255))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                    
                    // Hero Text
                    Text("Welcome")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Color(red: 30/255, green: 30/255, blue: 35/255))
                        .padding(.bottom, 8)
                    
                    Text("Choose your role to continue")
                        .font(.system(size: 16))
                        .foregroundColor(labelColor)
                        .padding(.bottom, 36)
                    
                    // Role Cards
                    VStack(spacing: 14) {
                        FMSRoleCard(
                            title: "Fleet Manager",
                            systemImage: "person.crop.rectangle.stack.fill",
                            description: "Manage vehicles, drivers, and analytics",
                            isSelected: pendingSelection == .fleetManager,
                            action: { withAnimation { pendingSelection = .fleetManager } }
                        )
                        
                        FMSRoleCard(
                            title: "Driver",
                            systemImage: "car.fill",
                            description: "Log trips, fuel, and vehicle inspections",
                            isSelected: pendingSelection == .driver,
                            action: { withAnimation { pendingSelection = .driver } }
                        )
                        
                        FMSRoleCard(
                            title: "Maintenance",
                            systemImage: "wrench.and.screwdriver.fill",
                            description: "Service requests and parts inventory",
                            isSelected: pendingSelection == .maintenance,
                            action: { withAnimation { pendingSelection = .maintenance } }
                        )
                    }
                    
                    Spacer()
                    
                    // Continue Button
                    Button {
                        if let selection = pendingSelection {
                            withAnimation {
                                authViewModel.selectRole(selection)
                            }
                        }
                    } label: {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(red: 30/255, green: 30/255, blue: 35/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(FMSTheme.amber)
                            )
                    }
                    .disabled(pendingSelection == nil)
                    .opacity(pendingSelection == nil ? 0.4 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: pendingSelection)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}
