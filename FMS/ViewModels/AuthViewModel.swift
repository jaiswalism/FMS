import SwiftUI
import Observation

public enum Role: String, CaseIterable, Codable {
    case fleetManager = "Fleet Manager"
    case driver = "Driver"
    case maintenance = "Maintenance"
}

@Observable
public class AuthViewModel {
    public var selectedRole: Role?
    public var isAuthenticated: Bool = false
    
    public init(selectedRole: Role? = nil, isAuthenticated: Bool = false) {
        self.selectedRole = selectedRole
        self.isAuthenticated = isAuthenticated
    }
    
    public func selectRole(_ role: Role) {
        selectedRole = role
    }
    
    public func authenticate() {
        isAuthenticated = true
    }
    
    public func logout() {
        selectedRole = nil
        isAuthenticated = false
    }
}
