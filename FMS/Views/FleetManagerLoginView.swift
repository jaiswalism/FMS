import SwiftUI

public struct FleetManagerLoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    
    private let lightBackground = Color(red: 245/255, green: 245/255, blue: 247/255)
    private let labelColor = Color(red: 130/255, green: 130/255, blue: 140/255)
    
    public init() {}
    
    public var body: some View {
        ZStack {
            lightBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Logo
                HStack(spacing: 8) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(FMSTheme.amber)
                    
                    Text("FleetPro")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
                
                // Hero Text
                Text("Master your logistics.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.bottom, 12)
                
                Text("Real-time tracking, maintenance scheduling,\nand driver performance.")
                    .font(.system(size: 15))
                    .foregroundColor(labelColor)
                    .lineSpacing(4)
                    .padding(.bottom, 40)
                
                // Welcome Section
                Text("Welcome back")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.bottom, 6)
                
                Text("Enter credentials to manage your fleet")
                    .font(.system(size: 14))
                    .foregroundColor(labelColor)
                    .padding(.bottom, 28)
                
                // Email Field
                FMSTextField(
                    label: "Email Address",
                    placeholder: "manager@fleetpro.com",
                    icon: "envelope",
                    text: $email
                )
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .padding(.bottom, 20)
                
                // Password Field
                FMSTextField(
                    label: "Password",
                    placeholder: "Required",
                    icon: "lock",
                    text: $password,
                    isSecure: true,
                    trailingAction: {
                        // Forgot password action
                    },
                    trailingLabel: "Forgot?"
                )
                .textContentType(.password)
                .padding(.bottom, 28)
                
                // Login Button
                Button {
                    performLogin()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.9)
                        } else {
                            Text("Login")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(FMSTheme.amber)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                
                Spacer()
                
                // Footer
                HStack {
                    Spacer()
                    Text("© 2024 FleetPro Systems")
                        .font(.system(size: 12))
                        .foregroundColor(labelColor)
                    Spacer()
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 28)
        }
    }
    
    private func performLogin() {
        isLoading = true
        
        // Simulate login delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            withAnimation {
                authViewModel.authenticate()
            }
        }
    }
}

#Preview {
    FleetManagerLoginView()
        .environment(AuthViewModel(selectedRole: .fleetManager))
}
