import SwiftUI

public struct FMSRoleCard: View {
    public let title: String
    public let systemImage: String
    public let description: String
    public let isSelected: Bool
    public let action: () -> Void
    
    private let labelColor = Color(red: 110/255, green: 110/255, blue: 120/255)
    
    public init(title: String, systemImage: String, description: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isSelected ? FMSTheme.amber : Color(red: 60/255, green: 60/255, blue: 70/255))
                    .frame(width: 36)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(red: 30/255, green: 30/255, blue: 35/255))
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(labelColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Checkmark indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(FMSTheme.amber)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? FMSTheme.amber.opacity(0.08) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? FMSTheme.amber : Color(red: 235/255, green: 235/255, blue: 240/255), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
