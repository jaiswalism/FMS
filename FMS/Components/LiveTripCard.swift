import SwiftUI

public struct LiveTripCard: View {
    public let plateNumber: String
    public let origin: String
    public let destination: String
    public let completionPercentage: Int
    
    // Theme colors matching the new aesthetics
    private let cardBackground = Color.white
    private let pillBackground = Color(red: 242/255, green: 242/255, blue: 247/255)
    private let textPrimary = Color(red: 30/255, green: 30/255, blue: 35/255)
    private let textSecondary = Color(red: 110/255, green: 110/255, blue: 120/255)
    private let borderLight = Color(red: 235/255, green: 235/255, blue: 240/255)
    private let symbolColor = Color(red: 80/255, green: 80/255, blue: 90/255) // Dark gray for the truck symbol
    
    public init(plateNumber: String, origin: String, destination: String, completionPercentage: Int) {
        self.plateNumber = plateNumber
        self.origin = origin
        self.destination = destination
        self.completionPercentage = completionPercentage
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // Left Column: Details
            VStack(alignment: .leading, spacing: 12) { // Scaled down from 20
                // Plate Number Pill
                Text(plateNumber)
                    .font(.system(size: 14, weight: .bold)) // Scaled down from 16
                    .foregroundColor(symbolColor)
                    .padding(.horizontal, 12) // Scaled down from 16
                    .padding(.vertical, 6)    // Scaled down from 8
                    .background(
                        RoundedRectangle(cornerRadius: 8) // Scaled down from 12
                            .fill(pillBackground)
                    )
                
                // Route & Progress
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) { // Scaled down from 6
                        Text(origin)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold)) // Scaled down from 16
                        Text(destination)
                    }
                    .font(.system(size: 18, weight: .bold)) // Scaled down from 22
                    .foregroundColor(textPrimary)
                    
                    Text("\(completionPercentage)% complete")
                        .font(.system(size: 14)) // Scaled down from 17
                        .foregroundColor(textSecondary) // Changed to secondary for visual hierarchy
                }
            }
            
            Spacer(minLength: 16) // Scaled down from 20
            
            // Right Column: Truck Graphic (SF Symbol)
            Image(systemName: "truck.box.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80) // Drastically reduced from 140 to fix the massive size
                .foregroundColor(symbolColor)
                .padding(.trailing, 4)
        }
        .padding(.vertical, 16) // Scaled down from 24
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20) // Scaled down from 32
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20) // Scaled down from 32
                .stroke(borderLight, lineWidth: 1)
        )
    }
}

// MARK: - Previews
#Preview {
    ZStack {
        Color(red: 250/255, green: 250/255, blue: 252/255).ignoresSafeArea()
        
        VStack(spacing: 16) {
            LiveTripCard(
                plateNumber: "MH02H0942",
                origin: "MYS",
                destination: "BLR",
                completionPercentage: 48
            )
            
            LiveTripCard(
                plateNumber: "KA 09 MA 1234",
                origin: "DEL",
                destination: "MUM",
                completionPercentage: 12
            )
        }
        .padding(16)
    }
}
